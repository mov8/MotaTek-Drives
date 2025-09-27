import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

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

class FollowRoute<T> {
  int _index = 0;
  int _delay = 1;
  bool run = false;
  StreamController<Position> controller;
  List<LatLng> _points = [];
  Position? position;

  FollowRoute({required this.controller});

  void follow({required List<LatLng> points, index = 0, delay = 1}) {
    run = true;
    _points = points;
    _index = index;
    _delay = delay;
    move();
  }

  Position? get getPosition => position;

  void move() async {
    if (run) {
      for (int i = _index; i < _points.length; i++) {
        await Future.delayed(Duration(seconds: _delay), () {
          position = Position(
              longitude: _points[i].longitude,
              latitude: _points[i].latitude,
              timestamp: DateTime.now(),
              accuracy: 1,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0);
          controller.add(position!);
          developer.log(
              'added to stream: $i lat: ${position!.latitude} lng: ${position!.longitude}',
              name: '_debug');
        });
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
