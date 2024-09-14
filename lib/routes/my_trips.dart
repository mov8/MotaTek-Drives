import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/routes_bottom_nav.dart';
import 'package:drives/models/my_trip_item.dart';
import 'package:drives/tiles/my_trip_tile.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/leading_widget.dart';
// import 'package:drives/services/web_helper.dart';
//import 'package:drives/services/db_helper.dart';

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

  Future<void> loadTrip(int index) async {}
  Future<void> shareTrip(int index) async {}
  Future<void> deleteTrip(int index) async {}
  Future<void> publishTrip(int index) async {}

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
                        "Trips I've already explored...",
                        style: TextStyle(
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
