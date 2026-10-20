import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '/classes/route.dart' as mt;
import '/routes/routes.dart';
import '/helpers/helpers.dart';
import '/services/services.dart';
import '/classes/classes.dart' hide Position;
import '/models/other_models.dart' show Setup;
import '../constants.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class StreamSocket {
  final _socketResponse = StreamController<String>();
  void Function(String) get addResponse => _socketResponse.sink.add;
  Stream<String> get getResponse => _socketResponse.stream;
  void dispose() {
    _socketResponse.close();
  }
}

class DataStream<T> {
  StreamController<T> streamController;
  DataStream({required this.streamController});

  Sink<T> get _input => streamController.sink;
  Stream<T> get output => streamController.stream;

  T? _currentValue;

  T? get current => _currentValue;

  void update(T value) {
    _currentValue = value;
    _input.add(value);
  }

  void close() {
    streamController.close();
  }
}

class PositionService {
  static final PositionService _instance = PositionService._internal();
  factory PositionService() => _instance;
  PositionService._internal();
  Position? _currentPosition;
  CurrentPosition? _userPosition;
  double _speed = 0;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Position>? _debuggingStream;
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5, // 10 meters
  );
  void Initialise() {
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      _currentPosition = position;
      _speed = _currentPosition!.speed * 3.6 / 8 * 5; // M/S -> MPH
      if (_movingStates.contains(CurrentTripItem().tripState)) {
        updateUserPosition(CurrentPosition(position: position));
      }
      if (_positionStream != null) {
        _positionStream!
            .onDone(() => CurrentTripItem().tripValues.streamFinished = true);
      }
    });
  }

  void InitialiseDebugging() {
    _debuggingStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      _currentPosition = position;
      _speed = _currentPosition!.speed * 3.6 / 8 * 5; // M/S -> MPH
      if (_movingStates.contains(CurrentTripItem().tripState)) {
        updateUserPosition(CurrentPosition(position: position));
      }
    });
  }

  void pause() {
    if (_positionStream != null) {
      _positionStream!.pause();
    }
  }

  void resume() {
    if (_positionStream != null) {
      _positionStream!.resume();
    }
  }

  void cancel() {
    if (_positionStream != null) {
      _positionStream!.cancel();
    }
  }

  void pauseDebugging() {
    if (_positionStream != null) {
      _debuggingStream!.pause();
    }
  }

  void resumeDebugging() {
    if (_positionStream != null) {
      _debuggingStream!.resume();
    }
  }

  void cancelDebugging() {
    if (_positionStream != null) {
      _debuggingStream!.cancel();
    }
  }

  /// The states where the map follows the user's position
  static const List<TripState> _movingStates = [
    TripState.tracking,
    TripState.following,
  ];

  /// Direction of travel - kept from the last fix while moving, as GPS
  /// heading is meaningless when stationary
  double _heading = 0;

  /// Called for each position while tracking or following (every 5m -
  /// distanceFilter). Moves the position marker and the camera; when
  /// tracking it also extends the tracked route.
  void updateUserPosition(CurrentPosition position) async {
    TripState tripState = CurrentTripItem().tripState;
    if (position.point.y == 0 || !_movingStates.contains(tripState)) {
      return;
    }
    CurrentTripItem trip = CurrentTripItem();
    _speed = position.speed.toDouble();
    if (position.speed > 0 && position.heading >= 0) {
      _heading = position.heading;
    }
    trip.tripValues.position = position.point;
    trip.tripValues.heading = _heading;

    if (tripState == TripState.tracking) {
      await _extendTrackedRoute(position);
    } else {
      // Following - the directions work from tripValues.position
      MapService().createTripStackController?.refresh();
    }
    await MapService()
        .showLocation(position: position.point, bearing: _heading);
    _followCamera(position);
    _userPosition = position;
  }

  /// Setup().rotateMap chooses the orientation:
  ///   false - "always points north": bearing 0, the marker turns
  ///   true  - "marker points up": the map turns to the direction of travel
  /// Moved without animation - fixes arrive every few hundred milliseconds.
  void _followCamera(CurrentPosition position) {
    MapLibreMapController? controller = MapService().controller;
    if (controller == null) return;
    controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: position.latLng,
      zoom: controller.cameraPosition?.zoom ?? 14,
      tilt: controller.cameraPosition?.tilt ?? 0,
      bearing: Setup().rotateMap ? _heading : 0,
    )));
  }

  /// The tracked route is extended and redrawn straight away. It used to wait
  /// for the map's onIdle, which rarely fires while the camera follows the
  /// user, so the line lagged behind the position marker.
  Future<void> _extendTrackedRoute(CurrentPosition position) async {
    CurrentTripItem trip = CurrentTripItem();
    if (trip.routes.isEmpty) {
      trip.routes = [mt.Route()];
    }
    MapUpdates changes = MapUpdates.routes;

    // A waypoint where tracking starts and then every kilometre - measured
    // from the last waypoint, not the last position which is only 5m back
    List<Waypoint> waypoints = trip.routes.last.waypoints;
    if (waypoints.isEmpty ||
        getDistanceBetween(
                startXY: waypoints.last.point, endXY: position.point) >
            1000) {
      trip.newWaypoint(point: position.point);
      changes = changes.add(MapUpdates.waypoints);
    }

    trip.routes.last.lines.add(position.list);
    if (trip.isGoodRoad && trip.goodRoads.isNotEmpty) {
      trip.goodRoads.last.lines.add(position.list);
      changes = changes.add(MapUpdates.goodRoads);
    }
    await MapService().updateMapGeoJson(mapUpdates: changes);
  }
}

// final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

// NavigatorState get _navigator => key.currentState!;
/*
  Future<dynamic> navigateTo(String routeName, Object? arguments) async {
    try {
      if (key.currentState == null) {
        developer.log('Navigator.key.currentState is null', name: 'error');
        return;
      } else if (!['trips', 'createTrip'].contains(routeName) || kIsWeb) {
        key.currentState!.pushNamed(routeName, arguments: arguments);
      }
    } catch (e) {
      developer.log(
          'NavigationService().navigateTo($routeName) from: ${MapService().page}  error: ${e.toString()} ',
          name: 'error');
    }
    return; // key.currentState!.pushNamed(routeName, arguments: arguments);
 
 
  }

  int page = 0;

  void goBack() {
    return key.currentState!.pop();
  }
  */

class FollowRoute<T> {
  int _currentIndex = 0;
  int _index = 0;
  int _route = 0;
  int _delay = 1;
  bool run = false;
  StreamController<Position> controller;
  List<mt.Route> _routes = [];
  Position? position;

  FollowRoute({required this.controller});

  void follow({required List<mt.Route> routes, index = 0, delay = 1}) {
    run = true;
    _routes = routes; //routes;
    _index = index;
    _delay = delay;
    move();
  }

  Position? get getPosition => position;

  int get getIndex => _currentIndex;
  List<double> getPositionAt(int index) => _routes[_route].lines[index];

  void move() async {
    if (run) {
      for (int r = 0; r < _routes.length; r++) {
        mt.Route route = _routes[r];
        _route = r;
        for (int i = _index; i < route.lines.length; i++) {
          _currentIndex = i;
          await Future.delayed(Duration(seconds: _delay), () {
            position = Position(
                longitude: route.lines[i][0],
                latitude: route.lines[i][1],
                timestamp: DateTime.now(),
                accuracy: 1,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0);
            controller.add(position!);
          });
        }
      }
    }
  }

  void close() {
    controller.close();
  }
}

// class gpsDataProvider {}

/*
  StreamSubscription<List<int>> listenToStream() {
    return BluetoothServer().characteristicDataProvider.stream.listen(
        (data) => setState(() {
              /// This shouldn't be async else it causes refreshing problems
              /// Getting version from monitor can only happen once the charateristics are instantiated
              /// properly. This ensures the versions are read even if an error is encountered.
              if (data.length == 12) {
                for (int i = 0; i < 6; i++) {
                  if (i < data.length / 2) {
                    // List<double> dem_data = [70, 97, 50, 1, 1, 0, 86];
                    // BLE from ESP32 can only send 8 bit numbers so sending 6 * 2
                    portsList[i].value =
                        (data[i * 2] << 8 | data[i * 2 + 1]).toDouble();
                    gaugesList[i].showNotification();
                    gaugesList[i].setAlarm();
                    if (gaugeTypes.contains(gaugesList[i].type)) {
                      /// This stopped some bizarre behaviour
                      gaugesList[i].draw(context);
                    }
                  } else {
                    portsList[i].value = -1;
                  }
                }
              }
            }), onError: (e) {
      debugPrint('Error ${e.toString()}');
    }, onDone: () {
      debugPrint('All done');
    });
  }



  Future<void> connect() async {
    //  NotificationServer().showNotification(message: 'Bluetooth connected', description: 'Sentinel - Bluetooth status');
    // BluetoothServer().connected = true;
    // Setup().status = 'BluetoothServer().characteristicDataProvider.isListening ${BluetoothServer().characteristicDataProvider.isListening.toString()}';
    while (!BluetoothServer().characteristicDataProvider.isListening) {
      try {
        characteristicSubscription = listenToStream();
        //    Setup().status = 'characteristicDataProvider.isListening ${BluetoothServer().characteristicDataProvider.isListening.toString()}';
      } catch (e) {
        debugPrint('Connection failed: ${e.toString()}');
        //    Setup().status = 'Connection failed: ${e.toString()}';
      }
    }
    if (BluetoothServer().characteristicDataProvider.isListening) {}
  }


*/
