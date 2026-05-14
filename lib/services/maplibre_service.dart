// import 'dart:math';
import 'package:flutter/material.dart';
import 'web_helper.dart';
import '../constants.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// This implementation tries to minimise the work the device has to do when displaying the map.
/// The MapService object is really just responsible for retrieving the style.json. It's a singleton
/// so should only get built once. It two another purpose
/// 1 holding the MapLibre's GlobalKey.
/// 2 giving access to the controller
/// The neat trick in this structure is that the singleton holds the GlobalKey for the actual map
/// object. The fact that the key is persisted in the singleton means that Flutter won't reinitialise
/// the MapLibre object which is expensive as the MapLibre object is destroyed, though it will rebuild
/// the Widget which is very cheap as it only creates a blueprint of the MapLibre object which is kept alive.
/// As the singleton holds the style.json data already it's very efficient.

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  MapLibreMapController? controller;
  final GlobalKey mapKey = GlobalKey();

  Future<String>? _styleFuture;
  Future<String> get style => _styleFuture ??= _fetchStyle();

  LatLng? _currentPosition;
  LatLng get currentPosition =>
      _currentPosition ?? LatLng(51.433, -0.513); // <-- Staines
  Future<String> _fetchStyle() async {
    String style = await getStyle(url: urlTilerMapLibre);
    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);
    return style;
  }
}

/*
class PersistentMap extends StatelessWidget {
  final Function(LatLng, MapLibreMapController)? onUpdate;
  final Function(Point, LatLng)? onTap;
  final Function()? onIdle;
  const PersistentMap({super.key, this.onIdle, this.onTap, this.onUpdate});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: MapService().style,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return MapLibreMap(
          key: MapService().mapKey, // <-- Keeps the map alive
          styleString: snapshot.data!,

          /// snapshot.data!.toString(),
          initialCameraPosition:
              CameraPosition(target: MapService().currentPosition, zoom: 11),

          trackCameraPosition: true, // ensures that zoom is updated
          //     onCameraMove: (position) {
          //       widget.onUpdate!(position.target, mapController!);
          //     },
          onMapCreated: _onMapCreated,
          onMapClick: onTap,
          onCameraIdle: onIdle,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer())
          },
        );
      },
    );
  }

  void _onMapCreated(MapLibreMapController controller) async {
    MapService().controller = controller;
    Position position = await Geolocator.getCurrentPosition();
    LatLng currentPosition = LatLng(position.latitude, position.longitude);
    onUpdate!(currentPosition, controller);
  }
}
*/
