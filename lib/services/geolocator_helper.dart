import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geolocator_android/geolocator_android.dart';
// import 'package:geolocator_android/geolocator_web.dart';
// import 'package:geolocator_apple/geolocator_apple.dart';

LocationSettings getGeolocatorSettings(
    {required TargetPlatform defaultTargetPlatform,
    distanceFilter = 100,
    intervalSeconds = 10,
    kIsWeb = false}) {
  if (kIsWeb) {
    return WebSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      maximumAge: Duration(minutes: intervalSeconds),
    );
  } else {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          forceLocationManager: true,
          intervalDuration: Duration(seconds: intervalSeconds),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }
    //  return locationSettings;
  }
}
