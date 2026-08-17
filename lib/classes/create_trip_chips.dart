import 'dart:math';
import 'package:drives/main.dart';
import 'package:drives/screens/create_trip_stack.dart';
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
    return Wrap(spacing: 5, children: getChips());
  }

  final List<Follower> _following = [];
  late final FollowRoute _debugRoute;
  final CreateTripStackController _createTripStackController =
      CreateTripStackController();

  List<ActionChip> getChips() {
    //   List<String> chipNames = [];
    // CreateTripCurrentTripItem().values CurrentTripItem().tripValues = CreateTripCurrentTripItem().values();
    // tripItem = CurrentTripItem();
    List<ActionChip> chips = [];
    try {
      if (CurrentTripItem().tripState == TripState.startFollowing) {
        () => createTripController?.updateValues(
            values: CurrentTripItem().tripValues);
      }
      if (CurrentTripItem().tripState == TripState.none) {
        CurrentTripItem().tripActions = TripActions.none;
        CurrentTripItem().isSaved = false;
        CurrentTripItem().isTracking = false;
        CurrentTripItem().highliteActions = HighliteActions.none;
      }
      final List<Map> chipDetails = [
        {
          'label': 'Extend start',
          'method': extendStart, //extendStart,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'actions': [],
          'waypointState': WaypointState.extendStart,
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Waypoint',
          'method': waypoint,
          'icon': Icons.pin_drop,
          'actions': [],
          'states': [
            TripState.manual,
            TripState.manualStart,
            TripState.goodRoadStart,
          ],
          // 'waypointState': [WaypointState.none],
          'highlight': [HighliteActions.none, HighliteActions.greatRoadStarted],
          'waypointState': WaypointState.none,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'goodRoad': null,
          'group': false
        },
        {
          'label': 'Insert waypoint',
          'method': waypoint,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'actions': [],
          'waypointState': WaypointState.insert,
          'highlight': [HighliteActions.none, HighliteActions.greatRoadStarted],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Extend end',
          'method': extendEnd, // extendEnd,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'waypointState': WaypointState.extendEnd,
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Remove waypoint',
          'method': removeWaypoint,
          'icon': Icons.wrong_location,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'waypointState': WaypointState.remove,
          'highlight': [],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'group': false
        },
        {
          'label': 'Revisit waypoint',
          'method': revisitWaypoint,
          'icon': Icons.wrong_location,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'waypointState': WaypointState.revisit,
          'highlight': [],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null, //true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Reverse trip',
          'method': reverseTrip,
          'icon': Icons.autorenew_outlined,
          'states': [TripState.editing],
          'actions': [],
          'highlight': [HighliteActions.waypointHighlited],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Point of interest',
          'method': pointOfInterest,
          'icon': Icons.add_photo_alternate,
          'states': [
            TripState.manual,
            TripState.editing,
            //   TripState.tracking,
            //   TripState.pausedTracking,
            //   TripState.stoppedTracking
          ],
          'actions': [],
          'highlight': [HighliteActions.none, HighliteActions.routeHighlited],
          'loaded': null, //true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Create manually',
          'method': addManually,
          'icon': Icons.touch_app,
          'states': [TripState.none],
          'actions': [],
          'highlight': [],
          'loaded': false,
          'saved': null,
          'group': false
        },
        {
          'label': 'Edit route',
          'method': editing,
          'icon': Icons.edit,
          'states': [TripState.none, TripState.loaded, TripState.notFollowing],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Save route',
          'method': saveTrip,
          'icon': Icons.save,
          'states': [
            TripState.manual,
            TripState.stoppedTracking,
            TripState.editing
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': false,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Clear route',
          'method': clear,
          'icon': Icons.delete,
          'states': [
            TripState.editing,
            TripState.loaded,
            TripState.none,
            TripState.notFollowing,
            TripState.stoppedFollowing,
            TripState.stoppedTracking,
            TripState.manual,
            TripState.manualStart,
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Add great road',
          'method': greatRoad,
          'icon': Icons.add_road,
          'states': [
            // TripState.tracking,
            TripState.manual,
            TripState.editing,
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': null,
          'saved': null,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Edit great road',
          'method': editGreatRoad,
          'icon': Icons.edit,
          'states': [TripState.tracking, TripState.manual, TripState.editing],
          'actions': [],
          'highlight': [HighliteActions.greatRoadHighlighted],
          'loaded': null,
          'saved': null,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Plan drive',
          'method': greatRoadEnd,
          'icon': Icons.add_road,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': false,
          'group': false,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'goodRoad': true
        },
        {
          'label': 'Great road end',
          'method': greatRoadEnd,
          'icon': Icons.add_road,
          'states': [TripState.editing, TripState.manual],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': false,
          'group': false,
          'colour': colourList[Setup().routeColour],
          'goodRoad': true
        },
        {
          'label': 'Track drive',
          'method': addAutomatically,
          'icon': Icons.directions_car,
          'states': [TripState.none],
          'actions': [],
          'highlight': [],
          'loaded': false,
          'saved': null,
          'group': false
        },
        {
          'label': 'Continue tracking',
          'method': trackRoute,
          'icon': Icons.play_arrow,
          'states': [TripState.pausedTracking],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': null,
          'group': false
        },
        {
          'label': 'Pause tracking',
          'method': pauseTracking,
          'icon': Icons.pause,
          'states': [TripState.tracking],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'End tracking',
          'method': endTracking,
          'icon': Icons.stop,
          'states': [TripState.tracking, TripState.pausedTracking],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Follow drive',
          'method': followRoute,
          'icon': Icons.play_arrow,
          'states': [
            TripState.loaded,
            TripState.stoppedFollowing,
            TripState.notFollowing,
          ],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null
        },
        {
          'label': 'Stop following',
          'method': stopFollowing,
          'icon': Icons.stop,
          'states': [TripState.following],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null
        },
        {
          'label': 'Steps',
          'method': steps,
          'icon': Icons.timeline,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded,
            TripState.manual,
            TripState.editing
          ],
          'actions': [], // [TripActions.none],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null,
          'goodRoad': false,
        },
        {
          'label': 'Group',
          'method': group,
          'icon': Icons.directions_car,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded
          ],
          'actions': [], // [TripActions.none],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': true
        },
        /*
      {
        'label': 'Drive info',
        'method': tripData,
        'icon': Icons.map,
        'states': [],
        'actions': [
          TripActions.showGroup,
          TripActions.showMessages,
          TripActions.showSteps
        ],
        'highlight': [],
        'loaded': true,
        'saved': null,
        'group': false
      },
    */
        {
          'label': 'Messages',
          'method': messages,
          'icon': Icons.chat_outlined,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded
          ],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': true
        },
      ];

      String failure = '';
      bool actionsOk(int i) {
        bool ok = chipDetails[i]['actions'].isEmpty ||
            chipDetails[i]['actions'].contains(CurrentTripItem().tripActions);
        failure = ok ? failure : '$failure, ACTIONS';
        return ok;
      }

      bool statesOk(int i) {
        /// CurrentTripItem().tripState is an Enum
        bool ok = (chipDetails[i]['states'].isEmpty ||
            chipDetails[i]['states'].contains(CurrentTripItem().tripState));
        failure = ok ? failure : '$failure, STATES';
        return ok;
      }

      bool waypointOk2(int i) {
        return false;
      }

      bool waypointOk(int i) {
        return chipDetails[i]['waypointState'] == null ||
            chipDetails[i]['waypointState'] == CurrentTripItem().waypointState;
      }

      bool highlightsOk(int i) {
        bool ok = ((chipDetails[i]['highlight'].isEmpty ||
                chipDetails[i]['highlight']
                    .contains(CurrentTripItem().highliteActions)) &&
            chipDetails[i]['highlight'] != HighliteActions.none);
        failure = ok ? failure : '$failure, HIGHLIGHTS';
        return ok;
      }

      /// loaded is a tri-value flag true, false either (null)
      /// Have to include the null test twice as Dart evaluates both sides of the || and
      /// errors if the RHS does a non null save evaluation even though the LHS satisfies the test.
      bool loadedOk(int i) {
        bool ok = chipDetails[i]['loaded'] == null ||
            (chipDetails[i]['loaded'] != null && chipDetails[i]['loaded']
                ? CurrentTripItem().routes.isNotEmpty
                : CurrentTripItem().routes.isEmpty);
        return ok;
      }

      bool savedOk(int i) {
        bool ok = chipDetails[i]['saved'] == null ||
            CurrentTripItem().isSaved == chipDetails[i]['saved'];
        failure = ok ? failure : '$failure, SAVED';
        return ok;
      }

      bool groupOk(int i) {
        bool ok = chipDetails[i]['group'] == null ||
            (chipDetails[i]['group'] ==
                CurrentTripItem().groupDriveId.isNotEmpty);
        failure = ok ? failure : '$failure, GROUP';
        return ok;
      }

      bool goodRoadOk(int i) {
        bool ok = chipDetails[i]['goodRoad'] == null ||
            CurrentTripItem().isGoodRoad == chipDetails[i]['goodRoad'];
        failure = ok ? failure : '$failure, GOODROAD';
        return ok;
      }

      bool isValid(int i) {
        return actionsOk(i) &&
            statesOk(i) &&
            highlightsOk(i) &&
            waypointOk(i) &&
            loadedOk(i) &&
            savedOk(i) &&
            groupOk(i) &&
            goodRoadOk(i);
      }

      try {
        for (int i = 0; i < chipDetails.length; i++) {
          failure = '';

          Color colour = CurrentTripItem().isGoodRoad &&
                  ['Waypoint'].contains(chipDetails[i]['label'])
              ? colourList[Setup().goodRouteColour]
              : Colors.white;
          Color wpColour = CurrentTripItem().isGoodRoad &&
                  ['Waypoint', 'Plan drive', 'Add great road']
                      .contains(chipDetails[i]['label'])
              ? colourList[Setup().goodRouteColour]
              : Colors.white;

          if (isValid(i)) {
            try {
              chips.add(ActionChip(
                  visualDensity:
                      const VisualDensity(horizontal: 0.0, vertical: 0.5),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  label: Text(chipDetails[i]['label'],
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  elevation: 10,
                  shadowColor: Colors.black,
                  onPressed: () => chipDetails[i]['method'](),
                  avatar: Icon(chipDetails[i]['icon'],
                      size: 20,
                      color: chipDetails[i]['colour'] ?? Colors.white)));
            } catch (e) {
              developer.log(
                  'Error adding ActionChip in grtChips() : ${e.toString()}',
                  name: 'error');
            }
          } else {
            //  Code below very useful - don't remove
            /*
            developer.log(
                '$i - [${chipDetails[i]['label']}] failed => ${actionsOk(i) ? '' : 'actions '}${statesOk(i) ? '' : 'states '}${highlightsOk(i) ? '' : 'highlights '}${waypointOk(i) ? '' : 'waypoints '}${loadedOk(i) ? '' : 'loaded '}${savedOk(i) ? '' : 'saved '}${groupOk(i) ? '' : 'group '}${goodRoadOk(i) ? '' : 'goodRoad'}',
                name: '_actionChips_');
            */
          }
        }
      } catch (e) {
        developer.log(
            'CreateChips().getChips() error 1 - error: ${e.toString()}',
            name: 'error');
      }
    } catch (e) {
      developer.log('Error creating ActionChips: ${e.toString()}',
          name: 'error');
    }
    return chips;
  }

  void addAutomatically() {
    CurrentTripItem().requestAddAutomatically();
    MapService().leadingWidgetController.changeWidget(1);
    CurrentTripItem().tripState = TripState.tracking;
    _executeChipActions(tripActions: MyTripActions.beginTracking);
  }

  void addManually() {
    try {
      MapService().leadingWidgetController.changeWidget(1);
    } catch (e) {
      developer.log(
          'Error CreateTripChips().addManually() error: ${e.toString()}',
          name: 'error');
    }
    CurrentTripItem().requestAddManually();
    _executeChipActions(tripActions: MyTripActions.startManual);
  }

  void clear() {
    // CurrentTripItem().requestClear();
    CurrentTripItem().requestClear();
    MapService().leadingWidgetController.changeWidget(0);
    CurrentTripItem().tripState = TripState.none;
    CurrentTripItem().mapUpdates = MapUpdates.updateAll;
    _executeChipActions(tripActions: MyTripActions.clearTrip);
  }

  void editing() {
    CurrentTripItem().requestEditing();
    MapService().leadingWidgetController.changeWidget(1);
    _executeChipActions(tripActions: MyTripActions.editTrip);
  }

  void extendStart() async {
    CurrentTripItem().requestExtendStart();
    _executeChipActions(tripActions: MyTripActions.addWaypoint);
  }

  void waypoint() async {
    CurrentTripItem().requestWaypoint();
    if (CurrentTripItem().tripValues.addGoodRoadDetail) {
      _executeChipActions(tripActions: MyTripActions.addGoodRoadDetails);
    } else {
      _executeChipActions(tripActions: MyTripActions.addWaypoint);
    }
  }

  void revisitWaypoint() async {
    CurrentTripItem().requestRevisitWaypoint();
    _executeChipActions(tripActions: MyTripActions.revisitWaypoint);
  }

  void extendEnd() async {
    CurrentTripItem().requestExtendEnd();
    _executeChipActions(tripActions: MyTripActions.addWaypoint);
  }

  saveTrip() async {
    _executeChipActions(tripActions: MyTripActions.saveTrip);
    return;
  }

  void removeWaypoint() async {
    CurrentTripItem().requestRemoveWaypoint();
    _executeChipActions(tripActions: MyTripActions.deleteWaypoint);
  }

  void pauseTracking() {
    CurrentTripItem().requestPauseTracking();
    _executeChipActions(tripActions: MyTripActions.none);
    // createTripController.updateValues(values: CurrentTripItem().tripValues);
  }

  void endTracking() {
    CurrentTripItem().requestEndTracking();
    _executeChipActions(tripActions: MyTripActions.stopTracking);
  }

  void greatRoad() {
    CurrentTripItem().requestGreatRoad();
    _executeChipActions(tripActions: MyTripActions.addGoodRoad);
  }

  void editGreatRoad() {
    CurrentTripItem().requestEditGreatRoad();
    _executeChipActions(tripActions: MyTripActions.saveGoodRoad);
  }

  void greatRoadEnd() {
    CurrentTripItem().requestGreatRoadEnd();
    _executeChipActions(tripActions: MyTripActions.addGoodRoadDetails);
  }

  void reverseTrip() async {
    await CurrentTripItem().reverseRoute();
    _executeChipActions(tripActions: MyTripActions.reverseTrip);
    return;
  }

  void pointOfInterest() {
    CurrentTripItem().requestPointOfInterest();
    _executeChipActions(tripActions: MyTripActions.addPointOfInterest);
    // widget.onChange!(My);
    return;
  }

  void steps() {
    _executeChipActions(tripActions: MyTripActions.showSteps);
  }

  void group() {
    CurrentTripItem().requestGroup();
    _executeChipActions(tripActions: MyTripActions.showGroup);
  }

  void messages() {
    CurrentTripItem().requestMessages();
    _executeChipActions(tripActions: MyTripActions.message);
  }

  void tripData() {
    CurrentTripItem().tripActions = TripActions.none;
    CurrentTripItem().tripValues.setState = true;
    createTripController?.updateValues(values: CurrentTripItem().tripValues);
  }

  void trackRoute() {
    CurrentTripItem().requestTrackRoute();
    _executeChipActions(tripActions: MyTripActions.track);
    return;
  }

  void followRoute() {
    CurrentTripItem().requestFollowRoute();
    _executeChipActions(tripActions: MyTripActions.follow);
    return;
  }

  void stopFollowing() {
    CurrentTripItem().requestStopFollowing;
    _executeChipActions(tripActions: MyTripActions.stopFollowing);
  }

  void _executeChipActions(
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
        _createTripStackController.refresh();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.saveTrip:
        _saveTrip();
        _createTripStackController.refresh();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.clearTrip:
        _createTripStackController.refresh();
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.startManual:
        try {
          updateControllers(
              items: BottomDrawerItems.trip, open: true, dock: true);
          CurrentTripItem().tripValues.showTarget = true;
          CurrentTripItem().tripActions = TripActions.none;
          CurrentTripItem().tripState = TripState.manualStart;
          if (onUpdate != null) {
            onUpdate!(MyTripActions.none);
          }
        } catch (e) {
          developer.log('Error _executeTripActions() ${e.toString()}',
              name: 'error');
        }
        return;

      case MyTripActions.addPointOfInterest:
        updateControllers(
          items: BottomDrawerItems.trip,
          open: true,
          //  dock: true,
        );

        if (onUpdate != null) {
          onUpdate!(MyTripActions.none);
        }

        return;

      case MyTripActions.addGoodRoad:
        CurrentTripItem().isGoodRoad = true;
        onUpdate!(MyTripActions.none);
        return;

      /// May be able to combine this with .addPointOfInterest
      case MyTripActions.addGoodRoadDetails:
        updateControllers(
            items: BottomDrawerItems.goodRoad, open: true, dock: true);
        onUpdate!(MyTripActions.none);

        return;

      case MyTripActions.showSteps:
        updateControllers(
            items: BottomDrawerItems.maneuvers, open: true, dock: true);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.showMessages:
        MapService()
            .bottomDrawerController!
            .setContent(content: BottomDrawerItems.maneuvers);
        MapService().bottomDrawerController!.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.showGroup:
        MapService().bottomDrawerController!.setContent(
            content: BottomDrawerItems.group, drawerItems: _following);
        MapService().bottomDrawerController!.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
        return;

      case MyTripActions.follow:
        MapService()
            .bottomDrawerController!
            .setContent(content: BottomDrawerItems.maneuvers);
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
        MapService()
            .bottomDrawerController!
            .setContent(content: BottomDrawerItems.trip);
        //  _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        onUpdate!(MyTripActions.none);
    }
    return;
  }

  _saveTrip() async {
    if (CurrentTripItem().headerComplete() != 7) {
      _getTripDescriptions();
      return;
    }
    if (CurrentTripItem().uri.isEmpty) {
      CurrentTripItem().uri = getUuid();
    }
    await _createMapImage();
    CurrentTripItem().imageRepository ??= ImageRepository();
    await CurrentTripItem().savePrivate();
    CurrentTripItem().tripState = TripState.loaded;
    CurrentTripItem().tripValues.editing();
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
          if (CurrentTripItem().debuggingRoute.isEmpty) {
            _debugRoute.follow(routes: CurrentTripItem().routes);
            PositionService().InitialiseDebugging();
          } else {
            MyTripItem debugMyTripItem = await getPrivateRepository()
                    .loadMyTripItem(name: CurrentTripItem().debuggingRoute) ??
                MyTripItem();
            if (debugMyTripItem.routes.isNotEmpty) {
              _debugRoute.follow(routes: debugMyTripItem.routes);
              PositionService().InitialiseDebugging();
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

  void updateControllers(
      {BottomDrawerItems? items, bool open = false, bool dock = false}) {
    try {
      if (items != null) {
        if (kIsWeb) {
          MapService()
              .sideDrawerController!
              .setContent(content: BottomDrawerItems.trip);
        } else {
          MapService().bottomDrawerController!.setContent(content: items);
        }
      }
      if (open) {
        if (kIsWeb) {
          MapService().sideDrawerController!.open(width: 0.4);
        } else {
          MapService().bottomDrawerController!.open(height: 500);
        }
      }
      if (dock) {
        if (kIsWeb) {
          MapService().sideDrawerController!.scrollTo(index: 0);
        } else {
          MapService().bottomDrawerController!.dockOpenTile();
        }
      }
    } catch (e) {
      developer.log('Error in updateControllers(): ${e.toString()}',
          name: 'error');
    }
  }

  _getTripDescriptions() async {
    MapService()
        .bottomDrawerController!
        .setContent(content: BottomDrawerItems.trip);
    MapService().bottomDrawerController!.open(height: 500);
    await Future.delayed(Duration(milliseconds: 500));
    MapService().bottomDrawerController!.dockOpenTile();
    //   }
    CurrentTripItem().tripActions = TripActions.none;
  }

  Future<void> _createMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      try {
        CurrentTripItem().tripActions = TripActions.saving;
        CurrentTripItem().highliteActions = HighliteActions.none;
        CurrentTripItem().tripValues.showProgress = true;
        MapService().bottomDrawerController!.close();
        try {
          Uint8List mapBytes = await MapService().controller!.takeSnapshot();

          if (CurrentTripItem().mapImage == null) {
            CurrentTripItem().mapImage ??= ImageInMemory(
                name: 'map', imageBytes: mapBytes.buffer.asUint8List());
          } else {
            CurrentTripItem().mapImage!.imageBytes =
                mapBytes.buffer.asUint8List();
          }
        } catch (e) {
          developer.log(
              'Error CreateTrip().createMapImage() saving map screenshot: "{eo.toString()',
              name: 'error');
        }
      } catch (e) {
        developer.log(
            'Error creating CreateTripChips().createMapImage(): ${e.toString()}',
            name: 'error');
      }
    }
  }
}
