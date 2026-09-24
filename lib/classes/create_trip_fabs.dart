import 'dart:math';
import '../classes/classes.dart' hide Position;
import '../models/models.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
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

class FabsController {
  _HandleCTFabsState? _handleCTFabsState;

  void _addState(_HandleCTFabsState handleCTFabsState) {
    _handleCTFabsState = handleCTFabsState;
  }

  void refresh() {
    if (isAttached) {
      _handleCTFabsState?.refresh();
    }
  }

  void hide() {
    if (isAttached) {
      _handleCTFabsState?.hide();
    }
  }

  void show() {
    if (isAttached) {
      _handleCTFabsState?.show();
    }
  }

  bool get isAttached => _handleCTFabsState != null;
}

class HandleCTFabs extends StatefulWidget {
  double top;

  final Function(bool)? update;
  FabsController? controller;
  HandleCTFabs({
    super.key,
    this.controller,
    this.update,
    this.top = 20,
  });

  @override
  State<HandleCTFabs> createState() => _HandleCTFabsState();
}

class _HandleCTFabsState extends State<HandleCTFabs> {
  final double _width = 50;
  final double _height = 56.0;
  bool visible = true;
  @override
  void initState() {
    super.initState;

    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
  }

  void refresh() => setState(() {});

  void hide() => setState(() => visible = false);
  void show() => setState(() => visible = true);

  @override
  Widget build(BuildContext context) {
    FloatingTextEditController teController = FloatingTextEditController();
    bool osmIncludingChange = false;
    return Material(
      color: Colors.transparent,
      child: visible
          ? Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height),
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, widget.top, 10, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (CurrentTripItem().tripState == TripState.following)
                      const SizedBox(height: 120),
                    if (MapService().controller != null)
                      MouseRegion(
                        onEnter: (_) => updateToolTips(true, 0),
                        onExit: (_) => updateToolTips(false, 0),
                        //   child: PointerInterceptor(
                        child: PlaceFinder(
                          height: _height,
                          width: _width,
                          onSelect: (position) => MapService()
                              .controller!
                              .animateCamera(
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
                          {
                            'Show cafes and restaurants': Setup().osmRestaurants
                          },
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
                                        point: CurrentTripItem()
                                            .tripValues
                                            .position,
                                        description: description,
                                        sounds: audio,
                                      ),
                                    ),
                            fillColor: Colors.white,
                            inputBorder:
                                _width > _height ? OutlineInputBorder() : null,
                            hint: 'Description to edit later...',
                            suffix: IconButton(
                                onPressed: (() {}), icon: Icon(Icons.mic)),
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
                              onPressed: (() => (widget.update!(true))),
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
                    if (MapService().controller != null)
                      MouseRegion(
                        onEnter: (_) => updateToolTips(true, 5),
                        onExit: (_) => updateToolTips(false, 5),
                        child: ZoomFab(
                          controller: MapService().controller!,
                          zfController: MapService().zoomFabController!,
                          width: 55,
                          height: 125,
                        ),
                      ),
                    const SizedBox(height: 10),
                    /*  FloatingActionButton(
                      onPressed: () async {
                        final stopwatch = Stopwatch();
                        stopwatch.start();
                        developer.log(
                            'create_trip_helpers.dart getRouteData() sending router request',
                            name: '_actionChips_');
                        final url = Uri.parse(
                            "https://motatek.com/router/route/v1/driving/-0.6894133547274919,51.36682116360749;-0.7035700029440477,51.35365237699247;-0.7237135941973065,51.34558560781177;-0.7504677508560746,51.33880374938146?steps=true&annotations=true&geometries=geojson&overview=full");
                        var response = await http.get(
                          url,
                          headers: {
                            'Host': '://motatek.com',
                            'Connection':
                                'close', // Forces a clean, fresh socket like curl
                            'User-Agent':
                                'FlutterApp/1.0', // Prevents any potential engine throttling
                          },
                        ).timeout(const Duration(seconds: 20));
                        stopwatch.stop();
                        developer.log(
                            'createTripHelpers.dart getRouteData() response statusCode: ${response.statusCode} elapsed ${stopwatch.elapsedMilliseconds} ms',
                            name: '_actionChips_');
                      },
                      heroTag: 'mapCentre',
                      backgroundColor: Colors.blue,
                      shape: const CircleBorder(),
                      child: Icon(
                        Icons.temple_hindu_outlined,
                        color: CurrentTripItem().isTracking
                            ? CurrentTripItem().tripValues.autoCentre
                                ? Colors.white
                                : Colors.grey
                            : Colors.white,
                      ),
                    ), */
                  ],
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  fteUpdate({String description = '', String audio = ''}) {
    CurrentTripItem().pointsOfInterest.add(PointOfInterest(
        point: CurrentTripItem().tripValues.position,
        description: description,
        sounds: audio));
  }

  void updateToolTips(bool enter, int i) {
    if (MapService().statusBarController != null) {
      try {
        if (enter) {
          MapService().statusBarController!.update([fabHints[i]]);
        } else {
          MapService().statusBarController!.clear();
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
    MapService().controller!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  updateRouteType({String description = '', String sound = ''}) {
    if (CurrentTripItem().isGoodRoad) {
      CurrentTripItem().goodRoadEnd(description: description, sounds: sound);
    } else {
      CurrentTripItem().requestGreatRoad();
      if (widget.update != null) {
        widget.update!(true);
      }
    }
  }
}
