import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/models/models.dart';
import '/classes/classes.dart' hide Route;
import '/tiles/my_trip_tile.dart';
import '/screens/screens.dart';
import '/services/services.dart';
import '/helpers/edit_helpers.dart';
import '../constants.dart';
import 'package:go_router/go_router.dart';
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
  final ImageRepository _imageRepository = ImageRepository();

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
    // fromMyTripItem({required MyTripItem myTripItem})
    // /load_private/<uri>

    MyTripItem? myTripItem = await PrivateStorageLocal()
        .loadMyTripItem(uri: _myTripItems[index].uri);

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
      //   if (kIsWeb) {
      //   } else {
      Navigator.pushNamedAndRemoveUntil(
          context, 'createTrip', (Route<dynamic> route) => false, //,
          arguments: TripArguments(trip: myTripItem, origin: 'db'));
      //  }
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

  void deleteTrip(int index) {
    setState(() => _myTripItems.removeAt(index));
    /* 
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: ' ', // _myTripItems[index].heading,
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) async {
    if (value > -1) {
      String id =
          kIsWeb ? _myTripItems[value].uri : _myTripItems[value].id.toString();

      getPrivateRepository()
          .deleteDriveLocal(tripItem: _myTripItems[value])
          .then((_) => setState(() => _myTripItems.removeAt(value)));
    }
    */
  }

/*
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/rng.dart';

*/

  /// May have a problem having a single method for publishing a drive on
  /// both the Web and Android version. The issue is likely to be how to
  /// handle images - Android is simple but the Web may be problematic.
/*
  Future<void> publishTrip(int index) async {
    await publish(_myTripItems[index]);
    // await getPrivateRepository().publish(_myTripItems[index]);
    return;
  }
*/
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
      setState(()  {});
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
    if (Setup().jwt.isEmpty) {
      return Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/aiaston.png',
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
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Text(
                  'My Drives allows you to build up a library of trips that you have enjoyed.',
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                  "If you haven't logged in to Drives then your trip details will only be saved on your device.",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                  "Trip information can't be stored on your PC if you are using the Web version.",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                  "You can't access data stored on your device for the PC browser version.",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                  "If you want to share your trip with other people, or access it with your PC you have to login first.",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 20),
              Text("Tap the button below to log in.",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              SizedBox(height: 50),
              ActionChip(
                label: Text('Login Now',
                    style: TextStyle(fontSize: 22, color: Colors.white)),
                onPressed: () => context.push('/login'),
                backgroundColor: Colors.blue,
              ),
            ],
          ),
        )
      ]);
    }

    if (_myTripItems.isEmpty) {
      _tripItems.add(TripItem(
          title: 'No favourite trips saved', subTitle: 'Why not add one now?'));
    }

    ListView listView = ListView(
      children: [
        for (int i = 0; i < _myTripItems.length; i++) ...[
          Padding(
            padding: kIsWeb
                ? const EdgeInsets.fromLTRB(250, 5, 250, 5)
                : const EdgeInsets.fromLTRB(5, 5, 5, 0),
            /*   child: Center(
              child: Text('Stuff '),
            ),
          */

            child: MyTripTile(
              index: i,
              myTripItem: _myTripItems[i],
              // onLoadTrip: loadTrip,
              // onShareTrip: shareTrip,
              onDeleteTrip: (index) => deleteTrip(index),
              //  onPublishTrip: publishTrip,
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
      drawer: const MainDrawer(),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: LeadingWidget(
            controller: _leadingWidgetController,
            onMenuTap: (index) => _leadingWidget(
              _scaffoldKey.currentState,
            ),
          ), // IconButton(
          title: const Text(
            'My Drives',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              onPressed: () {
                if (Setup().jwt.isEmpty) {
                  context.push('/login');
                }
              },
              icon: Icon(
                Setup().jwt.isEmpty
                    ? Icons.no_accounts_outlined
                    : Icons.account_circle_outlined,
                size: 30,
              ),
            )
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
      /*   bottomNavigationBar: RoutesBottomNav(
          controller: _bottomNavController,
          initialValue: 3,
          onMenuTap: (_) => {}), */
    );
  }
}
