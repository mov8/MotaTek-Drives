/* 
Classes good Functions bad ! A project for the future
https://stackoverflow.com/questions/53234825/what-is-the-difference-between-functions-and-classes-to-create-reusable-widgets
import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:drives/constants.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/screens/screens.dart';
import 'package:drives/services/services.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:image_picker/image_picker.dart';


Widget _handleMap() {
  if (listHeight == -1) {
    adjustMapHeight(MapHeights.full);
  }
  return RepaintBoundary(
    key: mapKey,
    child: Stack(
      children: [
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            onMapEvent: checkMapEvent,
            onMapReady: () {
              mapController.mapEventStream.listen((event) {});
            },
            onPositionChanged: (position, hasGesure) {
              if (_tripState == TripState.manual) {
                _tripActions = TripActions.none;
                // _routeAtCenter.context =
                _routeAtCenter.routes = _currentTrip.routes();
                int routeIdx = _routeAtCenter.getPolyLineNearestCenter();
                //       if (routeIdx >= 0) {
                //         _currentTrip.setRouteColour(routeIdx, Colors.red);
                //         highlightedIndex = routeIdx;
                //         //  _currentTrip.routes()[routeIdx].colour = Colors.red;
                //      }

                // if (routeIdx > -1) {
                for (int i = 0; i < _currentTrip.routes().length; i++) {
                  //  _currentTrip.routes()[i].borderColor = _currentTrip.routes()[i].color;
                  if (i == routeIdx) {
                    _tripActions = TripActions.routeHighlited;
                    _currentTrip.setRouteColour(
                        i, uiColours.keys.toList()[Setup().selectedColour]);

                    //   _currentngTrip.routes()[i].colour = Colors.red;
                    //  uiColours.keys.toList()[Setup().selectedColour];
                    debugPrint(
                        'setti route()[i].colour => ${uiColours.values.toList()[Setup().selectedColour]}');
                  } else {
                    _currentTrip.setRouteColour(
                        i, uiColours.keys.toList()[Setup().routeColour]);
                  }
                }
                //       }

                highlightedIndex = routeIdx;
              } else {
                //      updateTracking();
              }
              if (hasGesure) {
                _updateMarkerSize(position.zoom ?? 13.0);
              }

              LatLng northEast = _animatedMapController
                  .mapController.camera.visibleBounds.northEast;
              LatLng southWest = _animatedMapController
                  .mapController.camera.visibleBounds.southWest;
              if (_updateOverlays) {
                if (_viewportFence.fenceUpdate(
                    screenFence:
                        Fence(northEast: northEast, southWest: southWest))) {
                  updateOverlays(_viewportFence.screenFence.northEast,
                      _viewportFence.screenFence.southWest);
                }
              }
              _mapRotation =
                  _animatedMapController.mapController.camera.rotation;
            },
            initialCenter: routePoints[0],
            initialZoom: 15,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove),
          ),
          children: [
            VectorTileLayer(
                theme: _style.theme,
                sprites: _style.sprites,
                //          tileProviders:
                //              TileProviders({'openmaptiles': _tileProvider()}),
                tileProviders: _style.providers,
                layerMode: VectorTileLayerMode.vector,
                tileOffset: TileOffset.DEFAULT),
            /*     TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 18,
                ), */
            CurrentLocationLayer(
              focalPoint: const FocalPoint(
                ratio: Point(0.0, 1.0),
                offset: Point(0.0, -60.0),
              ),
              alignPositionStream: _allignPositionStreamController.stream,
              alignDirectionStream: _allignDirectionStreamController.stream,
              alignPositionOnUpdate: _alignPositionOnUpdate,
              alignDirectionOnUpdate: _alignDirectionOnUpdate,
              style: const LocationMarkerStyle(
                marker: DefaultLocationMarker(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                  ),
                ),
                markerSize: ui.Size(30, 30),
                markerDirection: MarkerDirection.heading,
              ),
            ),
            mt.RouteLayer(
              polylineCulling: false, //true,
              polylines: _currentTrip.routes(),
              onTap: routeTapped,
              onMiss: routeMissed,
              routeAtCenter: _routeAtCenter,
            ),
            mt.RouteLayer(
              polylineCulling: false, //true,
              polylines: _currentTrip.goodRoads(),
              onTap: routeTapped,
              onMiss: routeMissed,
              routeAtCenter: _routeAtCenter,
            ),
            mt.RouteLayer(
              polylineCulling: false, //true,
              polylines: _goodRoads,
              onTap: routeTapped,
              onMiss: routeMissed,
              routeAtCenter: _routeAtCenter,
            ),
            MarkerLayer(markers: _currentTrip.pointsOfInterest()),
            MarkerLayer(markers: _pointsOfInterest),
            MarkerLayer(markers: _following),
          ],
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Wrap(
              spacing: 5,
              children: getChips(),
            ),
          ),
        ),
        if (_showTarget) ...[
          CustomPaint(
            painter: TargetPainter(
                top: mapHeight / 2,
                left: MediaQuery.of(context).size.width / 2,
                color: insertAfter == -1 ? Colors.black : Colors.red),
          )
        ],
        getDirections(_directionsIndex),
        if (_showMask) ...[
          _getOverlay2(),
        ]
      ],
    ),
  );
}
*/
