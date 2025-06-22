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
  final int _delaySecs = 4;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Builder(
        builder: (BuildContext context) => _getPortraitBody(),
      ),
    );
  }

  Widget _getPortraitBody() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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
