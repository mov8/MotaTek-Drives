import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drives/main.dart'; // Import your main app file

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _homeState();
}

class _homeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Center(
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
            height: 300, //MediaQuery.of(context).size.height, //400,
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
// Replace 'MyApp' with your main app widget
                // });

                // Navigator.pop(context, buttonTexts[i]);
                //  Navigator.of(context).pop(buttonTexts[i]);
              })
        ],
      ),
    );
  }
}
