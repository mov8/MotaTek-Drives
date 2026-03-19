import 'dart:math';
import '/services/services.dart'; // hide getPosition;
import '/classes/classes.dart';
import '/tiles/tiles.dart';
import '/classes/route.dart' as mt;
import '/models/models.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

enum PinTypes {
  beautySpot,
  pub,
  cafe,
  historicBuilding,
  monument,
  park,
  parking,
  other,
  start,
  end,
  routePoint,
  waypoint,
  goodRoadStart,
  goodRoadEnd,
  newPointOfInterest,
  follower,
  tripStart,
  tripEnd,
}
/*
class Feature extends Marker {
  final int row;
  final String uri;
  final int id;
  final int drive;
  final int type;
  final int poiType;
  final LatLng maxPoint;
  final String pointOfInterestUri;

  const Feature(
      {this.row = -1,
      this.uri = '',
      this.id = -1,
      this.drive = -1,
      this.type = 0,
      this.poiType = 0,
      double iconSize = 30,
      super.width = 30,
      super.height = 30,
      super.child = const Icon(Icons.pin),
      super.point = const LatLng(0, 0),
      this.maxPoint = const LatLng(0, 0),
      this.pointOfInterestUri = ''});

  factory Feature.fromMap({
    required Map<String, dynamic> map,
    int row = -1,
    double size = 30,
    required Function onTap,
  }) {
    return Feature(
      row: row == -1 ? map['row'] ?? -1 : row,
      uri: map['uri'],
      id: -1,
      drive: map['drive'] ?? -1,
      type: map['type'] ?? 0,
      poiType: map['feature_id'] ?? 1,
      point: LatLng(map['min_lat'] ?? 50.0, map['min_lng'] ?? 0.0),
      maxPoint: LatLng(map['max_lat'] ?? 50.0, map['max_lng'] ?? 0.0),
      pointOfInterestUri: map['point_of_interest_uri'] ?? '',
      width: size,
      height: size,
    );
  }

  factory Feature.fromFeature(
      {required Feature feature,
      LatLng? point,
      int? row,
      double? size,
      Widget? child}) {
    return Feature(
        row: row ?? feature.row,
        uri: feature.uri,
        id: feature.id,
        drive: feature.drive,
        type: feature.type,
        poiType: feature.poiType,
        point: point ?? feature.point,
        maxPoint: point ?? feature.maxPoint,
        pointOfInterestUri: feature.pointOfInterestUri,
        width: size ?? feature.width,
        height: size ?? feature.height,
        child: child ?? feature.child);
  }

  Fence getBounds() {
    return Fence(northEast: maxPoint, southWest: point);
  }

  toMap() {
    return {
      'row': row,
      'id': id,
      'uri': uri,
      'feature_id': id,
      'drive': drive,
      'type': type,
      'max_lat': maxPoint.latitude,
      'max_lng': maxPoint.longitude,
      'min_lat': point.latitude,
      'min_lng': point.longitude,
      'point_of_interest_uri': pointOfInterestUri,
    };
  }
}

*/

/// PublishedFeatures - maintains the lists of features and cards based on the
/// camara bounds - the lists it maintains are:
///
/// 1 - features  - a full list of all the available features obtained
///                 from the API or the SQLite cache.
/// 2 - cache     - a subset of the features based on the current
///                 map position with a cache margin.
/// 3 - markers   - a subset of the cache features that are within the
///                 camara's visible bounds that show as Markers on the
///                 map.
/// 4 - cards     - a list of Cards for the appropriate visible features
///                 to be displayed at the bottom of the screen.
///
/// Methods:
///   update(bounds, margin, zoom)
///         bounds -updates the lists based on the camara.visibleBounds
///         margin (in degrees) - determines the size of the cache.
///         zoom -  determins which features are visible - at low
///                 zoom levels markers and cards may be hidden
///
/// Callback:
///   onUpdate(bool) reports back if any of the visible items have changed
///
/// if the camera bounds moves outside the cache bounds the whole
/// features are filtered again to repoulate the cache, the
/// visible list and the cards
///
/// getPublishedFeatures(zoom, pinTap) creates an instance of PublishedFeatures
///     as there aren't asyc constructors in Dart. It populates features
///     from the API or SQLite database.
///     The zoom parameter sets the initial zoom level
///     The pinTap parameter passes the onPinTap callback for the
///     MarkerWidgets that are generated.
///

Future<PublishedFeatures> getPublishedFeatures(
    {double zoom = 10,
    pinTap,
    Function(int, String)? onGetTrip,
    showRoutes = false,
    ExpandNotifier? expandNotifier,
    Map<String, int>? pointOfInterestLookup}) async {
  // List<Feature> features = [];
  Map<String, int> pointOfInterestLookup = {};

  List<Feature> features = (await getFeatures(
      zoom: 10, onTap: pinTap, pointOfInterestLookup: pointOfInterestLookup));
  return PublishedFeatures(
    features: features,
    pointOfInterestLookup: pointOfInterestLookup,
    pinTap: pinTap,
    onGetTrip: onGetTrip,
    showRoutes: showRoutes,
    expandNotifier: expandNotifier,
  );
}

/*
class OsmFeatures {
  Function(int)? pinTap;
  List<OsmAmenity> amenities = [];
  Fence? cacheFence = Fence.create();
  OsmFeatures({required this.amenities, this.pinTap, this.cacheFence});
  Future<bool> update({required Fence fence, double size = 30}) async {
    try {
      amenities =
          await getOsmAmenities(polygon: fence.polygonString(), size: size);
      debugPrint('amenities polygonString = $amenities');
      return true;
    } catch (e) {
      debugPrint('Error getting OSM data ${e.toString()}');
      return true;
    }
  }

  void resizeOsmAmenities({required double size}) {
    for (int i = 0; i < amenities.length; i++) {
      amenities[i] = OsmAmenity.morph(osmAmenity: amenities[i], size: size);
    }
  }

  void clear() {
    amenities.clear();
  }
}
*/
class PublishedFeatures {
  Function(bool)? onUpdate;
  Function(int) pinTap;
  Function(int, String)? onGetTrip;
  List<Feature> features = [];
  List<Feature> cache = [];
  List<Feature> markers = [];
  List<mt.Route> routes = [];
  List<Map<String, dynamic>> routesDetails = [];
  List<mt.Route> goodRoads = [];
  List<Card> cards = [];
  List<Card> routeCards = [];
  Fence cacheFence = Fence.create();
  List<int> exclude;
  int showZoom;
  bool showRoutes;
  bool updated = false;
  Map<String, int> pointOfInterestLookup = {};
  ExpandNotifier? expandNotifier;
  LatLng screenCenter = LatLng(0, 0);

  final GoodRoadRepository goodRoadRepository = GoodRoadRepository();
  final ImageRepository imageRepository = ImageRepository();
  final RouteRepository routeRepository = RouteRepository();
  final TripItemRepository tripItemRepository = TripItemRepository();
  final PointOfInterestRepository pointOfInterestRepository =
      PointOfInterestRepository();

  PublishedFeatures(
      {required this.features,
      required this.pinTap,
      required this.pointOfInterestLookup,
      this.onGetTrip,
      this.onUpdate,
      this.exclude = const [12, 14, 16, 17, 18],
      this.expandNotifier,
      this.showZoom = 10,
      this.showRoutes = false});

  Future<void> populate({double zoom = 10, onTap}) async {
    features.clear();
    features.addAll(await getFeatures(zoom: zoom, onTap: onTap));
    return;
  }

  Future<Card?> getCard({
    required Feature feature,
    required int index,
    List<Card>? children,
    ExpandNotifier? expandNotifier,
  }) async {
    if (feature.type == 0) {
      TripItem tripItem = await tripItemRepository.loadTripItem(
          key: feature.row, id: feature.id, uri: feature.uri);
      tripItem.closest = distanceBetween(
              Point(Setup().lastPosition.longitude,
                  Setup().lastPosition.longitude),
              feature.point)
          .truncate();
      return Card(
        key: Key('pin_${feature.row}'),
        shadowColor: Colors.transparent,
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: TripTile(
          tripItem: tripItem,
          imageRepository: imageRepository,
          index: index,
          onGetTrip: onGetTrip,
        ),
      );
    } else if (feature.type == 1 || feature.type == 6 || feature.type == 3) {
      PointOfInterest? pointOfInterest =
          await pointOfInterestRepository.loadPointOfInterest(
              key: feature.row, id: feature.id, uri: feature.uri);
      return Card(
        key: Key('pin_${feature.row}'),
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: PointOfInterestTile(
          expandNotifier: expandNotifier,
          index: index,
          pointOfInterest: pointOfInterest!,
          imageRepository: imageRepository,
          canEdit: false,
        ),
      );
    }
    return null;
  }
}
