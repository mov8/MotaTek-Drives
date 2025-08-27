// import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:drives/constants.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/home_tile.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart' hide getPosition;
import 'package:drives/screens/screens.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

class Home extends StatefulWidget {
  // var setup;

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final ImageRepository _imageRepository;
  final GlobalKey _scaffoldKey = GlobalKey();
  List<HomeItem> homeItems = [];
  late Future<bool> _dataLoaded;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _imageRepository = ImageRepository();
    // if (!Setup().loggingIn) {
    _dataLoaded = _getHomeData();
    // }
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  @override
  void dispose() {
    _imageRepository.clear();
    super.dispose();
  }

  /// _getHomeData() used to trigger FutureBuilder
  /// Has to be used in the initState() and the result used
  /// in the FutureBuilder
  /// It's going to see if the server is up, and if so copy all the
  /// home_page items into a local SQLite cache. The home_tile will
  /// read the data from the cache saving network traffic and ensuring
  /// seamless use when off-lime. It also allows the home_page to be
  /// displayed before the user has logged in.
  /// Once the user logs in it will check that all the home_item entries
  /// are up to date and will synchronise the cache with the API data.

  Future<bool> _getHomeData() async {
    if (!Setup().hasLoggedIn) {
      //Setup().hasLoggedIn = true;
      Setup().loggingIn = true;
      await tryLoggingIn().then((_) async {
        homeItems = await getHomeItems(1); // get API data

        Setup().lastPosition = await getPosition();
        //  Setup().appState = '{"route": 2, "trip_id": 233}';
        if (Setup().appState.isEmpty) {
          Setup().bottomNavIndex = 0;
        } else {
          Setup().bottomNavIndex = jsonDecode(Setup().appState)['route'] ?? 0;
        }

        if (homeItems.isNotEmpty) {
          Setup().hasLoggedIn = true;
          getStats();
        }
        //    _bottomNavController.setValue(Setup().bottomNavIndex);
        //    _bottomNavController.navigate();
      });
      return true;
    } else if (Setup().bottomNavIndex > 0) {
      // Look to see if the app was left open
      _bottomNavController.setValue(Setup().bottomNavIndex);
      // Setup().appState = "{route: 2, trip_id: 233}";
      if (Setup().appState == '') {
        Setup().bottomNavIndex = 0;
      } else {
        Setup().bottomNavIndex = jsonDecode(Setup().appState)['route'] ?? 0;
      }
      Setup().setupToDb();
      return true;
      //   _bottomNavController.navigate();
    } else {
      //  homeItems = await loadHomeItems(); // get cached homeItems
      homeItems = await getHomeItems(1); // get API data
      return true;
    }
  }

  Future<bool> tryLoggingIn() async {
    try {
      ///  User user = await getUser();
      /// Three possibilities for logging in
      /// 1 Password & email on device
      ///   Silent login retrieving fresh jwt
      /// 2 No password or email on device - new device / user
      ///   Login dialog appears
      /// 3 Email on device and password < 8 characters
      ///   Sign_up form appears to allow completion of registration
      developer.log(
          'tryLoggingIn() ${Setup().user.password.isEmpty ? 'Use passord empty' : 'password found'}',
          name: '_login');
      //   int code = 0;

      if (Setup().user.password.isEmpty) {
        await getUser();
      }

      LoginState loginState = LoginState.notLoggedin;
      bool serverUp = await serverListening();
      developer.log(
          'tryLoggingIn() ${serverUp ? 'Server is up' : 'Server down'} on $urlBase',
          name: '_login');

      if (serverUp) {
        /// Try silent login first

        if (Setup().jwt.isNotEmpty &&
            Setup().user.email.isNotEmpty &&
            Setup().user.password.length > 8) {
          bool refreshed = await refreshToken();
          developer.log(refreshed ? 'JWT refreshed' : 'JWT NOT REFRESHED',
              name: '_login');
          if (refreshed) {
            Setup().hasLoggedIn = true;
            return true;
          }
        }

        if (Setup().user.email.isNotEmpty && Setup().user.password.length > 8) {
          Map<String, dynamic> response = await tryLogin(user: Setup().user);
          String status = response['msg'] ?? '';
          //    code = response['response_status_code'] ?? 0;

          if (status == 'OK') {
            await saveUser(Setup().user);
            Setup().hasLoggedIn = true;
            developer.log('Setup().user found and logged in', name: '_login');
            return status == 'OK';
          }
          developer.log('Setup().user found but NOT LOGGED IN', name: '_login');

          /// Have user details on device but not on server
          loginState = LoginState.register;
        }

        /// Device has no login details invite user to login
        User user = Setup().user;
        if ((Setup().user.email.isEmpty ||
                Setup().jwt.isEmpty ||
                Setup().user.password.isEmpty) &&
            mounted) {
          loginState = await loginDialog(context, user: user);

          if (loginState == LoginState.login) {
            Map<String, dynamic> response = await tryLogin(user: user);
            if (response['msg'] == 'OK') {
              developer.log('Login was successful', name: '_login');
              Setup().hasLoggedIn = true;
              await saveUser(user);
              Setup().user = user;
              return true;
            }
            // return false;
          } else if (loginState == LoginState.cancel) {
            return false;
          }
        }

        /// Handle partially loggedin users invite to complete registration
        if ([
          LoginState.register,
          LoginState.notLoggedin,
          LoginState.resetPassword
        ].contains(loginState)) {
          if (user.password.length != 6) {
            await postValidateUser(user: user);
            Setup().user = user;
            Setup().user.password = '';
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const SignupForm()),
            );
          }
        }

        /// Now handle login failures
        ///       New user both email and password empty  register
        /// 401 - Invalid password                        login dialog
        /// 410 - Missing password                        register
        /// 204 - Email not found                         register

        Setup().hasLoggedIn = true;
        return true; //critical one
      } else {
        debugPrint('Server not listening ($urlBase)');
        return false;
      }
      // return false;
    } catch (e) {
      debugPrint('Splash login error: ${e.toString()}');
      return false;
    }
  }

  Widget _getPortraitBody() {
    if (homeItems.isEmpty) {
      homeItems.add(HomeItem(
        id: -2,
        uri: 'assets/images',
        heading:
            'New trip planning app for individuals, groups of friends and clubs',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''Drives is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        imageUrls: '[{"url": "aiaston.png", "caption": ""}]',
      ));

      homeItems.add(
        HomeItem(
            id: -2,
            uri: 'assets/images',
            heading:
                'Share your trips with friends, club members or publish them to everybody',
            subHeading:
                'Let others know about your great trips, and download trips others have discovered already.',
            body:
                '''Uploaded trips can be rated to let you know how much others enjoyed it. Waypoints like scenery, nice roads, pubs and restaurants can be rated too.''',
            imageUrls:
                '[{"url": "meeting.png", "caption": ""}]'), //CarGroup.png'),
      );
    }

    return ListView(children: [
      const Card(
        child: Column(
          children: [
            SizedBox(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'Drives',
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
                ),
              ),
            ),
          ],
        ),
      ),
      for (int i = 0; i < homeItems.length; i++) ...[
        HomeTile(
          homeItem: homeItems[i],
          imageRepository: _imageRepository,
        )
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
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
          'Drives trip planning and sharing app',
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
