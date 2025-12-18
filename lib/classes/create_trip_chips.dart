import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/routes/routes.dart';
import 'package:latlong2/latlong.dart';
import '/models/models.dart';
//import 'dart:developer' as developer;

/// CreateTripChips controls the chips in CreateTrip
/// it controls the state of both the trip and the parent
/// defining the trip
/// The aim was to abstract away the code from CreateTrip to a new
/// class that updates CreateTrip and the CurrentTripItem it's manipulating

class CreateTripChips extends StatelessWidget {
  final Function() onUpdate;
  final CurrentTripItem tripItem; // tripItem contains the trip state
  final CreateTripController createTripController;
  // final CreateTriptripItem.values tripItem.tripValues = CreateTriptripItem.values();
  final LatLng position;
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
    return Wrap(spacing: 5, children: getChips());
  }

  List<ActionChip> getChips() {
    //   List<String> chipNames = [];
    // CreateTriptripItem.values tripItem.tripValues = CreateTriptripItem.values();
    List<ActionChip> chips = [];

    if (tripItem.tripState == TripState.startFollowing) {
      () => createTripController.updateValues(values: tripItem.tripValues);
    }

    final List<Map> chipDetails = [
      {
        'label': 'Extend start',
        'method': extendStart, //extendStart,
        'icon': Icons.pin_drop,
        'states': [TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': true,
        'saved': null,
        'group': false,
      },
      {
        'label': 'Waypoint',
        'method': waypoint,
        'icon': Icons.pin_drop,
        'states': [TripState.manual],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': null,
        'saved': null,
        'group': false
      },
      {
        'label': 'Insert waypoint',
        'method': waypoint,
        'icon': Icons.pin_drop,
        'states': [TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': null,
        'saved': null,
        'group': false
      },
      {
        'label': 'Extend end',
        'method': extendEnd, // extendEnd,
        'icon': Icons.pin_drop,
        'states': [TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': true,
        'saved': null,
        'group': false
      },
      {
        'label': 'Remove waypoint',
        'method': removeWaypoint,
        'icon': Icons.wrong_location,
        'states': [TripState.manual, TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.waypointHighlited],
        'loaded': true,
        'saved': null,
        'group': false
      },
      {
        'label': 'Revisit waypoint',
        'method': revisitWaypoint,
        'icon': Icons.wrong_location,
        'states': [TripState.manual, TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.waypointHighlited],
        'loaded': true,
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
      },
      {
        'label': 'Point of interest',
        'method': pointOfInterest,
        'icon': Icons.add_photo_alternate,
        'states': [TripState.manual, TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.none, HighliteActions.routeHighlited],
        'loaded': true,
        'saved': null,
        'group': false
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
          TripState.stoppedRecording,
          TripState.editing
        ],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': true,
        'saved': false,
        'group': false
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
          TripState.stoppedRecording,
          TripState.manual,
        ],
        'actions': [],
        'highlight': [HighliteActions.none],
        'loaded': true,
        'saved': null,
        'group': false
      },
      {
        'label': 'Great road start',
        'method': greatRoad,
        'icon': Icons.add_road,
        'states': [TripState.editing],
        'actions': [],
        'highlight': [HighliteActions.routeHighlited],
        'loaded': null,
        'saved': null,
        'group': false,
        'goodRoad': false,
      },
      {
        'label': 'Great road end',
        'method': greatRoadEnd,
        'icon': Icons.remove_road,
        'states': [TripState.editing],
        'actions': [],
        'highlight': [],
        'loaded': true,
        'saved': false,
        'group': false,
        'goodRoad': true
      },
      {
        'label': 'Start tracking',
        'method': trackRoute,
        'icon': Icons.play_arrow,
        'states': [
          TripState.automatic,
          TripState.stoppedRecording,
          TripState.paused
        ],
        'actions': [],
        'highlight': [],
        'loaded': null,
        'saved': null,
        'group': false
      },
      {
        'label': 'Pause tracking',
        'method': pauseRecording,
        'icon': Icons.pause,
        'states': [TripState.recording],
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
        'states': [TripState.recording, TripState.paused],
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
        'actions': [TripActions.none],
        'highlight': [],
        'loaded': true,
        'saved': null,
        'group': null
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
        'actions': [TripActions.none],
        'highlight': [],
        'loaded': true,
        'saved': null,
        'group': true
      },
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

    for (int i = 0; i < chipDetails.length; i++) {
      bool actionsOk(int i) {
        return chipDetails[i]['actions'].isEmpty ||
            chipDetails[i]['actions'].contains(tripItem.tripActions);
      }

      bool statesOk(int i) {
        return (chipDetails[i]['states'].isEmpty ||
            chipDetails[i]['states'].contains(tripItem.tripState));
      }

      bool highlightsOk(int i) {
        return ((chipDetails[i]['highlight'].isEmpty ||
                chipDetails[i]['highlight']
                    .contains(tripItem.highliteActions)) &&
            chipDetails[i]['highlight'] != HighliteActions.none);
      }

      bool loadedOk(int i) {
        return chipDetails[i]['loaded'] == null ||
            (chipDetails[i]['loaded'] && tripItem.routes.isNotEmpty) ||
            (!chipDetails[i]['loaded'] && tripItem.routes.isEmpty);
      }

      bool savedOk(int i) {
        return chipDetails[i]['saved'] == null ||
            tripItem.isSaved == chipDetails[i]['saved'];
      }

      bool groupOk(int i) {
        return chipDetails[i]['group'] == null ||
            (chipDetails[i]['group'] == tripItem.groupDriveId.isNotEmpty);
      }

      bool goodRoadOk(int i) {
        return chipDetails[i]['goodRoad'] == null ||
            tripItem.tripValues.goodRoad.isGood == chipDetails[i]['goodRoad'];
      }

      bool isValid(int i) {
        return actionsOk(i) &&
            statesOk(i) &&
            highlightsOk(i) &&
            loadedOk(i) &&
            savedOk(i) &&
            groupOk(i) &&
            goodRoadOk(i);
      }

      //   developer.log(
      //       '${chipDetails[i]['label']} actions: ${actionsOk(i)} states: ${statesOk(i)} highlights: ${highlightsOk(i)} loaded: ${loadedOk(i)} saved: ${savedOk(i)} group: ${groupOk(i)} goodRoad: ${goodRoadOk(i)}}',
      //       name: '_chips');
      if (isValid(i)) {
        chips.add(ActionChip(
            visualDensity: const VisualDensity(horizontal: 0.0, vertical: 0.5),
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            label: Text(chipDetails[i]['label'],
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            elevation: 10,
            shadowColor: Colors.black,
            onPressed: () => chipDetails[i]['method'](),
            avatar:
                Icon(chipDetails[i]['icon'], size: 20, color: Colors.white)));
      }
    }
    return chips;
  }

  void addAutomatically() {
    tripItem.clearAll();
    tripItem.tripActions = TripActions.headingDetail;
    tripItem.tripState = TripState.automatic;
    //  onUpdate();

    leadingWidgetController?.changeWidget(1);
    tripItem.tripValues.mapHeight = MapHeights.headers;
    createTripController.getTripInfo(prompt: false);
  }

  void addManually() {
    tripItem.clearAll();
    tripItem.tripState = TripState.manual;
    tripItem.tripActions = TripActions.headingDetail;
    tripItem.tripValues.showTarget = true;
    tripItem.tripValues.setState = true;
    tripItem.tripValues.title = 'Create trip manually';
    //  tripItem.tripValues.leadingWidget = 1;
    //  tripItem.tripValues.mapHeight = MapHeights.headers;
    leadingWidgetController?.changeWidget(1);
    tripItem.tripValues.mapHeight = MapHeights.headers;
    createTripController.getTripInfo(prompt: false);
    onUpdate();
  }

  void clear() {
    tripItem.tripState = TripState.none;
    tripItem.tripActions = TripActions.none;
    tripItem.highliteActions = HighliteActions.none;
    tripItem.tripValues.mapHeight = MapHeights.full;
    tripItem.tripValues.setState = true;
    tripItem.clearAll();
    leadingWidgetController?.changeWidget(0);
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void editing() {
    tripItem.tripState = TripState.editing;
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.editing();
    tripItem.loadBackBuffer();

    tripItem.tripValues.mapHeight = MapHeights.full;
    leadingWidgetController?.changeWidget(1);
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void extendStart() async {
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.beforeWaypoint();
    onUpdate();
    await tripItem.addWaypoint(index: -1, point: tripItem.tripValues.position);
    tripItem.tripValues.afterWaypoint();
    tripItem.isSaved = false;
    onUpdate();
  }

  void waypoint() async {
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.beforeWaypoint();
    onUpdate();
    await tripItem.addWaypoint(index: 0, point: tripItem.tripValues.position);
    tripItem.tripValues.afterWaypoint();
    tripItem.isSaved = false;
    onUpdate();
    //  createTripController.updateValues(values: tripItem.tripValues);
  }

  void revisitWaypoint() async {
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.beforeWaypoint();
    onUpdate();
    await tripItem.addWaypoint(
        index: 0, point: tripItem.tripValues.position, revisit: true);
    tripItem.tripValues.afterWaypoint();
    tripItem.isSaved = false;
    onUpdate();
    //  createTripController.updateValues(values: tripItem.tripValues);
  }

  void extendEnd() async {
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.beforeWaypoint();
    onUpdate();
    await tripItem.addWaypoint(index: 1, point: tripItem.tripValues.position);
    tripItem.tripValues.afterWaypoint();
    tripItem.isSaved = false;
    onUpdate();
  }

  saveTrip() async {
    if (tripItem.heading.isEmpty ||
        tripItem.subHeading.isEmpty ||
        tripItem.body.isEmpty) {
      createTripController.getTripInfo();
      onUpdate();
      tripItem.isSaved = false;
      return;
    }
    tripItem.title = tripItem.heading;
    tripItem.tripValues.showProgress = true;
    tripItem.tripValues.setState = true;
    // createTripController. updatetripItem(values: tripItem.tripValues);
    onUpdate();
    tripItem.mapImage ?? await createTripController.getMapImage();
    await tripItem.save();
    tripItem.tripState = TripState.loaded;
    tripItem.tripActions = TripActions.readOnly;
    tripItem.tripValues.leadingWidget = 0;
    tripItem.tripValues.showProgress = false;
    tripItem.tripValues.showTarget = false;
    tripItem.tripValues.setState = true;

    leadingWidgetController?.changeWidget(1);
    // createTripController.updateValues(values: tripItem.tripValues);
    // createTripController.updatetripItem(values: tripItem.tripValues);
    onUpdate();
    return;
  }

  void removeWaypoint() async {
    await tripItem.deleteWaypoint(position: tripItem.tripValues.position);
    tripItem.tripValues.setState = true;
    tripItem.tripValues.showTarget = true;
    tripItem.tripValues.mapHeight = MapHeights.full;
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void pauseRecording() {
    tripItem.tripState = TripState.paused;
    tripItem.tripValues.pauseFollowing();
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void endTracking() {
    tripItem.tripState = TripState.stoppedRecording;
    tripItem.tripValues.stopTracking;
    tripItem.pointsOfInterest.add(PointOfInterest(
        point: tripItem.tripValues.position,
        type: 18,
        waypoint: tripItem.pointsOfInterest.length));
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void greatRoad() {
    tripItem.isSaved = false;
    //  tripItem.startGoodRoad(position: position);
    tripItem.startGoodRoad();
    // tripItem.highliteActions = HighliteActions.greatRoadStarted;
    tripItem.tripValues.goodRoad.isGood = true;
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void greatRoadEnd() {
    //tripItem.endGoodRoad(position: position);
    // tripItem.highliteActions = HighliteActions.greatRoadEnded;
    tripItem.goodRoadEnd();
    tripItem.tripValues.goodRoad.isGood = false;
    tripItem.tripValues.showMask = false;
    tripItem.tripActions = TripActions.goodRoad;
    tripItem.tripValues.showMask = false;
    tripItem.tripValues.setState = true;
    tripItem.tripValues.mapHeight = MapHeights.pointOfInterest;
    LatLng position = tripItem
        .goodRoads.last.points[tripItem.goodRoads.last.points.length ~/ 2];
    tripItem.newPointOfInterest(position: position, type: 13);
    createTripController.updateValues(values: tripItem.tripValues);
    //  onUpdate();
  }

  void reverseTrip() async {
    await tripItem.reverseRoute();
    onUpdate();
    return;
  }

  void pointOfInterest() {
    tripItem.tripActions = TripActions.pointOfInterest;
    tripItem.tripValues.showMask = false;
    tripItem.tripValues.setState = true;
    tripItem.tripValues.mapHeight = MapHeights.pointOfInterest;
    tripItem.newPointOfInterest(position: tripItem.tripValues.position);
    tripItem.tripValues.pointOfInterestIndex =
        tripItem.pointsOfInterest.length - 1;
    createTripController.updateValues(values: tripItem.tripValues);
    // onUpdate();
    return;
  }

  void steps() {
    tripItem.tripActions = TripActions.showSteps;
    tripItem.tripValues.showTarget =
        [TripState.manual, TripState.editing].contains(tripItem.tripState);
    tripItem.tripValues.mapHeight = MapHeights.headers;
    tripItem.tripValues.setState = true;
    // onUpdate();
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void group() {
    tripItem.tripActions = TripActions.showGroup;
    tripItem.tripValues.showTarget = false;
    tripItem.tripValues.mapHeight = MapHeights.headers;
    tripItem.tripValues.setState = true;
    // onUpdate();
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void messages() {
    tripItem.tripActions = TripActions.showMessages;
    tripItem.tripValues.showTarget = false;
    tripItem.tripValues.mapHeight = MapHeights.headers;
    tripItem.tripValues.setState = true;
    // onUpdate();
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void tripData() {
    tripItem.tripActions = TripActions.none;
    tripItem.tripValues.mapHeight = MapHeights.full;
    tripItem.tripValues.setState = true;
    // onUpdate();
    createTripController.updateValues(values: tripItem.tripValues);
  }

  void trackRoute() {
    tripItem.tripState = TripState.recording;
    if (tripItem.tripValues.pauseStream) {
      tripItem.tripValues.resumeFollowing();
    } else {
      tripItem.tripValues.startFollowing();
    }
    onUpdate();
    createTripController.drive();
    return;
  }

  void followRoute() {
    tripItem.tripState = TripState.following;
    if (tripItem.tripValues.pauseStream) {
      tripItem.tripValues.resumeFollowing();
    } else {
      tripItem.tripValues.startFollowing();
    }
    // onUpdate();
    createTripController.drive();
    return;
  }

  void stopFollowing() {
    tripItem.tripState = TripState.stoppedFollowing;

    tripItem.tripValues.pauseFollowing();
    createTripController.drive();
    //  createTripController.updateValues(values: tripItem.tripValues);
    onUpdate();
  }
}
