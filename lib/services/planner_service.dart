import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import 'dart:developer' as developer;

// choose: the start or finish is a name in several places - which?
enum PlannerStatus { idle, working, choose, done, refused, failed }

/// AI assist - the trip planner. Sends the user's request to the API and
/// follows the plan's progress, then makes the suggested trip the trip
/// being planned: the user changes it like any other (Edit mode, anchors
/// and undo) and saves it. Until it's saved it's drawn in the AI colour, and
/// everything else the planner found - the candidates - shows as dots; the
/// Status Bar names one under the crosshair (candidateAt()), so the user can
/// add it with the Waypoint chip.
///
/// The PlannerPanel (in the drawer) shows the request, the progress, what
/// was understood as chips the user can change, and the result.
class PlannerService extends ChangeNotifier {
  static final PlannerService _instance = PlannerService._internal();
  factory PlannerService() => _instance;
  PlannerService._internal();

  PlannerStatus status = PlannerStatus.idle;
  String request = '';
  String progress = '';
  String message = ''; // why there's no trip - refused or failed
  Map<String, dynamic>? result;

  /// What was understood, as the user has changed it with the chips
  Map<String, dynamic>? fields;
  bool edited = false;

  Timer? _poll;
  String _jobId = '';
  int _polls = 0;
  bool _checking = false;

  static const Duration _pollEvery = Duration(seconds: 2);
  static const int _mostPolls = 120; // 4 minutes - a plan takes about one

  Map<String, dynamic> get trip =>
      Map<String, dynamic>.from(result?['trip'] ?? {});
  List get candidates => result?['candidates']?['places'] ?? [];

  /// Plans a trip from what the user typed
  Future<void> plan(String text) async {
    request = text.trim();
    fields = null;
    await _start();
  }

  /// Plans again with the chips as the user changed them - the request
  /// isn't read again
  Future<void> planAgain() => _start(changed: fields);

  void changeField(String name, dynamic value) {
    fields ??= {};
    fields![name] = value;
    edited = true;
    notifyListeners();
  }

  // ---- route preferences -----------------------------------------------------
  // The user's settings (Settings, and the Fab menu on the map) - sent with
  // a new request, and shown as chips once it's planned. A chip changes the
  // setting too, so the app routes the trip as the planner measured it.

  /// The settings as the API takes them
  Map<String, bool> get preferences => {
        'avoid_motorways': Setup().avoidMotorways,
        'avoid_main_roads': Setup().avoidAroads,
        'avoid_ferries': Setup().avoidFerries,
        'avoid_tolls': Setup().avoidTollRoads,
      };

  /// A route preference's chip changed - field is one of the plan's fields
  /// (avoid_motorways, quiet_roads, avoid_ferries, avoid_tolls)
  void changeRoutePreference(String field, bool on) {
    _setting(field, on);
    changeField(field, on);
  }

  /// The settings as the plan has them - its request may have asked for more
  void _settingsFrom(Map<String, dynamic> planned) {
    for (String field in [
      'avoid_motorways',
      'quiet_roads',
      'avoid_ferries',
      'avoid_tolls'
    ]) {
      _setting(field, planned[field] == true);
    }
  }

  void _setting(String field, bool on) => switch (field) {
        'avoid_motorways' => Setup().avoidMotorways = on,
        'quiet_roads' => Setup().avoidAroads = on,
        'avoid_ferries' => Setup().avoidFerries = on,
        'avoid_tolls' => Setup().avoidTollRoads = on,
        _ => null,
      };

  /// Back to the request, e.g. to ask for something else
  void newRequest() {
    _poll?.cancel();
    status = PlannerStatus.idle;
    message = '';
    notifyListeners();
  }

  Future<void> _start({Map<String, dynamic>? changed}) async {
    if (request.isEmpty) return;
    _poll?.cancel();
    status = PlannerStatus.working;
    progress = 'Reading your request';
    message = '';
    notifyListeners();
    try {
      LatLng here = MapService().currentPosition;
      http.Response response = await postWebData(
          uri: Uri.parse('$urlPlanner/plan'),
          body: jsonEncode({
            'request': request,
            if (MapService().hasPosition) ...{
              'lat': here.latitude,
              'lng': here.longitude,
            },
            if (changed != null)
              'fields': _toSend(changed)
            else
              'preferences': preferences,
          }));
      Map body = response.body.isEmpty ? {} : jsonDecode(response.body);
      if (response.statusCode != 202) {
        _end(
            PlannerStatus.failed,
            [401, 407, 408].contains(response.statusCode)
                ? 'Log in to use AI assist'
                : body['msg'] ?? "AI assist isn't available just now");
        return;
      }
      _jobId = body['id'];
      _polls = 0;
      _poll = Timer.periodic(_pollEvery, (_) => _check());
    } catch (e) {
      developer.log('PlannerService._start(): ${e.toString()}', name: 'error');
      _end(PlannerStatus.failed,
          "Couldn't reach AI assist - check your connection and try again");
    }
  }

  /// The user chose which of the places with a name they meant (key is
  /// start or finish). Once none is in doubt, it's planned.
  Future<void> choosePlace(String key, Map place) async {
    fields ??= {};
    fields![key] = {
      for (MapEntry entry in place.entries)
        if (!['options', 'unsure'].contains(entry.key)) entry.key: entry.value
    };
    if (status != PlannerStatus.choose) {
      edited = true; // Plan again
      notifyListeners();
    } else if (['start', 'finish']
        .any((key) => fields![key] is Map && fields![key]['unsure'] == true)) {
      notifyListeners();
    } else {
      await planAgain();
    }
  }

  /// The fields as the API takes them - a town found or chosen by its id,
  /// none for where the user is
  Map<String, dynamic> _toSend(Map<String, dynamic> changed) {
    dynamic place(dynamic given) => given is Map
        ? (given['id'] == null ? null : {'id': given['id']})
        : given;
    return {
      ...changed,
      'start': place(changed['start']),
      'finish': place(changed['finish']),
    };
  }

  Future<void> _check() async {
    if (_checking) return;
    if (++_polls > _mostPolls) {
      _end(PlannerStatus.failed,
          'AI assist is taking too long - please try again');
      return;
    }
    _checking = true;
    try {
      http.Response response = await getWebData(
          uri: Uri.parse('$urlPlanner/plan/$_jobId'), secure: true);
      if (response.statusCode != 200) return; // tried again next time
      Map<String, dynamic> job = jsonDecode(response.body);
      switch (job['status']) {
        case 'working':
          if ((job['progress'] ?? '') != progress) {
            progress = job['progress'] ?? progress;
            notifyListeners();
          }
        case 'done':
          _poll?.cancel();
          result = job['result'];
          fields = Map<String, dynamic>.from(result?['understood'] ?? {});
          edited = false;
          status = PlannerStatus.done;
          _settingsFrom(fields!); // before it's routed
          await _showTrip();
          notifyListeners();
        case 'choose':
          _poll?.cancel();
          result = job['result'];
          fields = Map<String, dynamic>.from(result?['understood'] ?? {});
          edited = false;
          status = PlannerStatus.choose;
          message = job['message'] ?? 'Which place did you mean?';
          notifyListeners();
        default:
          _end(
              job['status'] == 'refused'
                  ? PlannerStatus.refused
                  : PlannerStatus.failed,
              job['message'] ?? "AI assist couldn't plan that trip");
      }
    } catch (e) {
      developer.log('PlannerService._check(): ${e.toString()}', name: 'error');
    } finally {
      _checking = false;
    }
  }

  void _end(PlannerStatus ended, String why) {
    _poll?.cancel();
    status = ended;
    message = why;
    notifyListeners();
  }

  // ---- the suggested trip --------------------------------------------------

  Future<void> _showTrip() async {
    Map<String, dynamic> suggested = trip;
    List<Waypoint> waypoints = [];
    for (Map w in suggested['waypoints'] ?? []) {
      if (w['great_road'] == true) {
        waypoints.add(Waypoint(point: Point(w['start'][1], w['start'][0])));
        waypoints.add(Waypoint(point: Point(w['end'][1], w['end'][0])));
      } else {
        waypoints.add(Waypoint(point: Point(w['lng'], w['lat'])));
      }
    }
    if (waypoints.length < 2) return;
    CurrentTripItem current = CurrentTripItem();
    await current.loadSuggestion(
      // A round trip ends where it starts - a revisit of the start
      waypoints: current.markRevisits(waypoints: waypoints),
      stops: [
        for (Map stop in suggested['stops'] ?? [])
          PointOfInterest(
            point: Point(stop['lng'], stop['lat']),
            type: poiTypeOf(stop['kind'] ?? ''),
            name: stop['name'] ?? '',
            description: describePlace(stop),
            score: (stop['rating'] ?? 0).toDouble(),
            scored: stop['ratings'] ?? 0,
          )
      ],
      // The trip's details, for the user to check when they save it
      title: suggested['title'] ?? 'AI assist trip',
      subTitle: (suggested['tagline'] ?? '').toString().isNotEmpty
          ? suggested['tagline']
          : 'Planned with AI assist',
      body: suggested['summary'] ?? '',
    );
    MapService().leadingWidgetController.changeWidget(1);
    await _showCandidates();
    await _fitTrip(waypoints);
  }

  /// Shows the whole trip in the part of the map the drawer doesn't cover
  Future<void> _fitTrip(List<Waypoint> waypoints) async {
    MapLibreMapController? controller = MapService().controller;
    if (controller == null) return;
    Iterable<num> lngs = waypoints.map((w) => w.point.x);
    Iterable<num> lats = waypoints.map((w) => w.point.y);
    double side = kIsWeb ? MapService().sideDrawerController?.getWidth() ?? 0 : 0;
    double below = kIsWeb ? 0 : MapService().bottomDrawerController?.getHeight() ?? 0;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(lats.reduce(min).toDouble(), lngs.reduce(min).toDouble()),
              northeast: LatLng(lats.reduce(max).toDouble(), lngs.reduce(max).toDouble())),
          left: 40 + side,
          top: 100,
          right: 40,
          // and above the chips
          bottom: 40 + below + (kIsWeb ? 100 : 0)));
    } catch (e) {
      developer.log('PlannerService._fitTrip(): ${e.toString()}', name: 'error');
    }
  }

  /// The trip's been saved - it's the user's now
  Future<void> tripSaved() async {
    await _clearCandidates();
    result = null;
    status = PlannerStatus.idle;
    notifyListeners();
  }

  /// The trip's been cleared
  Future<void> reset() async {
    _poll?.cancel();
    await _clearCandidates();
    result = null;
    fields = null;
    status = PlannerStatus.idle;
    message = '';
    notifyListeners();
  }

  // ---- the candidates: everything else the planner found -------------------

  static const String _source = 'planner-candidates';
  static const String _layer = 'planner-candidates-layer';
  bool _layerAdded = false;

  /// A new style drops runtime layers - see MapService().onStyleLoaded()
  Future<void> styleLoaded() async {
    _layerAdded = false;
    if (result != null && CurrentTripItem().aiSuggestion) {
      await _showCandidates();
    }
  }

  Future<void> _addLayer() async {
    MapLibreMapController? controller = MapService().controller;
    if (_layerAdded || controller == null) return;
    // Still there from before - e.g. a style loaded event that didn't
    // replace the style
    if ((await controller.getLayerIds()).contains(_layer)) {
      _layerAdded = true;
      return;
    }
    try {
      await controller.addGeoJsonSource(
          _source, {"type": "FeatureCollection", "features": []});
    } catch (_) {} // the source outlived its layer
    CircleLayerProperties circles = CircleLayerProperties(
      circleRadius: [
        Expressions.caseExpression,
        [Expressions.get, 'choice'],
        8,
        5
      ],
      circleColor: Setup().aiRouteColourHex(),
      circleOpacity: 0.55,
      circleStrokeColor: '#ffffff',
      circleStrokeWidth: 1.5,
    );
    try {
      // Under the trip's own markers
      await controller.addCircleLayer(_source, _layer, circles,
          belowLayerId: 'way-marker-layer', enableInteraction: false);
    } catch (_) {
      await controller.addCircleLayer(_source, _layer, circles,
          enableInteraction: false);
    }
    _layerAdded = true;
  }

  Future<void> _showCandidates() async {
    MapLibreMapController? controller = MapService().controller;
    if (controller == null) return;
    Map<String, dynamic> suggested = trip;
    Set onTrip = {
      for (Map place in [...?suggested['stops'], ...?suggested['waypoints']])
        place['id']
    };
    Set choices = {for (Map place in suggested['choices'] ?? []) place['id']};
    List<Map<String, dynamic>> features = [];
    for (int i = 0; i < candidates.length; i++) {
      Map place = candidates[i];
      if (onTrip.contains(place['id']) || place['lat'] == null) continue;
      features.add({
        "type": "Feature",
        "id": i,
        "geometry": {
          "type": "Point",
          "coordinates": [place['lng'], place['lat']]
        },
        "properties": {
          "choice": choices.contains(place['id']),
          "label": placeLabel(place),
        },
      });
    }
    try {
      await _addLayer();
      await controller.setGeoJsonSource(
          _source, {"type": "FeatureCollection", "features": features});
    } catch (e) {
      developer.log('PlannerService._showCandidates(): ${e.toString()}',
          name: 'error');
    }
  }

  Future<void> _clearCandidates() async {
    if (!_layerAdded) return;
    try {
      await MapService().controller?.setGeoJsonSource(
          _source, {"type": "FeatureCollection", "features": []});
    } catch (_) {}
  }

  /// A candidate under the crosshair, in a line - or null. The Status Bar
  /// shows it with what the chips will do there (MapService().onIdle()).
  Future<String?> candidateAt(MapLibreMapController controller) async {
    if (result == null || !CurrentTripItem().aiSuggestion) return null;
    try {
      await _addLayer();
      Point<num> centre =
          await controller.toScreenLocation(controller.cameraPosition!.target);
      Rect rect = Rect.fromCenter(
          center: Offset(centre.x.toDouble(), centre.y.toDouble()),
          width: 24,
          height: 24);
      List features =
          await controller.queryRenderedFeaturesInRect(rect, [_layer], null);
      return features.isEmpty ? null : features.first['properties']['label'];
    } catch (e) {
      developer.log('PlannerService.candidateAt(): ${e.toString()}',
          name: 'error');
      return null;
    }
  }
}

/// The app's point of interest type for a kind of place the planner found
int poiTypeOf(String kind) => switch (kind) {
      'pub' => 1,
      'cafe' => 2,
      'castle' || 'historic' || 'church' || 'windmill' => 3,
      'museum' => 5,
      'viewpoint' || 'nature' || 'birdwatching' || 'village' => 0,
      _ => 8,
    };

/// What a place is and where - e.g. "pub, Croft"
String placeWhat(Map place) => [
      (place['what'] ?? place['kind'] ?? '').toString().replaceAll('_', ' '),
      place['town'] ?? '',
    ].where((part) => part.toString().isNotEmpty).join(', ');

/// A place in a line - its name, what it is and its rating
String placeLabel(Map place) {
  String rating = (place['ratings'] ?? 0) > 0
      ? ' ★${(place['rating'] ?? 0).toStringAsFixed(1)}'
      : '';
  return '${place['name'] ?? ''} (${placeWhat(place)})$rating';
}

/// A stop's description: what it is, why AI assist chose it, its rating,
/// what users said and what Wikipedia says
String describePlace(Map place) {
  List<String> lines = [placeWhat(place)];
  if ((place['why'] ?? '').toString().isNotEmpty) {
    lines.add('Chosen because: ${place['why']}');
  }
  int ratings = place['ratings'] ?? 0;
  if (ratings > 0) {
    lines.add('Rated ${(place['rating'] ?? 0).toStringAsFixed(1)} out of 5 '
        'by $ratings Drives user${ratings == 1 ? '' : 's'}');
  }
  if ((place['description'] ?? '').toString().isNotEmpty) {
    lines.add(place['description']);
  }
  for (Map review in place['reviews'] ?? []) {
    lines.add('"${review['comment']}"');
  }
  if (place['wikipedia'] case Map wikipedia) {
    lines.add('${wikipedia['extract']} (From Wikipedia)');
  }
  lines.add(place['source'] == 'drives'
      ? 'From a trip a Drives user published.'
      : 'From OpenStreetMap.');
  return lines.join('\n');
}
