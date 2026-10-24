import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '/constants.dart';
import '/routes/routes.dart';
import '/helpers/helpers.dart';
import '/models/models.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;
import 'dart:developer' as developer;

/// PlanPhase is derived from CurrentTripItem() by phaseOf() - it's never stored -
/// so the ActionChips can't get out of step with the trip. It's the only place
/// that tests combinations of TripState, waypoint count and isGoodRoad.
enum PlanPhase {
  idle,
  awaitingFirstWp,
  oneWp,
  routed,
  tracking,
  pausedTracking,
  stoppedTracking,
  loaded,
  following,
  stoppedFollowing,
}

int _waypointCount(CurrentTripItem trip) =>
    trip.routes.isEmpty ? 0 : trip.routes.first.waypoints.length;

/// waypointIndex is set by MapService().getWaypointState() on each onIdle.
/// Also true when the route already ends at that waypoint's point, e.g. it
/// has just been revisited - revisiting it again would add a zero length leg.
bool _overLastWaypoint(CurrentTripItem trip) {
  List<Waypoint> waypoints =
      trip.routes.isEmpty ? [] : trip.routes.first.waypoints;
  int index = trip.waypointIndex;
  if (index < 0 || index >= waypoints.length) return false;
  return index == waypoints.length - 1 ||
      waypoints.last.point == waypoints[index].point;
}

PlanPhase phaseOf(CurrentTripItem trip) {
  switch (trip.tripState) {
    case TripState.tracking:
      return PlanPhase.tracking;
    case TripState.pausedTracking:
      return PlanPhase.pausedTracking;
    case TripState.stoppedTracking:
      return PlanPhase.stoppedTracking;
    case TripState.following:
    case TripState.startFollowing:
      return PlanPhase.following;
    case TripState.stoppedFollowing:
      return PlanPhase.stoppedFollowing;
    case TripState.loaded:
    case TripState.notFollowing:
      return PlanPhase.loaded;
    case TripState.manual:
    case TripState.manualStart:
    case TripState.goodRoadStart:
    case TripState.editing:
      // Great road mode isn't a phase of its own - see resolveChip()
      return switch (_waypointCount(trip)) {
        0 => PlanPhase.awaitingFirstWp,
        1 => PlanPhase.oneWp,
        _ => PlanPhase.routed,
      };
    case TripState.none:
    case TripState.clearing:
      return _waypointCount(trip) == 0 ? PlanPhase.idle : PlanPhase.loaded;
  }
}

/// Every ActionChip that can appear. The method each one calls is defined
/// in CreateTripChips._handlerFor()
enum TripChip {
  createManually('Create manually', Icons.touch_app),
  trackDrive('Track drive', Icons.directions_car),
  waypoint('Waypoint', Icons.pin_drop),
  insertWaypoint('Insert waypoint', Icons.pin_drop),
  extendStart('Extend start', Icons.pin_drop),
  extendEnd('Extend end', Icons.pin_drop),
  removeWaypoint('Remove waypoint', Icons.wrong_location),
  revisitWaypoint('Revisit waypoint', Icons.wrong_location),
  pointOfInterest('Point of interest', Icons.add_photo_alternate),
  // Switches great road mode on - the waypoints added next are great road
  addGreatRoad('Great road mode', Icons.add_road),
  editGreatRoad('Edit great road', Icons.edit),
  greatRoadEnd('Normal road mode', Icons.add_road),
  reverseTrip('Reverse trip', Icons.autorenew_outlined),
  saveTrip('Save trip', Icons.save),
  clear('Clear route', Icons.delete),
  editRoute('Edit route', Icons.edit),
  pauseTracking('Pause tracking', Icons.pause),
  continueTracking('Continue tracking', Icons.play_arrow),
  endTracking('End tracking', Icons.stop),
  follow('Follow drive', Icons.play_arrow),
  stopFollowing('Stop following', Icons.stop),
  steps('Steps', Icons.timeline),
  group('Group', Icons.directions_car),
  messages('Messages', Icons.chat_outlined);

  const TripChip(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The chips offered in each PlanPhase, in display order.
/// resolveChip() then swaps or hides the few that depend on more than the phase.
const Map<PlanPhase, List<TripChip>> chipsForPhase = {
  PlanPhase.idle: [TripChip.createManually, TripChip.trackDrive],
  // greatRoadEnd only shows in great road mode - e.g. after undoing back to
  // fewer than 2 waypoints, so the user can still switch back
  PlanPhase.awaitingFirstWp: [
    TripChip.waypoint,
    TripChip.greatRoadEnd,
    TripChip.clear,
  ],
  PlanPhase.oneWp: [
    TripChip.waypoint,
    TripChip.greatRoadEnd,
    TripChip.pointOfInterest,
    TripChip.clear,
  ],
  PlanPhase.routed: [
    TripChip.waypoint,
    TripChip.pointOfInterest,
    TripChip.addGreatRoad,
    TripChip.reverseTrip,
    TripChip.steps,
    TripChip.saveTrip,
    TripChip.clear,
  ],
  PlanPhase.tracking: [TripChip.pauseTracking, TripChip.endTracking],
  PlanPhase.pausedTracking: [TripChip.continueTracking, TripChip.endTracking],
  PlanPhase.stoppedTracking: [
    TripChip.editRoute,
    TripChip.saveTrip,
    TripChip.clear,
  ],
  // A saved trip, e.g. loaded from My Trips. Group / Messages only show for a
  // group drive (resolveChip)
  PlanPhase.loaded: [
    TripChip.follow,
    TripChip.editRoute,
    TripChip.group,
    TripChip.messages,
  ],
  PlanPhase.following: [
    TripChip.stopFollowing,
    TripChip.steps,
    TripChip.group,
    TripChip.messages,
  ],
  PlanPhase.stoppedFollowing: [
    TripChip.follow,
    TripChip.steps,
    TripChip.group,
    TripChip.messages,
    TripChip.clear,
  ],
};

/// Resolves a listed chip to the chip(s) actually shown:
///   the waypoint chip follows what's under the crosshair (waypointState)
///   highlight, saved and group-drive conditions hide or swap a chip
List<TripChip> resolveChip(TripChip chip, CurrentTripItem trip) =>
    switch (chip) {
      // With 1 waypoint the crosshair is still over it - nothing to revisit
      TripChip.waypoint when trip.isGoodRoad || _waypointCount(trip) < 2 => [
          TripChip.waypoint
        ],
      // Create trip mode only adds waypoints at the end (removed with the
      // ActionBar undo). Revisiting the last waypoint makes no sense - it's
      // under the crosshair straight after it's added.
      TripChip.waypoint when trip.tripState != TripState.editing =>
        trip.waypointState == WaypointState.remove && !_overLastWaypoint(trip)
            ? [TripChip.revisitWaypoint]
            : [TripChip.waypoint],
      // Edit mode
      TripChip.waypoint => switch (trip.waypointState) {
          WaypointState.insert => [TripChip.insertWaypoint],
          WaypointState.extendStart => [TripChip.extendStart],
          WaypointState.extendEnd => [TripChip.extendEnd],
          WaypointState.remove => _overLastWaypoint(trip)
              ? [TripChip.removeWaypoint]
              : [TripChip.removeWaypoint, TripChip.revisitWaypoint],
          _ => [TripChip.waypoint],
        },
      // In great road mode the mode chip switches back - every other chip
      // stays as in normal road mode
      TripChip.addGreatRoad when trip.isGoodRoad => [TripChip.greatRoadEnd],
      TripChip.greatRoadEnd when !trip.isGoodRoad => [],
      TripChip.addGreatRoad
          when trip.highliteActions == HighliteActions.greatRoadHighlighted =>
        [TripChip.editGreatRoad],
      TripChip.pointOfInterest
          when trip.highliteActions == HighliteActions.waypointHighlited =>
        [],
      TripChip.reverseTrip
          when trip.highliteActions != HighliteActions.waypointHighlited =>
        [],
      TripChip.saveTrip when trip.isSaved => [],
      TripChip.group || TripChip.messages when trip.groupDriveId.isEmpty => [],
      _ => [chip],
    };

/// CreateTripChips controls the chips in CreateTrip
/// it controls the state of both the trip and the parent
/// defining the trip
/// The aim was to abstract away the code from CreateTrip to a new
/// class that updates CreateTrip and the CurrentTripItem it's manipulating
///

class CreateTripChips extends StatelessWidget {
  final Function(MyTripActions)? onUpdate;
  final CreateTripController? createTripController;
  final Point? position;

  CreateTripChips({
    super.key,
    this.createTripController,
    this.position,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Wrap(
        spacing: 5,
        children: getChips(),
      ),
    );
  }

  final List<Follower> _following = [];

  List<Widget> getChips() {
    final CurrentTripItem trip = CurrentTripItem();
    final PlanPhase phase = phaseOf(trip);
    final List<Widget> chips = [];
    try {
      for (final TripChip listed in chipsForPhase[phase] ?? const []) {
        for (final TripChip chip in resolveChip(listed, trip)) {
          chips.add(_actionChip(chip));
        }
      }
    } catch (e) {
      developer.log('Error creating ActionChips: ${e.toString()}',
          name: 'error');
    }
    //  Code below very useful - don't remove
    return chips;
  }

  Widget _actionChip(TripChip chip) {
    return ActionChip(
      visualDensity: const VisualDensity(horizontal: 0.0, vertical: 0.5),
      backgroundColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Text(_label(chip),
          style: TextStyle(fontSize: 16, color: Colors.white)),
      elevation: 10,
      shadowColor: Colors.black,
      onPressed: () => _handlerFor(chip)(),
      avatar: Icon(chip.icon, size: 20, color: _iconColour(chip)),
    );
  }

  /// In great road mode the Waypoint chip says the waypoint is great road
  String _label(TripChip chip) =>
      chip == TripChip.waypoint && CurrentTripItem().isGoodRoad
          ? 'Great road waypoint'
          : chip.label;

  Color _iconColour(TripChip chip) {
    bool goodRoad = CurrentTripItem().isGoodRoad;
    return switch (chip) {
      TripChip.waypoint ||
      TripChip.insertWaypoint ||
      TripChip.removeWaypoint ||
      TripChip.revisitWaypoint =>
        colourList[goodRoad ? Setup().goodRouteColour : Setup().routeColour],
      TripChip.addGreatRoad ||
      TripChip.editGreatRoad =>
        colourList[goodRoad ? Setup().routeColour : Setup().goodRouteColour],
      TripChip.greatRoadEnd => colourList[Setup().routeColour],
      _ => Colors.white,
    };
  }

  /// No default case - a new TripChip without a method won't compile
  Future<void> Function() _handlerFor(TripChip chip) => switch (chip) {
        TripChip.createManually => addManually,
        TripChip.trackDrive => addAutomatically,
        TripChip.waypoint || TripChip.insertWaypoint => waypoint,
        TripChip.extendStart => extendStart,
        TripChip.extendEnd => extendEnd,
        TripChip.removeWaypoint => removeWaypoint,
        TripChip.revisitWaypoint => revisitWaypoint,
        TripChip.pointOfInterest => pointOfInterest,
        TripChip.addGreatRoad => greatRoad,
        TripChip.editGreatRoad => editGreatRoad,
        TripChip.greatRoadEnd => greatRoadEnd,
        TripChip.reverseTrip => reverseTrip,
        TripChip.saveTrip => saveTrip,
        TripChip.clear => clear,
        TripChip.editRoute => editing,
        TripChip.pauseTracking => pauseTracking,
        TripChip.continueTracking => trackRoute,
        TripChip.endTracking => endTracking,
        TripChip.follow => followRoute,
        TripChip.stopFollowing => stopFollowing,
        TripChip.steps => steps,
        TripChip.group => group,
        TripChip.messages => messages,
      };

  /// Each handler awaits its CurrentTripItem().request...() so the chips are
  /// rebuilt after the trip has changed, not before.

  Future<void> addAutomatically() async {
    await CurrentTripItem().requestAddAutomatically();
    MapService().leadingWidgetController.changeWidget(1);
    CurrentTripItem().tripState = TripState.tracking;
    await _executeChipActions(tripActions: MyTripActions.beginTracking);
  }

  Future<void> addManually() async {
    try {
      MapService().leadingWidgetController.changeWidget(1);
    } catch (e) {
      developer.log(
          'Error CreateTripChips().addManually() error: ${e.toString()}',
          name: 'error');
    }
    await CurrentTripItem().requestAddManually();
    await _executeChipActions(tripActions: MyTripActions.startManual);
  }

  Future<void> clear() async {
    await CurrentTripItem().requestClear();
    CurrentTripItem().waypointState = WaypointState.none;
    MapService().leadingWidgetController.changeWidget(0);
    await _executeChipActions(tripActions: MyTripActions.clearTrip);
  }

  Future<void> editing() async {
    await CurrentTripItem().requestEditing();
    MapService().leadingWidgetController.changeWidget(1);
    await _executeChipActions(tripActions: MyTripActions.editTrip);
  }

  Future<void> extendStart() async {
    await CurrentTripItem().requestExtendStart();
    await _executeChipActions(tripActions: MyTripActions.addWaypoint);
  }

  Future<void> waypoint() async {
    await CurrentTripItem().requestWaypoint();
    if (CurrentTripItem().tripValues.addGoodRoadDetail) {
      await _executeChipActions(tripActions: MyTripActions.addGoodRoadDetails);
    } else {
      await _executeChipActions(tripActions: MyTripActions.addWaypoint);
    }
  }

  Future<void> revisitWaypoint() async {
    await CurrentTripItem().requestRevisitWaypoint();
    await _executeChipActions(tripActions: MyTripActions.revisitWaypoint);
  }

  Future<void> extendEnd() async {
    await CurrentTripItem().requestExtendEnd();
    await _executeChipActions(tripActions: MyTripActions.addWaypoint);
  }

  Future<void> saveTrip() async {
    await _executeChipActions(tripActions: MyTripActions.saveTrip);
  }

  Future<void> removeWaypoint() async {
    await CurrentTripItem().requestRemoveWaypoint();
    await _executeChipActions(tripActions: MyTripActions.deleteWaypoint);
  }

  Future<void> pauseTracking() async {
    CurrentTripItem().requestPauseTracking();
    await _executeChipActions(tripActions: MyTripActions.none);
  }

  Future<void> endTracking() async {
    await CurrentTripItem().requestEndTracking();
    await _executeChipActions(tripActions: MyTripActions.stopTracking);
  }

  Future<void> greatRoad() async {
    CurrentTripItem().requestGreatRoad();
    await _executeChipActions(tripActions: MyTripActions.addGoodRoad);
  }

  Future<void> editGreatRoad() async {
    CurrentTripItem().requestEditGreatRoad();
    await _executeChipActions(tripActions: MyTripActions.saveGoodRoad);
  }

  Future<void> greatRoadEnd() async {
    // Only a great road with waypoints gets a description to fill in
    bool described = CurrentTripItem().requestGreatRoadEnd();
    await _executeChipActions(
        tripActions:
            described ? MyTripActions.addGoodRoadDetails : MyTripActions.none);
  }

  Future<void> reverseTrip() async {
    await CurrentTripItem().reverseRoute();
    await _executeChipActions(tripActions: MyTripActions.reverseTrip);
  }

  Future<void> pointOfInterest() async {
    await CurrentTripItem().requestPointOfInterest();
    await _executeChipActions(tripActions: MyTripActions.addPointOfInterest);
  }

  Future<void> steps() async {
    await _executeChipActions(tripActions: MyTripActions.showSteps);
  }

  Future<void> group() async {
    CurrentTripItem().requestGroup();
    await _executeChipActions(tripActions: MyTripActions.showGroup);
  }

  Future<void> messages() async {
    CurrentTripItem().requestMessages();
    await _executeChipActions(tripActions: MyTripActions.message);
  }

  void tripData() {
    CurrentTripItem().tripActions = TripActions.none;
    CurrentTripItem().tripValues.setState = true;
    createTripController?.updateValues(values: CurrentTripItem().tripValues);
  }

  Future<void> trackRoute() async {
    await CurrentTripItem().requestTrackRoute();
    await _executeChipActions(tripActions: MyTripActions.track);
  }

  Future<void> followRoute() async {
    await CurrentTripItem().requestFollowRoute();
    await _executeChipActions(tripActions: MyTripActions.follow);
  }

  Future<void> stopFollowing() async {
    await CurrentTripItem().requestStopFollowing();
    await _executeChipActions(tripActions: MyTripActions.stopFollowing);
  }

  Future<void> _executeChipActions(
      {MyTripActions tripActions = MyTripActions.none}) async {
    switch (tripActions) {
      case MyTripActions.beginTracking:
        await MapService().controller!.animateCamera(CameraUpdate.zoomTo(14.2));
        CurrentTripItem().tripState = TripState.tracking;
        setLocationUpdates();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.none || MyTripActions.addWaypoint:
        onUpdate!(MyTripActions.none);

        return;

      case MyTripActions.editTrip:
        CurrentTripItem().tripState = TripState.editing;
        MapService().createTripStackController?.refresh();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.saveTrip:
        _saveTrip();
        MapService().createTripStackController?.refresh();
        onUpdate!(MyTripActions.none);
        MapService().myTripsController?.refresh();
        return;

      case MyTripActions.clearTrip:
        CurrentTripItem().clearAll();
        CurrentTripItem().tripValues.manual();
        CurrentTripItem().tripValues.showTarget = false;
        CurrentTripItem().tripState = TripState.none;
        CurrentTripItem().routes = [];
        MapService().createTripStackController?.refresh();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.startManual:
        try {
          // Ready for the trip's details, but closed until they're needed
          updateControllers(items: BottomDrawerItems.trip);
          CurrentTripItem().tripValues.manual();
          MapService().createTripStackController?.refresh();
          if (onUpdate != null) {
            onUpdate!(MyTripActions.none);
          }
        } catch (e) {
          developer.log('Error _executeTripActions() ${e.toString()}',
              name: 'error');
        }
        return;

      case MyTripActions.addPointOfInterest:
        // Open at the new point of interest, for its details
        updateControllers(
          items: BottomDrawerItems.trip,
          open: true,
          openPointOfInterest:
              CurrentTripItem().tripValues.pointOfInterestIndex,
        );

        if (onUpdate != null) {
          onUpdate!(MyTripActions.none);
        }

        return;

      case MyTripActions.addGoodRoad:
        CurrentTripItem().isGoodRoad = true;
        onUpdate!(MyTripActions.none);
        return;

      // A great road just ended - open at its description, which like a
      // point of interest needs a description and, ideally, photos
      case MyTripActions.addGoodRoadDetails:
        updateControllers(
          items: BottomDrawerItems.trip,
          open: true,
          openPointOfInterest:
              CurrentTripItem().tripValues.pointOfInterestIndex,
        );
        onUpdate!(MyTripActions.none);

        return;

      case MyTripActions.showSteps:
        updateControllers(items: BottomDrawerItems.maneuvers, open: true);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.showMessages:
        updateControllers(items: BottomDrawerItems.messages, open: true);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.showGroup:
        updateControllers(items: BottomDrawerItems.groups, open: true);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.follow:
        // The participants for a group drive; following alone, the drawer
        // would only cover the map
        updateControllers(
            items: BottomDrawerItems.group,
            open: CurrentTripItem().groupDriveId.isNotEmpty);
        CurrentTripItem().tripActions = TripActions.none;
        setLocationUpdates();
        onUpdate!(MyTripActions.none);

        return;

      case MyTripActions.stopFollowing:
        CurrentTripItem().tripValues.pauseStream = true;
        CurrentTripItem().tripState = TripState.stoppedFollowing;
        setLocationUpdates();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.track:
        setLocationUpdates();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.stopTracking:
        CurrentTripItem().tripValues.stopStream = true;
        CurrentTripItem().tripState = TripState.stoppedTracking;
        setLocationUpdates();
        onUpdate!(MyTripActions.none);
        return;

      default:
        // Keep the drawer's contents current, without opening it
        updateControllers(items: BottomDrawerItems.trip);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
    }
    return;
  }

  void _saveTrip() async {
    if (CurrentTripItem().headerComplete() != 7) {
      MapService()
          .messageBoxController
          ?.message(message: Warning.headingIncomplete);
      _getTripDescriptions();
      return;
    }
    await _createMapImage();
    debugPrint('[_save_] map image done, saving trip ${CurrentTripItem().uri}');
    try {
      CurrentTripItem().imageRepository ??= ImageRepository();
      // My Trips shows "Saved on" - it was never set, so it was blank
      if (CurrentTripItem().added.isEmpty) {
        CurrentTripItem().added = dateFormat.format(DateTime.now());
      }
      TripRepository tripRepository = TripRepository();
      await tripRepository.openBox();
      // Awaited so My Trips (refreshed below) reads the trip just saved
      await tripRepository.saveTrip(CurrentTripItem());
      CurrentTripItem().markSaved();
      CurrentTripItem().tripState = TripState.loaded;
      CurrentTripItem().tripValues.editing();
      MapService().messageBoxController?.message(message: Warning.tripSaved);
      MapService().myTripsController?.refresh();
      // The details are done - the BottomDrawer was closed for the map image
      if (kIsWeb) MapService().sideDrawerController?.close();
    } catch (e) {
      developer.log('_saveTro() Error saving trip: ${e.toString()}',
          name: 'error');
    }
  }

  void setLocationUpdates() async {
    try {
      if (CurrentTripItem().tripValues.pauseStream) {
        PositionService().pause();
        CurrentTripItem().tripValues.resumeStream = true;
        CurrentTripItem().tripValues.pauseStream = false;
      } else if (CurrentTripItem().tripValues.resumeStream) {
        PositionService().resume();
        CurrentTripItem().tripValues.resumeStream = false;
      } else {
        if (CurrentTripItem().tripValues.streamFinished) {
          PositionService().cancel();
        }
        if (CurrentTripItem().debugging) {
          // Replays a route as positions instead of reading the GPS:
          // debuggingRoute names a saved trip to replay - needed for tracking,
          // which starts with no route. Empty replays the current trip, e.g.
          // the one being followed.
          if (CurrentTripItem().debuggingRoute.isEmpty) {
            PositionService()
                .InitialiseDebugging(routes: CurrentTripItem().routes);
          } else {
            MyTripItem debugMyTripItem =
                await loadSavedTrip(title: CurrentTripItem().debuggingRoute) ??
                    MyTripItem();
            if (debugMyTripItem.routes.isNotEmpty) {
              PositionService()
                  .InitialiseDebugging(routes: debugMyTripItem.routes);
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
            CurrentTripItem().groupDriveId = 'gdDebug1';
          }

          // _positionStream.
        } else {
          try {
            PositionService().Initialise();
          } catch (e) {
            debugPrint('Error getting stream ${e.toString()}');
          }
        }
        CurrentTripItem().tripValues.streamStarted = true;
        CurrentTripItem().tripValues.streamFinished = false;
        CurrentTripItem().tripValues.lastPosition = Point(0, 0);
        CurrentTripItem().tripValues.startPosition = Point(0, 0);
        CurrentTripItem().tripValues.position = Point(0, 0);
      }
    } catch (e) {
      developer.log('Error Stream error: ${e.toString()}', name: 'error');
    }
  }

  /// Shows [items] in the drawer - the BottomDrawer on a phone, the
  /// SideDrawer on the web - and opens it if [open]. The trip's drawer only
  /// opens when there's something to fill in: a point of interest or great
  /// road description just added ([openPointOfInterest]), or the trip's
  /// details ([openHeader]); the drawer scrolls to it.
  void updateControllers(
      {BottomDrawerItems? items,
      bool open = false,
      int openPointOfInterest = -1,
      bool openHeader = false}) {
    try {
      if (items != null) {
        if (kIsWeb) {
          MapService().sideDrawerController!.setContent(
              content: items,
              openPointOfInterest: openPointOfInterest,
              openHeader: openHeader);
        } else {
          MapService().bottomDrawerController!.setContent(
              content: items,
              open: open,
              openPointOfInterest: openPointOfInterest,
              openHeader: openHeader);
        }
      }
      if (open) {
        if (kIsWeb) {
          MapService().sideDrawerController!.open(width: 0.4);
        } else {
          MapService().bottomDrawerController!.open();
        }
      }
    } catch (e) {
      developer.log('Error in updateControllers(): ${e.toString()}',
          name: 'error');
    }
  }

  /// A save needs the trip's details - open the drawer at them
  void _getTripDescriptions() {
    updateControllers(
        items: BottomDrawerItems.trip, open: true, openHeader: true);
    CurrentTripItem().tripActions = TripActions.none;
  }

  /// Captures the map showing the whole route and keeps it in Hive as the
  /// trip's first image (caption 'map'), which publish() sends as map.png.
  /// Recaptured on every save, replacing the last, so it matches the trip.
  Future<void> _createMapImage() async {
    MapLibreMapController? controller = MapService().controller;
    CurrentTripItem trip = CurrentTripItem();
    List<List<double>> points = [for (var route in trip.routes) ...route.lines];
    if (controller == null || points.length < 2) return;
    CameraPosition? before = controller.cameraPosition;
    try {
      trip.tripActions = TripActions.saving;
      trip.highliteActions = HighliteActions.none;
      trip.tripValues.showProgress = true; // <-- hides the crosshair
      MapService().bottomDrawerController?.close();
      MapService().createTripStackController?.refresh();
      // Fit the whole route, and wait for the map's onIdle - the camera has
      // stopped and the map has drawn, so the snapshot gets the finished map
      Future<void> idle = MapService().nextIdle();
      double west = points.map((p) => p[0]).reduce(min);
      double east = points.map((p) => p[0]).reduce(max);
      double south = points.map((p) => p[1]).reduce(min);
      double north = points.map((p) => p[1]).reduce(max);
      await controller
          .moveCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east)),
              left: 40,
              top: 40,
              right: 40,
              bottom: 40))
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      // No onIdle if the camera didn't need to move - don't wait for ever
      await idle.timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('[_snapshot_] no onIdle after fitting the route');
      });
      // Time limited - the map image is a nice-to-have and must never stop
      // the trip being saved
      Stopwatch timer = Stopwatch()..start();
      Uint8List bytes =
          await controller.takeSnapshot().timeout(const Duration(seconds: 5));
      // How the snapshot behaves on this device - it has worked, then not
      debugPrint('[_snapshot_] returned ${bytes.length} bytes in '
          '${timer.elapsedMilliseconds}ms');
      if (bytes.isNotEmpty) {
        String key = getUuid();
        await ImageRepository()
            .loadImage(key: key, uri: '$key.png', bytes: bytes);
        _setMapImage(trip, key);
        trip.mapImage = ImageInMemory(name: 'map', imageBytes: bytes);
      }
    } on TimeoutException {
      debugPrint('[_snapshot_] takeSnapshot() never returned (timed out after '
          '5s) - saving without a map image');
    } catch (e) {
      debugPrint('[_snapshot_] takeSnapshot() failed: ${e.toString()}');
    } finally {
      if (before != null) {
        await controller
            .moveCamera(CameraUpdate.newCameraPosition(before))
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
      }
      // Without this the crosshair stays hidden after the save
      trip.tripValues.showProgress = false;
      trip.tripActions = TripActions.none;
      MapService().createTripStackController?.refresh();
    }
  }

  /// Makes the map the trip's first image, deleting the previous map image
  /// from Hive
  void _setMapImage(CurrentTripItem trip, String key) {
    List<Photo> photos =
        trip.images.isEmpty ? [] : photosFromJson(photoString: trip.images);
    for (Photo old in photos.where((photo) => photo.caption == 'map')) {
      ImageRepository().deleteImage(
          old.key.isNotEmpty ? old.key : getFileName(url: old.url));
    }
    photos.removeWhere((photo) => photo.caption == 'map');
    photos.insert(
        0, Photo(url: '$key.png', key: key, caption: 'map', rotation: 0));
    trip.images = '[${photos.map((photo) => photo.toString()).join(', ')}]';
  }
}
