import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drives/main.dart';
import 'package:flutter/services.dart'; // Import your main app file

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyHomePage()));
    });

    // Navigate to the main screen after 3 seconds
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue, // Customize background color
      body: Stack(children: [
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
          child: Text('MotaTrip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
              )),
        ),
        Positioned(
          top: 700,
          left: 170,
          child: Text('Explore your world',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              )),
        )
      ]),
    );
  }
}
