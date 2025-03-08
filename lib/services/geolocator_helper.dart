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
  final LocationSettings locationSettings;
  if (defaultTargetPlatform == TargetPlatform.android) {
    locationSettings = AndroidSettings(
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
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.automotiveNavigation,
      distanceFilter: distanceFilter,
      pauseLocationUpdatesAutomatically: true,
      // Only set to true if our app will be started up in the background.
      showBackgroundLocationIndicator: false,
    );
  } else if (kIsWeb) {
    locationSettings = WebSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      maximumAge: Duration(minutes: intervalSeconds),
    );
  } else {
    locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );
  }
  return locationSettings;
}
