import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/trip_tile.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/services/services.dart';

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
  bool _showPreferences = false;
  final TripsPreferences _preferences = TripsPreferences();
  final ScrollController _preferencesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = _getTripData();
    _preferencesScrollController.addListener(
      () {
        if (_preferencesScrollController.position.atEdge) {
          bool isTop = _preferencesScrollController.position.pixels == 0;
          if (isTop) {
            setState(() {
              _preferences.isRight = true;
              _preferences.isLeft = false;
            });
          } else {
            setState(() {
              _preferences.isLeft = true;
              _preferences.isRight = false;
            });
          }
        } else if (_preferences.isRight || _preferences.isLeft) {
          setState(() {
            _preferences.isLeft = false;
            _preferences.isRight = false;
          });
        }
        //  setState(() {});
      },
    );
  }

  Future<bool> _getTripData() async {
    if (!Setup().hasRefreshedTrips && Setup().hasLoggedIn) {
      tripItems = await getTrips();
      if (tripItems.isNotEmpty) {
        Setup().hasRefreshedTrips = true;
        tripItems = await saveTripItemsLocal(tripItems);
      }
    } else {
      tripItems = await loadTripItems();
    }
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<void> onGetTrip(int index) async {
    MyTripItem webTrip = await getMyTrip(tripItems[index].driveUri);
    webTrip.setId(-1);
    webTrip.setDriveUri(tripItems[index].driveUri);
    if (context.mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(webTrip, 'web'));
    }
  }

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
    if (tripItems.isEmpty) {
      tripItems.add(TripItem(
          heading: 'Explore the countryside around you',
          subHeading: "Register now to enjoy other people's trips",
          body:
              '''Finding nice places for a drive can be a bit of a challenge particularly if you're not familiar with an area. 
You can download trips that other people have enjoyed, stopping at the pubs, restaurants and other points of interest they have rated. 
You can modify the trips, and publish them yourself for others to enjoy too. 
          ''',
          author: 'Alex S',
          published: '05 Aug 2025',
          imageUrls:
              '[{"url": "map.png", "caption": ""}, {"url": "meeting.png", "caption": ""}]',
          score: 5.0,
          distance: 15.5,
          pointsOfInterest: 3,
          closest: 10,
          scored: 15,
          downloads: 25,
          uri: 'assets/images/'));
    }
    return ListView(
      children: [
        Card(
          child: Column(
            children: [
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      tripItems.isNotEmpty && tripItems[0].uri.contains('http')
                          ? 'Trips for you to enjoy...'
                          : 'Sign up to share trips...',
                      style: const TextStyle(
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
          onMenuTap: (index) => _leadingWidget(_scaffoldKey.currentState),
        ), // IconButton(
        title: Text(
          tripItems.isNotEmpty && tripItems[0].uri.contains('http')
              ? 'Trips available to download'
              : 'To share trips register for free',
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),

        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), //keyboard_arrow_down),
            onPressed: () =>
                setState(() => _showPreferences = !_showPreferences),
          ),
        ],
        bottom: (_showPreferences)
            ? PreferredSize(
                preferredSize: const ui.Size.fromHeight(60),
                child: AnimatedContainer(
                  height: 60,
                  curve: Curves.easeInOut,
                  duration: const Duration(seconds: 3),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: setPreferences(),
                  ),
                ),
              )
            : null,
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

  Widget setPreferences() {
    return SizedBox(
      height: 20,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          //  if (!_preferences.isLeft) ...[
          Icon(_preferences.isLeft ? null : Icons.arrow_back_ios,
              color: Colors.white),
          //  ],
          SizedBox(
            width: MediaQuery.of(context).size.width - 60, //delta,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: _preferencesScrollController,
              children: <Widget>[
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    checkColor: Colors.white,
                    title: const Text('Current location',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.currentLocation,
                    onChanged: (value) =>
                        setState(() => _preferences.currentLocation = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    //  activeColor: Colors.white,
                    hoverColor: Colors.white,
                    title: const Text('North West',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.northWest,
                    onChanged: (value) =>
                        setState(() => _preferences.northWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('North East',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.northEast,
                    onChanged: (value) =>
                        setState(() => _preferences.northEast = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    //  activeColor: Colors.white,
                    hoverColor: Colors.white,
                    title: const Text('South West',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.southWest,
                    onChanged: (value) =>
                        setState(() => _preferences.southWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('South East',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.southEast,
                    onChanged: (value) =>
                        setState(() => _preferences.southEast = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
          //  if (!_preferences.isRight) ...[
          Icon(
            _preferences.isRight ? null : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
