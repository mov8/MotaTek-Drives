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

  /// Web: re-reads the saved trips and puts their summaries in the SideDrawer
  void fillSideDrawer() => _myTripsScreenState?.refresh();

  /// Web: shows a trip's details to the right of the SideDrawer
  void select(int index) => _myTripsScreenState?.select(index);

  int get selected => _myTripsScreenState?._selected ?? -1;
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
  int _selected = 0; // web: the trip whose details are showing
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
      sideBarItems();
    }
  }

  void select(int index) {
    setState(() => _selected = index);
    sideBarItems(); // highlights the selected summary
  }

  /// Web: the trips' summaries in the SideDrawer - or, with no trips, the
  /// image and message filling it
  void sideBarItems() {
    if (!kIsWeb || !mounted || NavigationService().page != 3) return;
    if (_selected >= _myTripItems.length) _selected = 0;
    MapService().sideDrawerController!.open();
    MapService().sideDrawerController!.setContent(
        content: BottomDrawerItems.favourites, drawerItems: _myTripItems);
    MapService().sideDrawerController!.setFixed(fixed: true);
    MapService().sideDrawerController!.setVisible(visible: true);
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
    sideBarItems();
  }

  /// May have a problem having a single method for publishing a drive on
  /// both the Web and Android version. The issue is likely to be how to
  /// handle images - Android is simple but the Web may be problematic.
  /// Loading only basic trip information into the My Drives list.
  /// Will add remaining information if the user requests it by
  /// expanding the expansion tile.
  Future<void> onExpandChange(int index, bool expanded) async {}

  Widget _getPortraitBody() {
    if (kIsWeb) {
      // The summaries (or the no-trips message) are in the SideDrawer; the
      // selected trip's details go to its right, like Home and Shop
      if (_myTripItems.isEmpty) return const SizedBox.shrink();
      int index = _selected < _myTripItems.length ? _selected : 0;
      return Padding(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.38 + 10, 5, 10, 5),
        child: SingleChildScrollView(
          child: MyTripTile(
            key: ValueKey(_myTripItems[index].uri),
            view: MyTripTileView.details,
            index: index,
            myTripItem: _myTripItems[index],
            onDeleteTrip: (index) => deleteTrip(index),
            showMethods: true,
            imageRepository: _imageRepository,
          ),
        ),
      );
    }
    if (_myTripItems.isEmpty) {
      return const MyTripsEmptyView();
    }
    return ListView(
      children: [
        for (int i = 0; i < _myTripItems.length; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
            child: MyTripTile(
              index: i,
              myTripItem: _myTripItems[i],
              onDeleteTrip: (index) => deleteTrip(index),
              onExpandChange: onExpandChange,
              showMethods: true,
              imageRepository: _imageRepository,
            ),
          )
        ],
        const SizedBox(
          height: 40,
        ),
      ],
    );
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

/// Shown when there are no saved trips - the whole screen on a phone, the
/// whole SideDrawer on the web. Logged out it explains registering; logged
/// in, how to save a trip.
class MyTripsEmptyView extends StatelessWidget {
  const MyTripsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontSize: 22, color: Colors.white);
    List<String> lines = Setup().jwt.isEmpty
        ? [
            'My Drives allows you to build up a library of trips that you have enjoyed.',
            'Registering in Drives ensures your saved trip details will be available to all your devices, otherwise trips can only be shared with other devices through the Drives WiFi import export facility.',
            'Registering allows you to publish your trips, for your friends or other people to enjoy.',
            'Registering helps when members of a club, or a group of friends want to follow the trip together.',
            'Registering gives in-app messaging and real-time group location tracking.',
            'Tap the button below to log in.',
          ]
        : [
            "You haven't saved any trips yet.",
            'Saving trips allows you to keep your own private library of trips stored on your device.',
            'To save a trip go to the explore screen, enter the waypoints for the trip and any photos. Tap the Save Trip button and it will be saved in this screen as a personal trip.',
            'Any trips you have saved can be published, for your friends or other people to enjoy.',
            'Saved trips can be edited, new images added, and saved again as a personal trip.',
          ];
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
                Colors.black.withValues(alpha: 0.4), // Light shadow top
                Colors.black.withValues(alpha: 0.6), // Dark contrast bottom
              ],
            ),
          ),
        ),
      ),
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            for (String line in lines) ...[
              Text(line, style: style),
              const SizedBox(height: 20),
            ],
            if (Setup().jwt.isEmpty) ...[
              const SizedBox(height: 30),
              Center(
                child: ActionChip(
                  label: const Text('Register Now', style: style),
                  onPressed: () => kIsWeb
                      ? MapService()
                          .sideDrawerController
                          ?.setContent(content: BottomDrawerItems.login)
                      : context.push('/login'),
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}
