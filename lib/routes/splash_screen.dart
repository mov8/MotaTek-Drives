import 'dart:async';
import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drives/models/models.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late Future<bool> _setupOk;
  int _delaySecs = 4;

  @override
  void initState() {
    super.initState();
    _setupOk = setupLoaded();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    //_setupOk = Setup().loaded;
    Future.delayed(Duration(seconds: _delaySecs), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      int routeIndex = Setup().bottomNavIndex;
      if (routeIndex != 0) {
        Setup().bottomNavIndex = 0;
        Setup().setupToDb();
      }
      //  routeIndex = 4;
      if (mounted) {
        Navigator.pushNamed(context, routes[routeIndex]);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> setupLoaded() async {
    await Setup().loaded;
    if (Setup().bottomNavIndex != 0) {
      _delaySecs = 1;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Customize background color

/* 
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
*/

      body: FutureBuilder<bool>(
        future: _setupOk,
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
      /*
      bottomNavigationBar: RoutesBottomNav(
          controller: _bottomNavController,
          initialValue: 0,
          onMenuTap: (_) => {}),
      */
    );
  }

  Widget _getPortraitBody() {
    return const Stack(children: [
      Image(
        image: AssetImage('assets/images/splash.png'),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
      ),
      Positioned(
        top: 50,
        left: 120,
        child: Text(
          'Drives',
          style: TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Positioned(
        top: 700,
        left: 140,
        child: Text(
          'Explore your world',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
    ]);
  }
}
