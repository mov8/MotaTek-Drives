import 'dart:math';
import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/routes/routes.dart';
import '/models/models.dart';
import 'dart:developer' as developer;

/// CreateTripChips controls the chips in CreateTrip
/// it controls the state of both the trip and the parent
/// defining the trip
/// The aim was to abstract away the code from CreateTrip to a new
/// class that updates CreateTrip and the CurrentTripItem it's manipulating
///

class CreateTripChips extends StatelessWidget {
  final Function(MyTripActions) onUpdate;
  final CurrentTripItem tripItem; // tripItem contains the trip state
  final CreateTripController createTripController;
  // final CreateTripCurrentTripItem().values CurrentTripItem().tripValues = CreateTripCurrentTripItem().values();
  final Point position;
  final LeadingWidgetController? leadingWidgetController;

  const CreateTripChips({
    super.key,
    required this.tripItem,
    required this.createTripController,
    required this.position,
    required this.onUpdate,
    this.leadingWidgetController,
  });

  @override
  Widget build(BuildContext context) {
    developer.log(
        'Building CreateChips object CurrentTripItem().tripState: ${CurrentTripItem().tripState}',
        name: '_keyboard_');
    return Wrap(spacing: 5, children: getChips());
  }

  List<ActionChip> getChips() {
    //   List<String> chipNames = [];
    // CreateTripCurrentTripItem().values CurrentTripItem().tripValues = CreateTripCurrentTripItem().values();
    List<ActionChip> chips = [];

    if (CurrentTripItem().tripState == TripState.startFollowing) {
      () => createTripController.updateValues(
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

    developer.log(' ', name: '_chips');
    developer.log(
        ' +++++++ State Tests create_trip_chips.dart  CurrentTripItem().waypointState: ${CurrentTripItem().waypointState} ++++++++',
        name: '_actionChips_');
    String failure = '';
    // developer.log('States: ${CurrentTripItem().tripState}');

    bool actionsOk(int i) {
      bool ok = chipDetails[i]['actions'].isEmpty ||
          chipDetails[i]['actions'].contains(CurrentTripItem().tripActions);
      failure = ok ? failure : '$failure, ACTIONS';
      return ok;
    }

    bool statesOk(int i) {
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
                  size: 20, color: chipDetails[i]['colour'] ?? Colors.white)));
        } else {
          //   Code below very useful - don't remove
          developer.log(
              '$i - [${chipDetails[i]['label']}] failed => ${actionsOk(i) ? '' : 'actions '}${statesOk(i) ? '' : 'states '}${highlightsOk(i) ? '' : 'highlights '}${waypointOk(i) ? '' : 'waypoints '}${loadedOk(i) ? '' : 'loaded '}${savedOk(i) ? '' : 'saved '}${groupOk(i) ? '' : 'group '}${goodRoadOk(i) ? '' : 'goodRoad'}',
              name: '_actionChips_');
        }
      }
      developer.log(' ', name: '_chips');
    } catch (e) {
      debugPrint('error: &{e.toString()}');
    }
    return chips;
  }

  void addAutomatically() {
    CurrentTripItem().requestAddAutomatically();
    leadingWidgetController?.changeWidget(1);
    CurrentTripItem().tripState = TripState.tracking;
    onUpdate(MyTripActions.startTracking);
  }

  void addManually() {
    leadingWidgetController?.changeWidget(1);
    CurrentTripItem().requestAddManually();
    onUpdate(MyTripActions.startManual);
  }

  void clear() {
    // CurrentTripItem().requestClear();
    CurrentTripItem().requestClear();
    leadingWidgetController?.changeWidget(0);
    onUpdate(MyTripActions.clearTrip);
  }

  void editing() {
    CurrentTripItem().requestEditing();
    leadingWidgetController?.changeWidget(1);
    onUpdate(MyTripActions.editTrip);
  }

  void extendStart() async {
    CurrentTripItem().requestExtendStart();
    onUpdate(MyTripActions.addWaypoint);
  }

  void waypoint() async {
    CurrentTripItem().requestWaypoint();
    if (CurrentTripItem().tripValues.addGoodRoadDetail) {
      onUpdate(MyTripActions.addGoodRoadDetails);
    } else {
      onUpdate(MyTripActions.addWaypoint);
    }
  }

  void revisitWaypoint() async {
    CurrentTripItem().requestRevisitWaypoint();
    onUpdate(MyTripActions.revisitWaypoint);
  }

  void extendEnd() async {
    CurrentTripItem().requestExtendEnd();
    onUpdate(MyTripActions.addWaypoint);
  }

  saveTrip() async {
    onUpdate(MyTripActions.saveTrip);
    return;
  }

  void removeWaypoint() async {
    CurrentTripItem().requestRemoveWaypoint();
    onUpdate(MyTripActions.deleteWaypoint);
  }

  void pauseTracking() {
    CurrentTripItem().requestPauseTracking();
    onUpdate(MyTripActions.none);
    // createTripController.updateValues(values: CurrentTripItem().tripValues);
  }

  void endTracking() {
    CurrentTripItem().requestEndTracking();
    onUpdate(MyTripActions.stopTracking);
  }

  void greatRoad() {
    CurrentTripItem().requestGreatRoad();
    onUpdate(MyTripActions.addGoodRoad);
  }

  void editGreatRoad() {
    CurrentTripItem().requestEditGreatRoad();
    onUpdate(MyTripActions.saveGoodRoad);
  }

  void greatRoadEnd() {
    CurrentTripItem().requestGreatRoadEnd();
    onUpdate(MyTripActions.addGoodRoadDetails);
    //  onUpdate(MyTripActions.addGoodRoad);
  }

  void reverseTrip() async {
    await CurrentTripItem().reverseRoute();
    onUpdate(MyTripActions.reverseTrip);
    return;
  }

  void pointOfInterest() {
    CurrentTripItem().requestPointOfInterest();
    onUpdate(MyTripActions.addPointOfInterest);
    return;
  }

  void steps() {
    onUpdate(MyTripActions.showSteps);
  }

  void group() {
    CurrentTripItem().requestGroup();
    onUpdate(MyTripActions.showGroup);
  }

  void messages() {
    CurrentTripItem().requestMessages();
    onUpdate(MyTripActions.message);
  }

  void tripData() {
    CurrentTripItem().tripActions = TripActions.none;
    CurrentTripItem().tripValues.setState = true;
    createTripController.updateValues(values: CurrentTripItem().tripValues);
  }

  void trackRoute() {
    CurrentTripItem().requestTrackRoute();
    onUpdate(MyTripActions.track);
    return;
  }

  void followRoute() {
    CurrentTripItem().requestFollowRoute();
    onUpdate(MyTripActions.follow);
    return;
  }

  void stopFollowing() {
    CurrentTripItem().requestStopFollowing;

    onUpdate(MyTripActions.stopFollowing);
  }
}
