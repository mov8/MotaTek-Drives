import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart' hide Position;
import 'package:flutter/foundation.dart';
import '/screens/screens.dart';
import '/services/services.dart' hide getPosition;
import '/models/models.dart';
import '/helpers/helpers.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

BottomDrawerController _bottomDrawerController = BottomDrawerController();

/*
This might well be a good path to follow as it uses Flutter_maps

https://www.reddit.com/r/openstreetmap/comments/1ew60cw/how_i_learned_to_create_custom_maps_for_my_mobile/
https://openmaptiles.org/docs/generate/create-custom-extract/
https://github.com/maplibre/maputnik/wiki <- map styling

https://docs.maptiler.com/flutter/

https://project-osrm.org/docs/v5.5.1/api/#trip-service
https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

creating vector tiles from osm
https://osmand.net/docs/technical/map-creation/create-offline-maps-yourself/
https://wiki.openstreetmap.org/wiki/Osmator

https://openmaptiles.org/osm2vectortiles/ -AndMapCre creating vector tiles from osm
https://openmaptiles.org/docs/

TILE CACHING objectbox looks really useful it stores Dart objects and is really fast
https://pub.dev/packages/objectbox - looks really neat with cross-device synchronisation
https://github.com/JaffaKetchup/flutter_map_tile_caching/blob/main/lib/src/backend/impls/objectbox/models/src/tile.dart

Vector tiles from osrm data:
Look at Tilemaker that creates vector tiles from
*/

int testInt = 0;

enum MessageActions { none, read, write, writing, reply, send, delete }

enum ApiActions { none, pointOfInterest, waypoint, goodRoad }

class CurrentPosition {
  UserLocation? location;
  Position? position;
  late double latitude;
  late double longitude;
  late double heading;
  late int speed;

  CurrentPosition(
      {this.location,
      this.position,
      this.latitude = 0,
      this.longitude = 0,
      this.heading = 0,
      this.speed = 0}) {
    if (location != null) {
      latitude = location!.position.latitude;
      longitude = location!.position.longitude;
      speed = (location!.speed! * metersToMiles * 60 * 60).toInt();
      if (location!.heading != null) {
        heading = location!.heading!.trueHeading ?? 0;
      }
    } else if (position != null) {
      latitude = position!.latitude;
      longitude = position!.longitude;
      speed = (position!.speed * metersToMiles * 60 * 60).toInt();
      heading = position!.heading;
    }
  }
  LatLng get latLng => LatLng(latitude, longitude);
  Point get point => Point(longitude, latitude);
  List<double> get list => [longitude, latitude];
}

class CreateTripController {
  _CreateTripState? _createTripState;
  void _addState(_CreateTripState createTripState) {
    _createTripState = createTripState;
  }

  bool isAttached() => _createTripState != null;

  Future<ui.Image?> getMapImage() async {
    try {} catch (e) {
      debugPrint("Can't get the map image");
    }
    return null;
  }

  void updateValues({required CreateTripValues values}) {
    try {} catch (e) {
      debugPrint("Can't update CreateTrip state values: ${e.toString()}");
    }
  }

  void updateArguements({required TripArguments arguments}) {
    try {
      _createTripState?.updateArguments(arguments: arguments);
    } catch (e) {
      debugPrint("Can't update the arguments: ${e.toString()}");
    }
  }

  bool? getTripInfo({bool prompt = false}) {
    try {} catch (e) {
      debugPrint("Can't stop following");
    }
    return false;
  }

  void drive({bool follow = false}) {
    try {} catch (e) {
      debugPrint('Controller error: ${e.toString()}');
    }
  }

  void changePage(String page) {
    if (_createTripState != null) {
      _createTripState?.changePage(page);
    }
  }

  void update() {
    _createTripState?.update();
  }
}

/// OVERALL STRUCTURE
/// 1 CurrentTripItem - singleton that looks after the persistent data - routes, waypoints etc
///   CurrentTripItem is changed first as many of the map updates depend on previously entered
///   data - Clear Trip Extend Start etc.
///
/// 2 MapService - singleton that looks after the map display. Requests for the map to change
///   - are effected by posting MapRequests into the updateRequest() method. These requests
///     are initiated by the ActionChips
///
///
///     ActionChip -> CurrentTripItem() -> MapService()
///   MapService is also controlled by the FABS which change the MapCenter, Zoom etc.
///
///   the MapRequest is actioned on the onIdle and are changes mage to the geoJson
///   MapService also actions any immediate requests like changing position and zoom
///
///
///
/// CreateTripChips()
///   Displays the appropriate chips for the options the user needs based on the tripStates held in CurrentTripItem
///   Updates the map CurrentTripItem() singleton based on the chip just pressed
///   Returns to CreateTrip() page the action just taken through the MyTripAction Enum
///
///   CreateTripChip().onChipTap() ->
///       update CurrentTripItem() -> CreateTripChips().onUpdate ->
///       _executeChipActions(MyTripActions) -> update Drawers()
///
///

class CreateTrip extends StatefulWidget {
  final String mapType;
  const CreateTrip({
    super.key,
    this.mapType = 'explore',
  });
  @override
  State<CreateTrip> createState() => _CreateTripState();
}

class _CreateTripState extends State<CreateTrip> with TickerProviderStateMixin {
  final GlobalKey mapKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();

  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');

  final start = TextEditingController();
  final end = TextEditingController();

  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List tripItems = [];
  int id = -1;
  int userId = -1;
  int type = -1;
  int _directionsIndex = 0;
  double iconSize = 35;
  StreamSubscription<Position>? _positionStream;
  late FocusNode fn1;
  late ui.Size screenSize;
  late ui.Size appBarSize;
  double mapHeight = 250;
  double listHeight = 0;
  final TripPreferences _preferences = TripPreferences();
  late Position _currentPosition;
  CurrentPosition _userPosition = CurrentPosition();
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  var moveDelay = const Duration(seconds: 2);
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  final List<MyTripItem> _myTripItems = [];
  late final StreamController<double?> _alignPositionStreamController;
  late final StreamController<void> _alignDirectionStreamController;
  late final DirectionTileController _directionTileController;
  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  int initialLeadingWidgetValue = 0;
  String wpId = '';
  String grId = '';
  String images = '';
  String mapStyle = '';

  final bool _debugging = false; //true; //false; //true;
  final String _debuggingRoute = ''; // 'Debug'; // ''; //'Debug';

  UserLocation? useLocation;
  TripArguments? _tripArguments;
  DrivesRequest? _drivesRequest;

  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  final ImageRepository _imageRepository = ImageRepository();
/*
  Future<String> getPoiName({required latLng, name = ''}) async {
    dynamic jsonResponse;

    var url = Uri.parse(
        'https://photon.komoot.io//reverse?lon=${latLng.longitude}&lat=${latLng.latitude}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 2),
          onTimeout: () {
        return name;
      });
      if (response.statusCode == 200) {
        jsonResponse = jsonDecode(response.body);
        if (jsonResponse['features'][0]['properties']['name'] != null) {
          name = jsonResponse['features'][0]['properties']['name'];
        }
        return name;
      } else {
        return name;
      }
    } catch (e) {
      return name;
    }
  }
*/
  @override
  void initState() {
    super.initState();
    MapService().createTripController!._addState(this);

    /// Have to have a controller instance for each Widget
    /// being controlled, as the controller shares the widgets state
    /// A single controller would then share the state of
    /// all the widgets it controls - not good.
    ///

    MapService().statusBarController = StatusBarController();
    MapService().zoomFabController = ZoomFabController();
    _directionTileController = DirectionTileController();
    _bottomDrawerController.close();

    if (_debugging) {
      _debugPositionController = StreamController<Position>();
      _debugRoute = FollowRoute(controller: _debugPositionController);
    }

    try {
      dataFromDatabase();
      if (CurrentTripItem().routes.isNotEmpty) {
        CurrentTripItem().mapUpdates = MapUpdates.updateAll;
      } else {
        CurrentTripItem().clearAll(newTripState: TripState.none);
      }
      _alignPositionStreamController = StreamController<double?>.broadcast();
      _alignDirectionStreamController = StreamController<void>.broadcast();
      fn1 = FocusNode();
      listHeight = -1;
      socket.onConnectError((_) => debugPrint('connect error'));
      socket.onError((data) => debugPrint('Error: ${data.toString()}'));
      socket.on(
        'message_from_trip',
        (data) {
          TripMessage tripMessage = TripMessage.fromSocketMap(data);
          if (tripMessage.message.isNotEmpty) {
            debugPrint('message: ${tripMessage.message}');
          }

          if (tripMessage.email != Setup().user.email &&
              (tripMessage.message.isNotEmpty ||
                  ['p', 's'].contains(tripMessage.type))) {
            try {
              if (['p', 's'].contains(tripMessage.type) &&
                  tripMessage.lat != 0 &&
                  tripMessage.lng != 0) {
                for (int i = 0; i < _following.length; i++) {
                  if (_following[i].email == tripMessage.email &&
                      _following[i].email != Setup().user.email) {
                    _following[i] = _following[i].moveFollower(
                        newPosition: [tripMessage.lng, tripMessage.lat]);
                    if (tripMessage.type == 's') {
                      _following[i].manufacturer = tripMessage.manufacturer;
                      _following[i].model = tripMessage.model;
                      _following[i].carColour = tripMessage.carColour;
                      _following[i].registration = tripMessage.registration;
                      _following[i].phoneNumber = tripMessage.phoneNumber;
                      _following[i].position = [
                        tripMessage.lng,
                        tripMessage.lat
                      ];
                      _following[i].accepted = tripMessage.accepted;
                    }
                    if (_following[i].track) {}
                  }
                }
              } else {
                for (int i = 0; i < _following.length; i++) {
                  if (_following[i].email == tripMessage.email) {
                    tripMessage.manufacturer = _following[i].manufacturer;
                    tripMessage.model = _following[i].model;
                    tripMessage.carColour = _following[i].carColour;
                    tripMessage.registration = _following[i].registration;
                    break;
                  }
                }

                CurrentTripItem().tripMessages.add(tripMessage);
              }
              setState(() {});
            } catch (e) {
              debugPrint('Error: ${e.toString()}');
            }
          }
        },
      );

      if (socket.connected) {}
    } catch (e) {
      developer.log(
          'Error CreateTrip().initState() called error: ${e.toString()}',
          name: 'error');
    }
  }

  void update() {
    setState(() => {});
  }

  void changePage(String page) {
    setState(() {});
  }

  void updateArguments({required TripArguments arguments}) async {
    if (_tripArguments != arguments) {
      if (kIsWeb) {
        MapService().sideDrawerController!.close();
      }
      _tripArguments = arguments; // <--
      await updateTripArguments();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _alignPositionStreamController.close();
    _alignDirectionStreamController.close();
    _debugPositionController.close();
    fn1.dispose();
    if (socket.connected) {
      socket.close;
    }

    streamSocket.dispose();
    super.dispose();
  }

  ///
  /// Returns the routepoints and the waypoint data for the added waypoint
  /// _SimpleUri (http://10.101.1.150:5000/route/v1/driving/-0.0237985,52.9776561;-0.0237985,52.9776561?steps=true&annotations=true&geometries=geojson&overview=full&exclude=motorway&exclude=trunk&exclude=primary)

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => MapService().createTripStackController?.refresh());
    return Scaffold(
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      // The main drawer is on the shell Scaffold in main.dart
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: HandleCTFabs(
        top: 20, //appBar.preferredSize.height + kToolbarHeight,
        controller: MapService().fabsController,
      ),
      body: _getPortraitBody(),
      bottomSheet: kIsWeb
          ? null
          : BottomDrawer(
              context: context,
              maxHeight: 500,
              controller: MapService().bottomDrawerController,
              content: CurrentTripItem(),
              imageRepository: _imageRepository,
              onOpened: onOpened,
            ),
    );
  }

// https://drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf

  Future getPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services not enabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied. Check your settings');
      }
    }
  }

  Future<bool> dataFromDatabase() async {
    try {
      await getPermission();
      _currentPosition = await Geolocator.getCurrentPosition();
      // Setup is loaded from Hive at startup (main.dart initialise())
      if (Setup().hasLoggedIn) {
        _preferences.avoidMotorways = Setup().avoidMotorways;
        _preferences.avoidFerries = Setup().avoidFerries;
        _preferences.avoidTollRoads = Setup().avoidTollRoads;
      }
      return true;
    } catch (e) {
      debugPrint('Error getting features data: ${e.toString()}');
      return false;
    }
  }

  double appBarHeight() {
    double abHeight = 200;
    final abKeyContext = _appBarKey.currentContext;
    if (abKeyContext != null) {
      final box = abKeyContext.findRenderObject() as RenderBox;
      abHeight = box.size.height;
    }
    return abHeight;
  }

  void detailClose() {
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      setState(() {});
    }
  }

  Future<void> updateTripArguments() async {
    try {
      switch (_tripArguments!.appState) {
        case AppState.myTrips:
          {
            _myTripItems.clear();
            _myTripItems.addAll(await loadSavedTrips());
            try {
              await MapService().sideDrawerController!.setContent(
                  content: BottomDrawerItems.favourites,
                  // a List<MyTripItem> - casting it to List<Widget> threw
                  drawerItems: _myTripItems);
              Future.delayed(Duration(milliseconds: 200));
              setState(
                  () => MapService().sideDrawerController!.open(width: 0.4));
            } catch (e) {
              developer.log(
                  'Error setting sideDrawer contents: ${e.toString()}',
                  name: 'error');
            }
          }
        case AppState.trips:
          {
            _drivesRequest ??= DrivesRequest(onUpdated: (_) {});
          }
        default:
          {
            if (Setup().hasLoggedIn) {
              _preferences.avoidMotorways = Setup().avoidMotorways;
              _preferences.avoidFerries = Setup().avoidFerries;
              _preferences.avoidTollRoads = Setup().avoidTollRoads;
            }
          }
      }
    } catch (e) {
      developer.log('Error calling updateArguments()  ${e.toString()}',
          name: 'error');
    }
    return;
  }

  Widget _getPortraitBody() {
    _tripArguments ??=
        TripArguments(activeChip: 2, appState: AppState.createTrip);
    return Stack(children: [
      KeyboardSteadyMap(child: MapService().mlMap!),
      CreateTripStack(controller: MapService().createTripStackController)
    ]);
  }

  /// callback for BottomDrawer object. Is fired when the BottomDrawer.AnimatedContainer has finished its animation.
  /// Value of open is true if the drawer is currently open.
  /// This callback is used to update the map when the user has completed adding data like the trip heading, points of
  /// interest etc.
  Future<void> onOpened(bool open) async {
    if (!open) {
      CurrentTripItem().tripActions = TripActions.none;
      if (MapService().controller != null &&
          CurrentTripItem().mapUpdates != MapUpdates.none) {
        MapService().controller!.animateCamera(
              CameraUpdate.zoomBy(0.000001),
            );
      }
      if ([TripState.manualStart, TripState.goodRoadStart]
          .contains(CurrentTripItem().tripState)) {
        CurrentTripItem().tripState = CurrentTripItem().tripValues.isEditing
            ? TripState.editing
            : TripState.manual;
      }

      /// Put the default values back into the drawer after other is viewed and drawer is closed
      if (tripItems.isNotEmpty) {
        MapService().sideDrawerController!.setContent(
            content: BottomDrawerItems.favourites,
            drawerItems: tripItems as List<Widget>);
      }
      if (MapService().sideDrawerController!.content ==
              BottomDrawerItems.settings &&
          MapService().sideDrawerController!.changed) {
        Setup().save(); // <-- Writes the setup changes to Hive
      }
    }
    setState(() {});
  }

  /// closeAndUpdateDrawer() closes the drawer and refreshes its contents with
  /// the new CurrentTripItem(). This ensures all completed tiles are contracted
  void closeAndUpdateDrawer(bool closed) {
    _bottomDrawerController.close();
  }

  Future<String> goodRoadTargetted({required Point point}) async {
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 15,
        height: 15);
    var features = await MapService()
        .controller!
        .queryRenderedFeaturesInRect(rect, ['good_roads'], null);
    if (features.isNotEmpty) {
      debugPrint('feature found!');
      for (int i = 0; i < features.length; i++) {
        if (features[i]['geometry']['type'] == 'LineString') {
          return features[i]['id'];
        }
      }
    }
    return '';
  }

  /// updateHighlightedZone() uses MapLibre's setFilter() method to change the filter conditions
  /// on a layer. This avoids having to identify all the visible features, and the decide if they
  /// should be visible.
  /// In this case the objects to be highlighted will be made visible:
  /// The route and good road highlight layer, and their associated shields.
  /// The geoJson objects have to have a min_lat min_lon etc that is calculated by
  /// Mariadb.
  /// It makes sense to put all the highlight-able features under a single layer

  /// Opens the bottomDrawer to add the details of the last added CurrentTripItem().PointOfInterest
  /// _executeChipActions controls the behaviour of the bottom drawer through its controller
  /// The instruction to change the BottomDrawer come from CreateTripChips.onUpdate()
  /// The controller options are:
  ///   Control the open / close state of the drawer
  ///   Change the content of the drawer
  ///
  /// If the trip descriptions or point of interest descriptions are incomplete
  /// the bottom drawer shows the incomplete Expand Tile opened ready for the user to complete
  /// the data.
  /// The data options are:
  ///   1: Tap or drag divider bar: Trip details + points of interest
  ///   2: Point of Interest chip add a point of interest into list above & expand tile for details
  ///   3: Complete trip descriptions

  void updateControllers(
      {BottomDrawerItems? items, bool open = false, bool dock = false}) {
    try {
      if (items != null) {
        if (kIsWeb) {
          MapService()
              .sideDrawerController!
              .setContent(content: BottomDrawerItems.trip);
        } else {
          _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        }
      }
      if (open) {
        if (kIsWeb) {
          MapService().sideDrawerController!.open(width: 0.4);
        } else {
          _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
          _bottomDrawerController.open();
        }
      }
      if (dock) {
        if (kIsWeb) {
          MapService().sideDrawerController!.scrollTo(index: 0);
        }
      }
    } catch (e) {
      developer.log('Error in updateControllers(): ${e.toString()}',
          name: 'error');
    }
  }

  Point chipPosition() {
    try {
      return Point(MapService().controller!.cameraPosition!.target.latitude,
          MapService().controller!.cameraPosition!.target.longitude);
    } catch (e) {
      return Point(0, 0);
    }
  }

  Align getDirections(int index) {
    if (CurrentTripItem().tripState == TripState.following &&
        CurrentTripItem().maneuvers.isNotEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: DirectionTile(
          controller: _directionTileController,
          onTap: (index, routeIndex, pointIndex) => changeRoute(
              lastManeuverIndex: index,
              routeIndex: routeIndex,
              pointIndex: pointIndex),
        ),
      );
    } else {
      return const Align(
        alignment: Alignment.topLeft,
      );
    }
  }

  Future<void> changeRoute(
      {int lastManeuverIndex = 0,
      int routeIndex = 0,
      int pointIndex = 0}) async {
    bool update = await CurrentTripItem().changeRoute(
        lastManeuverIndex: lastManeuverIndex,
        position: CurrentTripItem().tripValues.position,
        routeIndex: routeIndex,
        pointIndex: pointIndex);
    if (update) {
      _directionTileController.updateRoute();
    }
  }

  dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<bool> loadGroup({required String groupDriveId, int status = 2}) async {
    List<Follower> participants = [];
    Follower? myCarInfo;
    try {
      participants = await getDrivers(groupDriveId: groupDriveId, accepted: 2);
    } catch (e) {
      debugPrint('error getting drivers: ${e.toString()}');
    }
    int cIndex = 2;
    _following.clear;

    for (int i = 0; i < participants.length; i++) {
      Follower follower = participants[i];
      cIndex = cIndex < 16 ? ++cIndex : 2;
      if (Setup().user.email == follower.email) {
        myCarInfo = follower;
      }
      try {
        _following.add(
          Follower(
            uri: follower.uri,
            iconColour: cIndex,
            driveId: follower.driveId,
            forename: follower.forename,
            surname: follower.surname,
            phoneNumber: follower.phoneNumber,
            manufacturer: follower.manufacturer,
            model: follower.model,
            carColour: follower.carColour,
            registration: follower.registration,
            email: follower.email,
            position: follower.position,
          ),
        );
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
    if (myCarInfo == null) {
      cIndex = cIndex < 16 ? ++cIndex : 2;
      myCarInfo = Follower(
        forename: Setup().user.forename,
        surname: Setup().user.surname,
        email: Setup().user.email,
        phoneNumber: Setup().user.phone,
        driveName: ' ', // CurrentTripItem().heading,
        iconColour: cIndex,
        position: [_currentPosition.longitude, _currentPosition.latitude],
      );
      _following.add(myCarInfo);
    }
    await carInfo(myCarInfo);

    return true;
  }

  /// _setBottomDrawerDetails() determines what is shown in the bottom drawer
  /// enum TripActions {
  ///  none,            Returns an empty SizedBox
  ///  readOnly,        Returns everything, but in readonly for when driving
  ///  saving,          Used to make the screen-shot work
  ///  saved,
  ///  headingDetail,   Shows just the TripHeading tile in edit mode
  ///  pointOfInterest, Shows the PointOfInterest tile of the just added point of interest in edit mode
  ///  showGroup,       Shows all the group members of a group drive
  ///  showSteps,       Shows all the maneuvers in the current drive
  /// }

  /// closeDrawerCallback() called from trip_header_tile. As it's a simple 3 text-box
  /// entry tile the keyboard.action.done triggers the drawer to close if all 2 fields
  /// are completed

  void closeDrawerCallback(bool close) {
    if (close) {
      _bottomDrawerController.close();
      CurrentTripItem().drawerClosed();
    }
  }

  messageGroup(int index) async {
    return contactDiolog(context: context, socket: socket);
  }

  Future<String> showMessages({required TripMessage message}) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: const Text('Group Drive Message')),
          content: SizedBox(
            width: 150,
            height: 300,
            child: Align(
              alignment: Alignment.topLeft,
              child: TripMessageTile(
                index: -1,
                message: message,
                onEdit: (_) {},
                onSelect: (_) {},
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Dismiss', style: TextStyle(fontSize: 22)),
              onPressed: () {
                Navigator.pop(context, '');
              },
            ),
          ],
        );
      },
    );
    return '';
  }

  Future<String> carInfo(Follower driver) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Drive - ${driver.driveName}',
              style: textStyle(context: context, color: Colors.black, size: 2)),
          titlePadding: EdgeInsets.fromLTRB(30, 30, 0, 0),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            initialValue: driver.manufacturer,
                            style: textStyle(
                                context: context, color: Colors.black),
                            decoration: InputDecoration(
                                label: Text('Vehicle manufacturer'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Manufacturer',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.manufacturer = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: driver.model,
                            decoration: InputDecoration(
                                label: Text('Vehicle model'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Model',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.model = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.carColour,
                            decoration: InputDecoration(
                                label: Text('Colour'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Colour',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.carColour = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.registration,
                            decoration: InputDecoration(
                                label: Text('Registration'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Reg No',
                                hintStyle: hintStyle(context: context)),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.registration = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: textStyle(
                                context: context, color: Colors.black),
                            initialValue: driver.phoneNumber,
                            decoration: InputDecoration(
                                label: Text('Mobile'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Mobile phone number',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => driver.phoneNumber = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok', style: TextStyle(fontSize: 22)),
              onPressed: () async {
                _currentPosition = await Geolocator.getCurrentPosition();
                driver.position = [
                  _currentPosition.longitude,
                  _currentPosition.latitude
                ];
                await sendDriverDetails(driver);
                if (!socket.connected) {
                  socket.connect();
                }
                if (socket.connected) {
                  socket.emit('trip_join', {
                    'token': Setup().jwt,
                    'trip': ' ', // CurrentTripItem().groupDriveId,
                    'message': '',
                    'make': driver.manufacturer,
                    'model': driver.model,
                    'colour': driver.carColour,
                    'reg': driver.registration,
                    'phone': driver.phoneNumber,
                    'lat': _currentPosition.latitude,
                    'lng': _currentPosition.longitude,
                  });
                } else {
                  debugPrint('Socket not connected');
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(fontSize: 22)),
              onPressed: () {
                Navigator.pop(context, '');
              },
            ),
          ],
        );
      },
    );
    return '';
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage:
            ' ', // CurrentTripItem().heading, // _myTripItems[index].heading,
        okValue: index,
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      CurrentTripItem().clearAll();
    }
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    final picker = ImagePicker();

    await picker.pickImage(source: source, imageQuality: 10).then((pickedFile) {
      setState(
        () {
          if (pickedFile != null) {
            poi.images =
                "${poi.images},{'url': ${pickedFile.path}, 'caption':}";
          }
        },
      );
    });
  }

  /// _trackingState
  /// Sets tracking on if off
  /// Clears down the CurrentTripItem().routes

  /// Prostate PSA test Dr/Mr Halsburough 1.7 from 21

  /// Uses Geolocator.getPositionStream to get a stream of locations. Triggers posotion update
  /// every 10M
  /// must use _positionStream.cancel() to cancel stream when no longer reading from it

  void setLocationUpdates() async {
    try {
      if (CurrentTripItem().tripValues.pauseStream) {
        _positionStream!.pause();
        CurrentTripItem().tripValues.resumeStream = true;
        CurrentTripItem().tripValues.pauseStream = false;
      } else if (CurrentTripItem().tripValues.resumeStream) {
        _positionStream!.resume();
        CurrentTripItem().tripValues.resumeStream = false;
      } else {
        if (CurrentTripItem().tripValues.streamFinished) {
          _positionStream!.cancel();
        }
        if (_debugging) {
          if (_debuggingRoute.isEmpty) {
            _debugRoute.follow(routes: CurrentTripItem().routes);
            _positionStream = _debugPositionController.stream.listen(
              (Position position) {
                updatePosition(position);
              },
            );
          } else {
            MyTripItem debugMyTripItem =
                await loadSavedTrip(title: _debuggingRoute) ?? MyTripItem();
            if (debugMyTripItem.routes.isNotEmpty) {
              _debugRoute.follow(routes: debugMyTripItem.routes);
              _positionStream = _debugPositionController.stream
                  .listen((Position position) => updatePosition(position));
            }
          }
          if (CurrentTripItem().tripState == TripState.following) {
            _following.add(Follower(
                forename: 'One',
                surname: 'One',
                registration: 'CAR 001',
                position: [0, 0],
                track: true,
                carColour: 'red',
                iconColour: 1));
            _following.add(Follower(
              forename: 'Two',
              surname: 'Two',
              registration: 'CAR 002',
              position: [0, 0],
              track: true,
              carColour: 'blue',
              iconColour: 2,
            ));
            setState(() => CurrentTripItem().groupDriveId = 'gdDebug1');
          }

          // _positionStream.
        } else {
          const LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5, // 10 meters
          );
          try {
            _positionStream =
                Geolocator.getPositionStream(locationSettings: locationSettings)
                    .listen((position) {
              _currentPosition = position;
              if (CurrentTripItem().tripState == TripState.tracking) {
                updateUserPosition(CurrentPosition(position: position));
              }
            });
          } catch (e) {
            debugPrint('Error getting stream ${e.toString()}');
          }
        }
        CurrentTripItem().tripValues.streamStarted = true;
        CurrentTripItem().tripValues.streamFinished = false;
        CurrentTripItem().tripValues.lastPosition = Point(0, 0);
        CurrentTripItem().tripValues.startPosition = Point(0, 0);
        CurrentTripItem().tripValues.position = Point(0, 0);

        if (_positionStream != null) {
          _positionStream!
              .onDone(() => CurrentTripItem().tripValues.streamFinished = true);
        }
      }
    } catch (e) {
      developer.log('Error Stream error: ${e.toString()}', name: 'error');
    }
  }

  void updateUserPosition(CurrentPosition position) async {
    if (_userPosition.point.y > 0 &&
        position.point.y > 0 &&
        CurrentTripItem().tripState == TripState.tracking) {
      double travelled = getDistanceBetween(
          startXY: _userPosition.point, endXY: position.point);
      if (travelled > 1000) {
        CurrentTripItem().newWaypoint(point: position.point);
      }
    }

    /// Update the map without animation
    MapService()
        .controller!
        .moveCamera(CameraUpdate.newLatLng(position.latLng));
    setState(() => _userPosition = position);
  }

  void updatePosition(Position position) async {
    _currentPosition = position;
    _userPosition = CurrentPosition(position: position);
    CurrentTripItem().tripValues.position = _userPosition.point;
    LatLng pos = _userPosition.latLng;

    if (_debugging) {
      handleDebugStream(position, _debugRoute, _following);
    }

    if (CurrentTripItem().tripState == TripState.tracking &&
        CurrentTripItem().tripValues.lastPosition.y != 0) {
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          CurrentTripItem().tripValues.lastPosition.y.toDouble(),
          CurrentTripItem().tripValues.lastPosition.x.toDouble());
      if (distance > 5) {
        try {
          if (distance > 1000) {
            CurrentTripItem().routes.last.waypoints.add(Waypoint(
                value: CurrentTripItem().routes.last.waypoints.length + 1));
            if (CurrentTripItem().isGoodRoad) {
              CurrentTripItem().goodRoads.last.waypoints.add(Waypoint(
                  value:
                      CurrentTripItem().goodRoads.last.waypoints.length + 1));
            }
          }
          CurrentTripItem()
              .routes
              .last
              .lines
              .add([pos.longitude, pos.latitude]);

          await MapService().controller!.setGeoJsonSource('route-data', {
            "type": "FeatureCollection",
            "features": routesToGeoJson(),
          });

          if (CurrentTripItem().isGoodRoad) {
            CurrentTripItem()
                .goodRoads
                .last
                .lines
                .add([pos.longitude, pos.latitude]);
            await MapService().controller!.setGeoJsonSource('good-road-data', {
              "type": "FeatureCollection",
              "features": goodRoadsToGeoJson(),
            });
          }
        } catch (e) {
          developer.log('Error updatePosition() error: ${e.toString()}',
              name: 'error');
        }
        CurrentTripItem().tripValues.lastPosition =
            Point(pos.longitude, pos.latitude);
      }
    }

    CurrentTripItem().tripValues.heading = position.heading;
    CurrentTripItem().mapUpdates = MapUpdates.followers;

    MapService().controller!.animateCamera(CameraUpdate.newLatLng(pos));

    setState(() => getDirectionsIndex());
    if (Setup().rotateMap) {
      MapService()
          .controller!
          .animateCamera(CameraUpdate.bearingTo(position.heading));
    }
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (CurrentTripItem().tripState == TripState.following) {
      for (int i = _directionsIndex;
          i < CurrentTripItem().maneuvers.length;
          i++) {
        temp = Geolocator.distanceBetween(
            CurrentTripItem().tripValues.position.y.toDouble(),
            CurrentTripItem().tripValues.position.x.toDouble(),
            CurrentTripItem().maneuvers[i].point.y.toDouble(),
            CurrentTripItem().maneuvers[i].point.x.toDouble());
        if (temp < distance) {
          distance = temp;
          idx = i;
        }
      }
    }
    return idx;
  }

  void handleDebugStream(
      Position position, FollowRoute debugRoute, List<Follower> following) {
    LatLng pos = LatLng(position.latitude, position.longitude);
    CurrentTripItem().tripValues.heading = angleFromPoints(point1: [
      CurrentTripItem().tripValues.lastPosition.x.toDouble(),
      CurrentTripItem().tripValues.lastPosition.y.toDouble()
    ], point2: [
      pos.longitude,
      pos.latitude
    ]).toDouble();
    if (_following.isNotEmpty) {
      try {
        int index = _debugRoute.getIndex;
        int jump = 12;
        for (int i = 0; i < _following.length; i++) {
          if (index > jump * (i + 1)) {
            following[i] = following[i].moveFollower(
              newPosition: debugRoute.getPositionAt(index - (jump * (i + 1))),
            );
          } else {
            break;
          }
        }
      } catch (e) {
        debugPrint('Error setting followin ${e.toString()}');
      }
    }
    updateGroupOnMap(position);
  }

  void updateGroupOnMap(Position position) {
    if (CurrentTripItem().groupDriveId.isNotEmpty) {
      if (!socket.connected) {
        socket.connect();
        for (Follower follower in _following) {
          if (follower.email == Setup().user.email) {
            socket.emit('trip_join', {
              'token': Setup().jwt,
              'trip': CurrentTripItem().groupDriveId,
              'message': '',
              'make': follower.manufacturer,
              'model': follower.model,
              'colour': follower.carColour,
              'reg': follower.registration,
              'phone': follower.phoneNumber,
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }
        }
      }

      if (socket.connected) {
        socket.emit(
          'trip_message',
          {
            'message': '',
            'lat': position.latitude,
            'lng': position.longitude,
          },
        );
      }
    }
  }

  locationLatLng(pos) {
    setState(() {});
  }

  routeTapped(routes, details) {
    if (details != null) {
      setState(() {});
    }
  }

  expandChange(var details) {
    if (details != null) {
      setState(
        () {
          CurrentTripItem().tripValues.pointOfInterestIndex = details;
        },
      );
    }
  }

  iconButtonTapped(var details) {}

  removePointOfInterest(var details) {}

  routeMissed(var details) {
    if (details != null) {
      setState(() {
        debugPrint('Route missed');
      });
    }
  }

  /// getMapImage()
  /// Removes the ActionChips
  /// Takes map image
  /// Saves map image
  /// Sets the_CreateTripState to TripState.editing

  bool getTripDetails({bool prompt = false}) {
    if (CurrentTripItem().title.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            "Please enter what you'd like to call this trip.");
      }
      _bottomDrawerController.open(); // height of opened ExpandTile

      CurrentTripItem().tripActions = TripActions.headingDetail;
      fn1.requestFocus();
    }
    return false;
  }
}

/// Example of how to incorporate State into a function outside the main class
/// the important part is passing the BuildContext and setState to lower functions...

Future openDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Route waypoints'),
          content: const TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: submit(context, setState),
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );

submit(BuildContext context, setState) {
  Navigator.of(context).pop();
  setState(() {});
}

/// Keeps the map at its full height while the keyboard is showing.
/// The shell Scaffold shrinks the page as the keyboard slides up, so the
/// bottom drawer rides up with it - but the map would be resized on every
/// frame of the keyboard's animation, and a native map view can't keep up:
/// it judders and its image stretches. Instead the map keeps the height it
/// had without the keyboard, and the keyboard covers its lower part.
class KeyboardSteadyMap extends StatefulWidget {
  final Widget child;
  const KeyboardSteadyMap({super.key, required this.child});

  @override
  State<KeyboardSteadyMap> createState() => _KeyboardSteadyMapState();
}

class _KeyboardSteadyMapState extends State<KeyboardSteadyMap> {
  double _height = 0;
  double _width = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        // The Scaffold removes the keyboard from this MediaQuery, so ask the View
        bool keyboardShowing = View.of(context).viewInsets.bottom > 0;
        if (!keyboardShowing ||
            _height == 0 ||
            constraints.maxWidth != _width) {
          _height = constraints.maxHeight;
          _width = constraints.maxWidth;
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: _height,
            maxHeight: _height,
            child: widget.child,
          ),
        );
      }),
    );
  }
}
