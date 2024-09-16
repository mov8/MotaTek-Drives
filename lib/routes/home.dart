import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/home_tile.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/web_helper.dart';
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
  late Future<bool> _dataLoaded;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = _getWebData();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<bool> _getWebData() async {
    await tryLoggingIn();
    return true;
  }

  tryLoggingIn() async {
    try {
      Map<String, dynamic> response = {'msg': 'Not logged in'};

      debugPrint('Splash message: ${response['msg']}');
      Future.delayed(const Duration(seconds: 4), () async {
        debugPrint('About to try logging in..');
        bool loaded = await Setup().loaded;

        if (loaded && Setup().jwt.isNotEmpty && Setup().user.email.isNotEmpty) {
          debugPrint('JWT not empty - about to try logging in..');
          response = await tryLogin(Setup().user.email, Setup().user.password);
        }
        if (response['msg'] != 'OK' && context.mounted) {
          debugPrint('tryLogin() failed About to use login()..');
          await login(context);
        }
      });
    } catch (e) {
      debugPrint('Splash login error: ${e.toString()}');
    }
  }

  Widget _getPortraitBody() {
    List<HomeItem> homeItems = [];
    homeItems.add(HomeItem(
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        imageUrl: 'assets/images/splash.png'));

    homeItems.add(HomeItem(
        heading: 'Share your trips',
        subHeading: 'Let others know about your beautiful trip',
        body: '''MotaTrip lets you enjoy trips other users have saved. 
You can also publish your trips for others to enjoy. You can invite a group of friends to share your trip and track their progress as they drive with you. You can rate pubs and other points of interest to help others enjoy their trip.
''',
        imageUrl: 'assets/images/CarGroup.png'));

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
                    fontSize: 28,
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
                    child: CircularProgressIndicator()));
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
