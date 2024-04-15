import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drives/main.dart'; // Import your main app file

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main screen after 3 seconds
    /*   Timer(const Duration(seconds: 3), () {
      Navigator.push(
        //Replacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MyApp()), // Replace 'MyApp' with your main app widget
      );
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue, // Customize background color
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MotaTrip',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Trip Planner',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Image.asset(
                  'assets/images/splash.png',
                  // width: 500,
                  height: 200, //MediaQuery.of(context).size.height, //400,
                ),
                const SizedBox(height: 24),
                TextButton(
                    style: TextButton.styleFrom(
                      elevation: 5,
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: const Color.fromARGB(255, 204, 224, 241),
                      textStyle: const TextStyle(fontSize: 30),
                    ),
                    child: Text('Plan your Escape...',
                        style: Theme.of(context).textTheme.bodyLarge!),
                    onPressed: () {
                      // Navigator.pop(context, buttonTexts[i]);
                      //  Navigator.of(context).pop(buttonTexts[i]);
                    })
              ],
            ),
          ),
        ));
  }
}
