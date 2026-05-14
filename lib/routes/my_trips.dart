import 'dart:math';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart' hide Route;
import '/tiles/my_trip_tile.dart';
import '/screens/screens.dart';
import '/services/services.dart';
import '/helpers/edit_helpers.dart';
import '../constants.dart';
// import 'package:latlong2/latlong.dart';

class MyTrips extends StatefulWidget {
  const MyTrips({
    super.key,
  });

  @override
  State<MyTrips> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTrips> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<TripItem> _tripItems = [];
  List<MyTripItem> _myTripItems = [];

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = getMyTripItems();
  }

  Future<bool> getMyTripItems() async {
    // _tripItems = await getPrivateTrips(); <-- gets saved trips from api
    _myTripItems = await getPrivateRepository().loadMyTripItems();
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<void> onGetTrip(int index) async {}

  /// Loads CurrentTripItem() with the chosen trip and navigates to My Trip page - create_trip.dart
  Future<void> loadTrip(int index) async {
    // CurrentTripItem.reset();
    // CurrentTripItem().clearAll(newTripState: TripState.loaded);
    CurrentTripItem().id = _myTripItems[index].id;
    CurrentTripItem().uri = _myTripItems[index].uri;
    CurrentTripItem().title = _myTripItems[index].title;
    CurrentTripItem().subTitle = _myTripItems[index].subTitle;
    CurrentTripItem().author = _myTripItems[index].author;
    CurrentTripItem().authorUri = _myTripItems[index].authorUri;
    CurrentTripItem().images = _myTripItems[index].images;
    CurrentTripItem().imageUrls = _myTripItems[index].imageUrls;
    CurrentTripItem().body = _myTripItems[index].body;
    CurrentTripItem().pointsOfInterest = _myTripItems[index].pointsOfInterest;
    CurrentTripItem().maneuvers = _myTripItems[index].maneuvers;
    CurrentTripItem().routes = _myTripItems[index].routes;
    CurrentTripItem().goodRoads = _myTripItems[index].goodRoads;
    CurrentTripItem().score = _myTripItems[index].score;
    CurrentTripItem().tripState = TripState.loaded;
    CurrentTripItem().tripType = TripType.none;
    CurrentTripItem().updateMap = true;
    CurrentTripItem().mapUpdates = MapUpdates.updateAll;

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, 'createTrip', (Route<dynamic> route) => false); //,
      //  arguments: TripArguments(_myTripItems[index], 'db'));
    }
  }

  Future<void> shareTrip(int index) async {
    TripItem currentTrip = _tripItems[index];
    /*
    currentTrip.showMethods = false;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ShareForm(
                tripItem: currentTrip,
              )),
    ).then((value) {
      setState(() {
        currentTrip.showMethods = true;
      });
    });
    */
    return;
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: ' ', // _myTripItems[index].heading,
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) async {
    if (value > -1) {
      String id = _myTripItems[value].id >= 0
          ? _myTripItems[value].id.toString()
          : _myTripItems[value].uri;
      getPrivateRepository()
          .deleteDriveLocal(driveUri: id)
          .then((_) => setState(() => _myTripItems.removeAt(value)));
    }
  }

/*
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/rng.dart';

*/

  /// May have a problem having a single method for publishing a drive on
  /// both the Web and Android version. The issue is likely to be how to
  /// handle images - Android is simple but the Web may be problematic.

  Future<void> publishTrip(int index) async {
    await publish(_myTripItems[index]);
    // await getPrivateRepository().publish(_myTripItems[index]);
    return;
  }

  /// Loading only basic trip information into the My Drives list.
  /// Will add remaining information if the user requests it by
  /// expanding the expansion tile.
  Future<void> onExpandChange(int index, bool expanded) async {
    /*
    if (_myTripItems[index].pointsOfInterest.isEmpty) {
      try {
        _myTripItems[index] =
            await loadPrivateTrip(uri: _myTripItems[index].uri) ??
                _myTripItems[index];
      } catch (e) {
        debugPrint('Error getting the trip details');
      }
      setState(() => ());
    }
    */
  }

  /*
  Future<void> refreshTrip(int index) async {
    Map<String, dynamic> tripJSON = _myTripItems[index].
    _myTripItems[index] = MyTripItem.fromJson()
  }
  */

  Widget _getPortraitBody() {
    if (_myTripItems.isEmpty) {
      _myTripItems.add(
        MyTripItem(
          title: 'Save your trips for later, or to share',
          subTitle: 'Add points of interest, nice roads, pubs restaurants etc.',
          body:
              'Describe the trip and why you liked it. You can share the trip with members of a group. You can also publish a trip for other people to enjoy',
          pointsOfInterest: [
            PointOfInterest(
              point: Point(0, 0),
            ),
          ],
          distance: 35,
          closest: 10,
          images:
              '[{"url": "assets/images/map.png", "caption": ""},{"url": "assets/images/meeting.png", "caption": ""}]',
          added: dateFormat.format((DateTime.now())),
          author: Setup().user.forename,
        ),
      );
    }
    return ListView(
      children: [
        for (int i = 0; i < _myTripItems.length; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: MyTripTile(
              index: i,
              myTripItem: _myTripItems[i],
              onLoadTrip: loadTrip,
              onShareTrip: shareTrip,
              onDeleteTrip: deleteTrip,
              onPublishTrip: publishTrip,
              onExpandChange: onExpandChange,
              showMethods:
                  !_myTripItems[i].title.contains('Save your trips for'),
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
      drawer: const MainDrawer(),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: LeadingWidget(
              controller: _leadingWidgetController,
              onMenuTap: (index) =>
                  _leadingWidget(_scaffoldKey.currentState)), // IconButton(
          title: Text(
            "My Drives",
            style: headlineStyle(context: context, size: 1),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
                onPressed: () => {}, icon: Icon(Icons.help_outline_outlined))
          ]),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
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
      bottomNavigationBar: RoutesBottomNav(
          controller: _bottomNavController,
          initialValue: 3,
          onMenuTap: (_) => {}),
    );
  }
}
