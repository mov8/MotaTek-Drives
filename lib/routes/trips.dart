import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/routes_bottom_nav.dart';
import 'package:drives/tiles/trip_tile.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/leading_widget.dart';
import 'package:drives/services/web_helper.dart';

import 'package:geolocator/geolocator.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
  });

  @override
  State<TripsScreen> createState() => _tripsScreenState();
}

class _tripsScreenState extends State<TripsScreen> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<TripItem> tripItems = [];

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = tripsFromWeb();
  }

  Future<bool> tripsFromWeb() async {
    int tries = 0;

    //  Position _currentPosition = await Geolocator.getCurrentPosition();

    //  while (Setup().jwt.isEmpty && ++tries < 4) {
    //    await login(context);
    //    if (Setup().jwt.isEmpty) {
    //      debugPrint('Login failed');
    //    }
    //  }
    tripItems = await getTrips();
    for (int i = 0; i < tripItems.length; i++) {}
    // setState(() {});
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<void> onGetTrip(int index) async {}

  onTripRatingChanged(int value, int index) async {
    setState(
      () {
        debugPrint('Value: $value  Index: $index');
        tripItems[index].score = value.toDouble();
      },
    );
    putDriveRating(tripItems[index].uri, value);
  }

  Widget _getPortraitBody() {
    return ListView(
      children: [
        const Card(
          child: Column(
            children: [
              SizedBox(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'Trips for you to enjoy...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < tripItems.length; i++) ...[
          TripTile(
            tripItem: tripItems[i],
            index: i,
            onGetTrip: onGetTrip,
            onRatingChanged: onTripRatingChanged,
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
            onMenuTap: () =>
                _leadingWidget(_scaffoldKey.currentState)), // IconButton(
        title: const Text(
          'Trips available to download',
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
          throw ('Error - FutureBuilder in trips.dart');
        },
      ),
      bottomNavigationBar: RoutesBottomNav(
          controller: _bottomNavController,
          initialValue: 1,
          onMenuTap: (_) => {}),
    );
  }
}
