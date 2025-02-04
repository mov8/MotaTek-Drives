import 'package:flutter/material.dart';
import 'package:drives/routes/routes.dart';

/*
https://techblog.geekyants.com/implementing-flutter-maps-with-osm     /// Shows how to implement markers and group them
https://stackoverflow.com/questions/76090873/how-to-set-location-marker-size-depend-on-zoom-in-flutter-map      
https://pub.dev/packages/flutter_map_location_marker
https://github.com/tlserver/flutter_map_location_marker
https://www.appsdeveloperblog.com/alert-dialog-with-a-text-field-in-flutter/   /// Shows text input dialog
https://fabricesumsa2000.medium.com/openstreetmaps-osm-maps-and-flutter-daeb23f67620  /// tapableRouteLayer  
https://github.com/OwnWeb/flutter_map_tappable_Route/blob/master/lib/flutter_map_tappable_Route.dart
https://pub.dev/packages/flutter_map_animations/example  shows how to animate markers too
*/

void main() {
  runApp(
    // debugInvertOversizedImages = true;
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'splash',
      routes: {
        'splash': (BuildContext context) => const Splash(),
        'home': (BuildContext context) => const Home(),
        'trips': (BuildContext context) => const Trips(),
        'createTrip': (BuildContext context) => const CreateTrip(),
        'myTrips': (BuildContext context) => const MyTrips(),
        'shop': (BuildContext context) => const Shop(),
        'messages': (BuildContext context) => const Messages(),
      },
    ),
  );
}
