import 'dart:math';
import '../classes/classes.dart' hide Position;
import '../models/models.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// List<String> ['jj'];
const List<String> fabHints = [
  "Search for a place by it's name, and zoom the map to centre on it.",
  "Set the map's router preferences to navigate a route for you avoiding motorways for example and show reviewed features.",
  "Record a point of interest to your trip, adding a description and any photos to help you or other users later.",
  "Record the start and end of memorable stretches or road, for example where the scenery is beautiful.",
  "Centre the map on your current position.",
  "Zoom the map's size to show more detail for a smaller region, or less detail for a larger region."
];

class HandleCTFabs extends StatelessWidget {
  final double _width = 50;
  final double _height = 56.0;
  double top;
  final MapLibreMapController controller;
  final FloatingTextEditController? teController;
  final ZoomFabController? zfController;
  final StatusBarController? sbController;
  final Function(bool)? update;
  HandleCTFabs(
      {super.key,
      required this.controller,
      ZoomFabController? zfController,
      this.update,
      this.teController,
      this.sbController,
      this.top = 20})
      : zfController = zfController ?? MapService().zoomFabController;

  @override
  Widget build(BuildContext context) {
    bool osmIncludingChange = false;
    developer.log('HandleCTFabs().build() called', name: '_map_');
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height),
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(0, top, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (CurrentTripItem().tripState == TripState.following)
                const SizedBox(height: 120),
              MouseRegion(
                onEnter: (_) => updateToolTips(true, 0),
                onExit: (_) => updateToolTips(false, 0),
                //   child: PointerInterceptor(
                child: PlaceFinder(
                  height: _height,
                  width: _width,
                  onSelect: (position) => controller.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(position.latitude, position.longitude),
                    ),
                  ),
                ),
                //   ),
              ),
              const SizedBox(
                height: 10,
              ),
              MouseRegion(
                onEnter: (_) => updateToolTips(true, 1),
                onExit: (_) => updateToolTips(false, 1),
                //  child: PointerInterceptor(
                child: FloatingChecklist(
                  choices: [
                    {'Avoid motorways': Setup().avoidMotorways},
                    {'Avoid main roads': Setup().avoidAroads},
                    {'Avoid ferries': Setup().avoidFerries},
                    {'Avoid toll roads': Setup().avoidTollRoads},
                    {'Show pubs and bars': Setup().osmPubs},
                    {'Show cafes and restaurants': Setup().osmRestaurants},
                    {'Show fuel and charging stations': Setup().osmFuel},
                    {'Show toilets': Setup().osmToilets},
                    {'Show ATMs': Setup().osmAtms},
                    {'Show historic sites': Setup().osmHistorical}
                  ],
                  maxWidth: MediaQuery.of(context).size.width - 40,
                  onCheck: (index, value) {
                    switch (index) {
                      case 0:
                        Setup().avoidMotorways = value;
                        break;
                      case 1:
                        Setup().avoidAroads = value;
                        break;
                      case 2:
                        Setup().avoidFerries = value;
                        break;
                      case 3:
                        Setup().avoidTollRoads = value;
                        break;
                      case 4:
                        Setup().osmPubs = value;
                        break;
                      case 5:
                        Setup().osmRestaurants = value;
                        break;
                      case 6:
                        Setup().osmFuel = value;
                        break;
                      case 7:
                        Setup().osmToilets = value;
                        break;
                      case 8:
                        Setup().osmAtms = value;
                        break;
                      case 9:
                        Setup().osmHistorical = value;
                        break;
                    }
                    osmIncludingChange = true;
                  },
                  onClose: (_) async {
                    if (osmIncludingChange) {
                      osmIncludingChange = false;
                    }
                  },
                ),
                //   ),
              ),
              const SizedBox(height: 10),
              if ([TripState.tracking, TripState.following]
                  .contains(CurrentTripItem().tripState)) ...[
                MouseRegion(
                  onEnter: (_) => updateToolTips(true, 2),
                  onExit: (_) => updateToolTips(false, 2),
                  //   child: PointerInterceptor(
                  child: Material(
                    child: FloatingTextEdit(
                      key: Key('ftepoi'),
                      focusNode: FocusNode(),
                      keyboardType: TextInputType.name,
                      controller: teController,
                      closedIcon: Icons.add_location_alt_outlined,
                      openIcon: Icons.add_task_outlined,
                      onOpen: (_) => CurrentTripItem().saveState(),
                      onClose: (description, audio) =>
                          CurrentTripItem().pointsOfInterest.add(
                                PointOfInterest(
                                  point: CurrentTripItem().tripValues.position,
                                  description: description,
                                  sounds: audio,
                                ),
                              ),
                      fillColor: Colors.white,
                      inputBorder:
                          _width > _height ? OutlineInputBorder() : null,
                      hint: 'Description to edit later...',
                      suffix:
                          IconButton(onPressed: (() {}), icon: Icon(Icons.mic)),
                    ),
                  ),
                  //     ),
                ),
                if (CurrentTripItem().isGoodRoad) ...[
                  const SizedBox(height: 10),
                  MouseRegion(
                    onEnter: (_) => updateToolTips(true, 3),
                    onExit: (_) => updateToolTips(false, 3),
                    //   child: PointerInterceptor(
                    child: FloatingTextEdit(
                      key: Key('ftegr'),
                      maxWidth: 200,
                      focusNode: FocusNode(),
                      keyboardType: TextInputType.name,
                      controller: teController,
                      closedIcon: Icons.remove_road,
                      openIcon: Icons.add_task_outlined,
                      onOpen: (_) => CurrentTripItem().saveState(),
                      onClose: (description, audio) => updateRouteType(
                          description: description, sound: audio),
                      fillColor: Colors.white,
                      inputBorder:
                          _width > _height ? OutlineInputBorder() : null,
                      hint: 'Description to edit later...',
                      suffix: IconButton(
                        onPressed: (() => (update!(true))),
                        icon: Icon(
                          Icons.mic,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    //  ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
                if (!CurrentTripItem().isGoodRoad) ...[
                  const SizedBox(height: 10),
                  MouseRegion(
                    onEnter: (_) => updateToolTips(true, 3),
                    onExit: (_) => updateToolTips(false, 3),
                    child: FloatingActionButton(
                      onPressed: () => updateRouteType(),
                      heroTag: 'goodRoadOn',
                      backgroundColor: Colors.blue,
                      shape: const CircleBorder(),
                      child: Icon(
                        Icons.add_road,
                        color: CurrentTripItem().isTracking
                            ? CurrentTripItem().tripValues.autoCentre
                                ? Colors.white
                                : Colors.grey
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ],
              MouseRegion(
                onEnter: (_) => updateToolTips(true, 4),
                onExit: (_) => updateToolTips(false, 4),
                //    child: PointerInterceptor(
                child: FloatingActionButton(
                  onPressed: () => updatePosition(),
                  heroTag: 'mapCentre',
                  backgroundColor: Colors.blue,
                  shape: const CircleBorder(),
                  child: Icon(
                    Icons.my_location,
                    color: CurrentTripItem().isTracking
                        ? CurrentTripItem().tripValues.autoCentre
                            ? Colors.white
                            : Colors.grey
                        : Colors.white,
                  ),
                ),
                //       ),
              ),
              const SizedBox(height: 10),
              MouseRegion(
                onEnter: (_) => updateToolTips(true, 5),
                onExit: (_) => updateToolTips(false, 5),
                child: ZoomFab(
                  controller: controller,
                  zfController: zfController!,
                  width: 55,
                  height: 125,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  fteUpdate({String description = '', String audio = ''}) {
    CurrentTripItem().pointsOfInterest.add(PointOfInterest(
        point: CurrentTripItem().tripValues.position,
        description: description,
        sounds: audio));
  }

  void updateToolTips(bool enter, int i) {
    if (sbController != null) {
      try {
        if (enter) {
          sbController!.update([fabHints[i]]);
        } else {
          sbController!.clear();
        }
      } catch (e) {
        debugPrint('whoops: ${e.toString()}');
      }
    }
  }

  updatePosition() async {
    CurrentTripItem().tripValues.autoCentre =
        !CurrentTripItem().tripValues.autoCentre;
    Position position = await Geolocator.getCurrentPosition();
    Point point = Point(position.longitude, position.latitude);
    if (CurrentTripItem().tripValues.autoCentre) {
      if (CurrentTripItem().tripState != TripState.following) {
        CurrentTripItem().tripValues.position = point;
      }
    }
    controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  /// updateRouteType()
  /// if ! CurrentTripItem().isGoodRoad
  ///   sets the CurrentTripItem().isGoodRoad
  ///   Adds a Route to CurrentTripItem().goodRoads with waypoints[Waypoint(currentPosition)]
  /// else
  ///   updates the goodRoads.last.route.uuid
  ///   adds a waypoint(Waypoint(currentPosition)) to goodRoads.last.waypoints
  ///   adds a pointOfInterest(uuid, description, sound) to CurrentTripItems().pointsOfInterest
  ///
  updateRouteType({String description = '', String sound = ''}) {
    if (CurrentTripItem().isGoodRoad) {
      CurrentTripItem().goodRoadEnd(description: description, sounds: sound);
    } else {
      CurrentTripItem().requestGreatRoad();
      if (update != null) {
        update!(true);
      }
    }
  }
}
