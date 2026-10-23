import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/models/models.dart';
import '/classes/classes.dart' hide Route;
import '/tiles/my_trip_tile.dart';
import '/services/services.dart';
import '/helpers/helpers.dart';
import '../constants.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class MyTripsController {
  _MyTripsScreenState? _myTripsScreenState;

  void _addState(_MyTripsScreenState myTripsScreenState) {
    _myTripsScreenState = myTripsScreenState;
  }

  bool get isAttached => _myTripsScreenState != null;

  void refresh() {
    if (isAttached) {
      _myTripsScreenState?.refresh();
    }
  }

  void addCurrentTripItem() {
    if (isAttached) {
      _myTripsScreenState?.addCurrentTripItem();
    }
  }
}

class MyTrips extends StatefulWidget {
  final MyTripsController? controller;
  const MyTrips({
    super.key,
    this.controller,
  });
  @override
  State<MyTrips> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTrips> {
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<MyTripItem> _myTripItems = [];
  final ImageRepository _imageRepository = ImageRepository();

  @override
  void initState() {
    super.initState();
    developer.log(
        '_MyTripsScreen().initState() MapService().myTripsController is null: ${MapService().myTripsController == null}',
        name: 'error');
    if (MapService().myTripsController != null) {
      MapService().myTripsController?._addState(this);
    }
    _dataLoaded = getMyTripItems();
  }

  Future<bool> getMyTripItems() async {
    // _tripItems = await getPrivateTrips(); <-- gets saved trips from api
    try {
      TripRepository tripRepository = TripRepository();
      await tripRepository.openBox();
      _myTripItems = await tripRepository.getTrips();
    } catch (e) {
      developer.log('Error trying to get items: ${e.toString()}',
          name: 'error');
    }
    return true;
  }

  void refresh() async {
    await getMyTripItems();
    if (mounted) {
      setState(() {});
    }
  }

  void addCurrentTripItem() {
    _myTripItems.add(CurrentTripItem());
  }

  Future<void> onGetTrip(int index) async {}

  /// Loads CurrentTripItem() with the chosen trip and navigates to My Trip page - create_trip.dart
  Future<void> loadTrip(int index) async {
    // /load_private/<uri>

    MyTripItem? myTripItem = await loadSavedTripByUri(_myTripItems[index].uri);

    myTripItem ??= _myTripItems[index];

    CurrentTripItem().id = myTripItem.id;
    CurrentTripItem().uri = myTripItem.uri;
    CurrentTripItem().title = myTripItem.title;
    CurrentTripItem().subTitle = myTripItem.subTitle;
    CurrentTripItem().author = myTripItem.author;
    CurrentTripItem().authorUri = myTripItem.authorUri;
    CurrentTripItem().images = myTripItem.images;
    CurrentTripItem().imageUrls = myTripItem.imageUrls;
    CurrentTripItem().body = myTripItem.body;
    CurrentTripItem().pointsOfInterest = myTripItem.pointsOfInterest;
    CurrentTripItem().maneuvers = myTripItem.maneuvers;
    CurrentTripItem().routes = myTripItem.routes;
    CurrentTripItem().goodRoads = myTripItem.goodRoads;
    CurrentTripItem().score = myTripItem.score;
    CurrentTripItem().tripState = TripState.loaded;
    CurrentTripItem().tripType = TripType.none;
    CurrentTripItem().updateMap = true;
    CurrentTripItem().mapUpdates = MapUpdates.updateAll;

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, 'createTrip', (Route<dynamic> route) => false, //,
          arguments: TripArguments(trip: myTripItem, origin: 'db'));
    }
  }

  Future<void> shareTrip(int index) async {
    return;
  }

  void deleteTrip(int index) {
    setState(() => _myTripItems.removeAt(index));
  }

  /// May have a problem having a single method for publishing a drive on
  /// both the Web and Android version. The issue is likely to be how to
  /// handle images - Android is simple but the Web may be problematic.
  /// Loading only basic trip information into the My Drives list.
  /// Will add remaining information if the user requests it by
  /// expanding the expansion tile.
  Future<void> onExpandChange(int index, bool expanded) async {}

  Widget _getPortraitBody() {
    if (_myTripItems.isEmpty && Setup().jwt.isEmpty) {
      return Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/scenery.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4), // // Light shadow top
                  Colors.black.withValues(alpha: 0.6), // Dark contrast bottom
                ],
              ),
            ),
          ),
        ),
        if (Setup().jwt.isEmpty && _myTripItems.isEmpty) ...[
          if (Setup().jwt.isEmpty) ...[
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Text(
                      'My Drives allows you to build up a library of trips that you have enjoyed.',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      '''Registering in Drives ensures your saved trip details will be available to all your devices, otherwise trips can only be shared with other devices through the Drives WiFi import export facility.''',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      "Registering allows you to publish your trips, for your friends or other people to enjoy.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      "Registering helps when members of a club, or a group of friends want to follow the trip together.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      "Registering gives in-app messaging and real-time group location tracking.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text("Tap the button below to log in.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 50),
                  Center(
                    child: ActionChip(
                      label: Text('Register Now',
                          style: TextStyle(fontSize: 22, color: Colors.white)),
                      onPressed: () => context.push('/login'),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_myTripItems.isEmpty && Setup().jwt.isNotEmpty) ...[
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Text("You haven't saved any trips yet.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      '''Saving trips allows you to keep your own private library of trips stored on your device.''',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      '''To save a trip go to the explore screen, enter the waypoints for the trip and any photos. 
                      Tap the Save Trip button and it will be saved in this screen as a personal trip.''',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  if (Setup().jwt.isNotEmpty)
                    Text(
                        "Any trips you have saved can be publish, for your friends or other people to enjoy.",
                        style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Text(
                      "Saved trips can be edited, new images added, and saved again as a personal trip.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  if (Setup().jwt.isNotEmpty) ...[
                    Text(
                        "Registering helps when members of a club, or a group of friends want to follow the trip together.",
                        style: TextStyle(fontSize: 22, color: Colors.white)),
                    SizedBox(height: 20),
                    Text(
                        "Registering gives in-app messaging and real-time group location tracking.",
                        style: TextStyle(fontSize: 22, color: Colors.white)),
                    SizedBox(height: 20),
                  ],
                  Text("Tap the button below to log in.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ]
        ],
      ]);
    }

    if (_myTripItems.isEmpty) {
      _myTripItems.add(MyTripItem(
          title: 'No favourite trips saved', subTitle: 'Why not add one now?'));
    }

    ListView listView = ListView(
      children: [
        for (int i = 0; i < _myTripItems.length; i++) ...[
          Padding(
            padding: kIsWeb
                ? const EdgeInsets.fromLTRB(250, 5, 250, 5)
                : const EdgeInsets.fromLTRB(5, 5, 5, 0),
            child: MyTripTile(
              index: i,
              myTripItem: _myTripItems[i],
              onDeleteTrip: (index) => deleteTrip(index),
              onExpandChange: onExpandChange,
              showMethods:
                  !_myTripItems[i].title.contains('Save your trips for'),
              imageRepository: _imageRepository,
            ),
          )
        ],
        const SizedBox(
          height: 40,
        ),
      ],
    );
    return listView;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      // The main drawer is on the shell Scaffold in main.dart
      //   appBar: PersistentAppBar(
      //       controller: MapService().persistentAppBarController!, page: 3),

      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return _getPortraitBody();
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
          throw ('Error - FutureBuilder in main.dart');
        },
      ),
    );
  }
}
