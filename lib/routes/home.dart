// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/home_tile.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';
import 'package:drives/screens/dialogs.dart';

import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  // var setup;

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<HomeScreen> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  List<HomeItem> homeItems = [];
  late Future<bool> _dataLoaded;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = _getHomeData();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  /// _getHomeData() used to trigger FutureBuilder
  /// Has to be used in the initState() and the result used
  /// in the FutureBuilder
  /// It's going to see if the server is up, and if so copy all the
  /// home_page items into a local SQLite cache. The home_tile will
  /// read the data from the cache saving network traffic and ensuring
  /// seemless use when off-lime. It also allows the home_page to be
  /// displayed before the user has logged in.
  /// Once the user logs in it will check that all the home_item entries
  /// are up to date and will synchronise the cache with the API data.

  Future<bool> _getHomeData() async {
    if (!Setup().hasLoggedIn) {
      await tryLoggingIn();
      homeItems = await getHomeItems(1); // get API data
      if (homeItems.isNotEmpty) {
        Setup().hasLoggedIn = true;
        homeItems = await saveHomeItemsLocal(homeItems); // load cache
        return true;
      }
      return true;
    } else if (Setup().bottomNavIndex > 0) {
      // Look to see if the app was left open
      _bottomNavController.setValue(Setup().bottomNavIndex);
      Setup().bottomNavIndex = 0;
      Setup().setupToDb();
      _bottomNavController.navigate();
    } else {
      homeItems = await loadHomeItems(); // get cached homeItems
    }
    return true;
  }

  tryLoggingIn() async {
    try {
      User user = await getUser();
      bool serverUp = await serverListening();
      if (serverUp) {
        if (user.email.isNotEmpty && user.password.length > 6) {
          tryLogin(user: user).then(
            (response) {
              String status = response['msg'] ?? '';
              if (status == 'OK') {
                saveUser(user);
              }
            },
          );
        } else {
          if (context.mounted) {
            await loginDialog(context, user: user);
          }
        }
      } else {
        debugPrint('Server not listening');
      }
    } catch (e) {
      debugPrint('Splash login error: ${e.toString()}');
    }
  }

  Widget _getPortraitBody() {
    if (homeItems.isEmpty) {
      homeItems.add(HomeItem(
        id: -2,
        uri: 'assets/images/',
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        imageUrls: '[{"url": "aiaston.png", "caption": ""}]',
      ));

      homeItems.add(
        HomeItem(
            id: -2,
            uri: 'assets/images/',
            heading: 'Share your trips',
            subHeading: 'Let others know about your beautiful trip',
            body:
                '''MotaTrip lets you enjoy trips other users have saved.  You can also publish your trips for others to enjoy. You can invite a group of friends to share your trip and track their progress as they drive with you. 
You can rate pubs and other points of interest to help others enjoy their trip.''',
            imageUrls:
                '[{"url": "meeting.png", "caption": ""}]'), //CarGroup.png'),
      );
    }

    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'MotaTrip',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'the new free trip planning app',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
      ])),
      for (int i = 0; i < homeItems.length; i++) ...[
        HomeTile(homeItem: homeItems[i])
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
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
          'MotaTrip Trip planning app',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<bool>(
        //  initialData: false,
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
          initialValue: 0,
          onMenuTap: (_) => {}),
    );
  }
}
