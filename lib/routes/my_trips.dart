import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/tiles/my_trip_tile.dart';
import 'package:drives/screens/screens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:drives/services/services.dart';
import 'package:latlong2/latlong.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({
    super.key,
  });

  @override
  State<MyTripsScreen> createState() => _myTripsScreenState();
}

class _myTripsScreenState extends State<MyTripsScreen> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<MyTripItem> _myTripItems = [];

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = getMyTripItems();
  }

  Future<bool> getMyTripItems() async {
    _myTripItems = await tripItemFromDb();
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<void> onGetTrip(int index) async {}

  Future<void> loadTrip(int index) async {
    int driveId = _myTripItems[index].getId();

    MyTripItem dbTrip = _myTripItems[index];
    await dbTrip.loadLocal(driveId);
    if (context.mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(dbTrip, 'db'));
    }
  }

  Future<void> shareTrip(int index) async {
    MyTripItem currentTrip = _myTripItems[index];
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
    return;
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: _myTripItems[index].getHeading(),
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      int driveId = _myTripItems[value].getDriveId();
      deleteDriveLocal(driveId: driveId);
      setState(() => _myTripItems.removeAt(value));
    }
  }

  Future<void> publishTrip(int index) async {
    String driveUI = '';
    int driveId = _myTripItems[index].getDriveId();
    postTrip(_myTripItems[index]).then((driveUi) {
      driveUI = driveUi['id'];
      for (PointOfInterest pointOfInterest
          in _myTripItems[index].pointsOfInterest()) {
        postPointOfInterest(pointOfInterest, driveUI);
      }
    }).then((_) async {
      List<Polyline> polylines = await loadPolyLinesLocal(driveId, type: 0);
      postPolylines(polylines, driveUI, 0);

      polylines = await loadPolyLinesLocal(driveId, type: 1);
      if (polylines.isNotEmpty) {
        postPolylines(polylines, driveUI, 1);
      }

      List<Maneuver> maneuvers = await loadManeuversLocal(driveId);
      postManeuvers(maneuvers, driveUI);
    });
    return;
  }

  Widget _getPortraitBody() {
    if (_myTripItems.isEmpty) {
      _myTripItems.add(
        MyTripItem(
            heading: 'Save your favourite trips for later or to share',
            subHeading:
                'Add points of interest, nice roads, pubs restaurants etc.',
            body:
                'Describe the trip and why you liked it. You can share the trip with members of a group. You can also publish a trip for other people to enjoy',
            pointsOfInterest: [
              PointOfInterest(
                -1,
                -1,
                1,
                '',
                '',
                30,
                30,
                markerPoint: const LatLng(-52, 0),
                marker: const Icon(Icons.ac_unit),
              ),
            ],
            distance: 35,
            closest: 10,
            images:
                '[{"url": "assets/images/map.png", "caption": ""},{"url": "assets/images/meeting.png", "caption": ""}]',
            published: '',

            //  DateTime.now().subtract(const Duration(days: 10)).toString(),
            publisher: ''),
      );
    }
    return ListView(
      children: [
        Card(
          child: Column(
            children: [
              SizedBox(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        _myTripItems[0].getImages().contains('assets')
                            ? 'Save your trips to enjoy again...'
                            : "Trips I've already explored...",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    )),
              ),
            ],
          ),
        ),
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
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
            controller: _leadingWidgetController,
            onMenuTap: (index) =>
                _leadingWidget(_scaffoldKey.currentState)), // IconButton(
        title: const Text(
          "Trips I've already saved",
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
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
