import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:path_provider/path_provider.dart';
import 'routes/routes.dart';
import 'models/models.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <- needed to allow await to work
  await Setup().loaded;
  Setup().hasLoggedIn = false;
  debugPrint('Setup().user.surname ${Setup().user.surname}');
  final CreateTripController createTripController = CreateTripController();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // https://docs.flutter.dev/cookbook/design/themes
      // theme: ThemeData.light(),
      // flutter pub add google_fonts
      // import "package:google_fonts/google_fonts.dart";
      // textTheme: GoogleFonts.rubikBubblesTextTheme(),
      ///        Theme.of(context).textTheme.bodyLarge,
      // theme: ThemeData(
      //     primarySwatch: Colors.indigo,
      //     scaffoldBackgroundColor: Colors.blueGrey,
      //     textTheme: TextTheme()),
      // darkTheme: ThemeData.dark(),
      // themeMode: ThemeMode.system, //light,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          useSystemColors: true,
          scaffoldBackgroundColor: Colors.blue,
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Colors.transparent,
          ),
          textTheme: TextTheme(
            headlineLarge: const TextStyle(
                fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
            headlineMedium: const TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            headlineSmall: const TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            titleLarge: const TextStyle(fontSize: 24, color: Colors.white),
            titleMedium: const TextStyle(fontSize: 20, color: Colors.white),
            titleSmall: const TextStyle(fontSize: 16, color: Colors.white),
            bodyLarge: const TextStyle(fontSize: 24, color: Colors.white),
            bodyMedium: const TextStyle(fontSize: 20, color: Colors.white),
            bodySmall: const TextStyle(fontSize: 16, color: Colors.white),
            labelLarge: const TextStyle(fontSize: 24, color: Colors.white),
            labelMedium: const TextStyle(fontSize: 20, color: Colors.white),
            labelSmall: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          appBarTheme: const AppBarTheme(
            // This ensures the status bar icons are light (for a dark app bar)
            systemOverlayStyle: SystemUiOverlayStyle.light,
          )),

      initialRoute: Setup().appState.isEmpty ? 'splash' : 'createTrip',
      routes: {
        'splash': (BuildContext context) => const Splash(), // Shop(),
        'home': (BuildContext context) => const Home(),
        'trips': (BuildContext context) => const Trips(),
        'createTrip': (BuildContext context) =>
            CreateTrip(controller: createTripController),
        'myTrips': (BuildContext context) => const MyTrips(),
        'shop': (BuildContext context) => const Shop(),
        'messages': (BuildContext context) => const Messages(),
      },
      builder: (context, child) {
        // Wrap the entire app in AnnotatedRegion and MediaQuery for colour and font scaling
        return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light, // For iOS
              // the order of the contrast and the colour may be critical.
              systemStatusBarContrastEnforced: false,
              statusBarColor: Colors.blue,
              // The next line doesn't make any difference
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarColor: Colors.blue,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(0.9)),
              // The child is the Navigator widget that contains all screens to which the test scaling will be applied
              child: child!,
            ));
      },
    ),
  ); //);
}
