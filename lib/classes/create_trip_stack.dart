import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart' hide Position;
import 'package:flutter/foundation.dart';
import '/screens/screens.dart';
import '/services/services.dart' hide getPosition;
import '/models/models.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;
import '/theme.dart';

class CreateTripStackController {
  _CreateTripStackState? _createTripStackState;
  void _addState(_CreateTripStackState createTripStackState) {
    _createTripStackState = createTripStackState;
  }

  bool get isAttached => _createTripStackState != null;

  void refresh() {
    if (isAttached) {
      _createTripStackState?.refresh();
    }
  }

  void changeRoute() {
    if (isAttached) {
      _createTripStackState?.changeRoute();
    }
  }

  /// Following: the turn-by-turn panel works out the next instruction and
  /// the distance to it from tripValues.position
  void updateDirections() => _createTripStackState?.updateDirections();

  void warn(int index) {
    if (isAttached) {
      _createTripStackState?.warn(index);
    }
  }
}

class CreateTripStack extends StatefulWidget {
  final CreateTripStackController? controller;
  const CreateTripStack({super.key, this.controller});
  @override
  State<CreateTripStack> createState() => _CreateTripStackState();
}

class _CreateTripStackState extends State<CreateTripStack>
    with TickerProviderStateMixin {
  late Future<bool> _dataLoaded;
  final DirectionTileController _directionTileController =
      DirectionTileController();

  StreamSubscription<Position>? _positionStream;
  int _directionsIndex = 0;

  int positionUpdates = 0;

  final MessageBox _messageBox =
      MessageBox(controller: MapService().messageBoxController);

  StreamSocket streamSocket = StreamSocket();

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    _dataLoaded = dataFromDatabase();
    if (CurrentTripItem().routes.isNotEmpty) {
      CurrentTripItem().mapUpdates = MapUpdates.updateAll;
    } else {
      CurrentTripItem().clearAll(newTripState: TripState.none);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void refresh() {
    setState(() => {});
  }

  void updateDirections() {
    if (_directionTileController.isAttached) {
      _directionTileController.updatePosition();
    }
  }

  void warn(int index) async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 15));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _dataLoaded,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          developer.log('CreateTrip().build() snapshot.hasError',
              name: 'error');
        } else if (snapshot.hasData) {
          try {
            Widget body = _getPortraitBody();
            return body;
          } catch (e) {
            developer.log('CreateTrip().build() error:${e.toString()}',
                name: 'error');
          }
        } else {
          return const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _getPortraitBody() {
    Future<bool>;
    developer.log(
        'TripState: ${TripState.editing} CurrentTripItem().tripValues.showTarget: ${CurrentTripItem().tripValues.showTarget} CurrentTripItem().tripValues.showProgress: ${CurrentTripItem().tripValues.showProgress}',
        name: 'error');
    return Stack(
      children: [
        //   if (MapService().controller != null)
        Positioned(
          left: 0,
          right: 0,
          top: 110,
          child: Align(
            // <-- Only do editing in "Explore" mode
            alignment: Alignment.topRight,
            child: FutureBuilder(
              future: MapService().mapFuture, // <-- From Completer
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Map not ready',
                      style: (TextStyle(fontSize: 22, color: Colors.red)),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ),

        if (NavigationService().page == 2) ...[
          Positioned(
            top: 0,
            // On the web, clear of the SideDrawer
            left:
                kIsWeb ? MapService().sideDrawerController?.getWidth() ?? 0 : 0,
            right: 0,
            child: _messageBox,
          ),
          Positioned(
            // On the web, clear of the SideDrawer - e.g. AI assist's - so the
            // trip can be edited with it open
            left:
                kIsWeb ? MapService().sideDrawerController?.getWidth() ?? 0 : 0,
            right: 0,
            bottom: 0,
            child: Align(
              // <-- Only do editing in "Explore" mode
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 35),
                child: Padding(
                  padding:
                      EdgeInsetsGeometry.fromLTRB(kIsWeb ? 30 : 0, 0, 0, 0),
                  child: CreateTripChips(
                    createTripController: MapService().createTripController,
                    onUpdate: (_) {},
                    compact: kIsWeb &&
                        (MapService().sideDrawerController?.getWidth() ?? 0) >
                            0,
                  ),
                ),
              ),
            ),
          ),
          if ((CurrentTripItem().tripState == TripState.editing ||
                  CurrentTripItem().tripValues.showTarget) &&
              !CurrentTripItem().tripValues.showProgress) ...[
            CustomPaint(
              painter: TargetPainter(
                  top: MapService()
                      .mapMiddle
                      .y
                      .toDouble(), //mapMiddle().y.toDouble(),
                  left: MapService()
                      .mapMiddle
                      .x
                      .toDouble(), //mapMiddle().x.toDouble(),
                  color: CurrentTripItem().isGoodRoad
                      // The user's great road colour, like the route
                      ? colourList[Setup().goodRouteColour]
                      : Colors.black),
            )
          ],
          // The position marker is a map layer - MapService().showLocation()
          // Speed while moving when tracking or following - PositionService
          // sets it, and the stack is rebuilt on each position
          if ([TripState.tracking, TripState.following]
                  .contains(CurrentTripItem().tripState) &&
              CurrentTripItem().tripValues.speed > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 0, 150),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.black,
                    child: Text(CurrentTripItem().tripValues.speed.toString(),
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
          if (NavigationService().page == 1) ...[
            CustomPaint(
              painter: HighlightPainter(
                boundary: MapService().mapSize(),
                proportion: 0.6,
                color: DrivesColours.current.neutral,
              ),
            ),
          ],
        ],

        /// getDirections shows the turn-by-turn navigation details
        getDirections(_directionsIndex),
        if (kIsWeb) ...[]
      ],
    );
  }

  Point chipPosition() {
    try {
      return Point(MapService().controller!.cameraPosition!.target.latitude,
          MapService().controller!.cameraPosition!.target.longitude);
    } catch (e) {
      return Point(0, 0);
    }
  }

  Future<bool> dataFromDatabase() async {
    // Setup is loaded from Hive at startup (main.dart initialise())
    return true;
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

      if (MapService().sideDrawerController!.content ==
              BottomDrawerItems.settings &&
          MapService().sideDrawerController!.changed) {
        Setup().save(); // <-- Writes the setup changes to api
      }
    }
    setState(() {});
  }

  void update(bool complete) {
    if (complete) {
      MapService().bottomDrawerController!.close();
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
}
