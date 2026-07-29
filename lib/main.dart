import 'package:drives/screens/create_trip_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'classes/classes.dart' hide NavigationService, Route;
import '/services/services.dart'; // hide NavigationService;
import 'routes/routes.dart';
import 'dart:math';
import 'models/models.dart';
import 'package:flutter/gestures.dart';
import 'package:hive/hive.dart';
import '../constants.dart';

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
  await Hive.initFlutter();
  await Setup().loaded;
  Setup().hasLoggedIn = Setup().jwt.isNotEmpty;
  var currentTripBox = await Hive.openBox('currentTrip');

  debugPrint('Setup().user.surname ${Setup().user.surname}');
  final CreateTripController createTripController = CreateTripController();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // if (kIsWeb) {
  //   Setup().webAppBarController = WebAppBarController();
  // }
  runApp(
    MaterialApp(
      navigatorKey: NavigationService().key,
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
          scaffoldBackgroundColor: backgroundColour, // Colors.blue,
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

      onGenerateRoute: Routes.generateRoute,
/*
      routes: {
        'splash': (BuildContext context) => const Splash(), // Shop(),
        'home': (BuildContext context) => const Home(),
        //    'trips': (BuildContext context) => const Trips(),
        'createTrip': (BuildContext context) =>
            CreateTrip(controller: createTripController),
        'myTrips': (BuildContext context) => const MyTrips(),
        'shop': (BuildContext context) => const Shop(),
        'messages': (BuildContext context) => Messages(),
      },
      */
      builder: (context, child) {
        /// Had a real issue with the map getting gestures in the Stack structure. For some reason the Scaffold
        /// in pages blocked the gestures in Android version. The only way round it was to implement the two map pages
        /// as vanilla Widgets. The Route for the Home, Shop, and Messages are displayed as normal.
        UIStateService().setPage(Setup().appState.isEmpty ? 1 : 0);
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
            child: AppMasterShell(
              content: child!,
            ), //    child!,
          ),
        );
      },
    ),
  ); //);
}

/// Routes class allows the generation of Routes. The reason it's used
/// is partly because it's more modular, but also it allows the generation
/// of a page from a scaffold-free class, as the inclusion of the scaffold
/// stops the gestures from the map reaching the map as the map is at the
/// bottom of a Stack

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'splash':
        return MaterialPageRoute(builder: (_) => Splash());
      case 'home':
        return MaterialPageRoute(builder: (_) => Home());
      case 'trips' || 'createTrip':
        return MaterialPageRoute(builder: (_) => CreateTrip());
      /* return PageRouteBuilder(
            opaque: false,
            barrierColor: null,
            settings: settings,
            pageBuilder: (
              context,
              _,
              __,
            ) =>
                const CreateTripStack(),
            transitionsBuilder: (context, anim, _, child) => FadeTransition(
                  opacity: anim,
                  child: child,
                )); */
      case 'myTrips':
        return MaterialPageRoute(builder: (_) => MyTrips());
      case 'shop':
        return MaterialPageRoute(builder: (_) => Shop());
      case 'messages':
        return MaterialPageRoute(builder: (_) => Messages());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for \${settings.name}'),
            ),
          ),
        );
    }
  }
}

enum AppDisplayMode { mapOverlay, navigator }

class UIStateService extends ChangeNotifier {
  static final UIStateService _instance = UIStateService._internal();
  factory UIStateService() => _instance;
  UIStateService._internal();

  int _page = 0;
  int get page => _page;

  void setPage(int newPage) {
    if (_page == newPage) return;
    _page = newPage;

    // THIS IS THE MISSING LINK:
    // It tells Flutter to look at every widget listening to this class
    notifyListeners();
  }

  AppDisplayMode displayMode = AppDisplayMode.mapOverlay;

  void setMode(AppDisplayMode mode) {
    if (displayMode == mode) return;
    displayMode = mode;
    notifyListeners();
  }
}

/// AppMasterShell allows the WebAppBar, MLMap, SideDrawer and StatusBar to be available
/// throughout the whole app, as they're instantiated before the navigation.
/// All references to the WebAppBar, MapLibreMap and controllers are held in the MapService() singleton
/// to make them accessible throughout the app. All these Widgets should remain in the tree
/// unmodified come-what-may.
/// * Note: There is an PopupMenu issue with Widgets instantiated outside the Navigator
///         The Navigator provides the target for the menus, so a Widget built outside
///         the Navigator has nowhere to put the menu. Look at WebAppBar for the solution
///         based on accessing and using the main Navigator's GlobalKey which is held in the
///         NavigationService() singleton to allow the WebAppBar and SideDrawer objects
///         to render widgets outside their Navigator boundaries - see PopupMenu implementations
///         in both WebAppBar and side drawer.

class AppMasterShell extends StatelessWidget {
  final Widget content;
  AppMasterShell({super.key, required this.content});
  final PageStorageBucket _shellStorageBucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    /// The whole app rebuilds if the browser size changes so have to make
    /// sure the controllers don't get re-instantiated when the browser re-sizes
    MapService().webAppBarController ??= WebAppBarController();
    MapService().sideDrawerController ??= SideDrawerController();
    MapService().statusBarController ??= StatusBarController();
    developer.log(
        'AppMasterShell().build() called MapService().page: ${MapService().page}',
        name: '_map_');
    double sideDrawerOpenWidth = 0.4;
    return Scaffold(
        body:

            // ListenableBuilder(
            //   listenable: UIStateService(),
            //   builder: (context, _) {
            //     final mode = UIStateService().displayMode;
            // final mode = AppDisplayMode.navigator;
            //     return
            PageStorage(
      // <-- has to be added because outside Navigation
      bucket: _shellStorageBucket,
      child: Column(
        children: [
          if (kIsWeb) ...[
            Expanded(
              flex: 2,
              child: WebAppBar(
                context: context,
                appBarController: MapService().webAppBarController,
                sideDrawerController: MapService().sideDrawerController,
                statusBarController: MapService().statusBarController,
              ),
            ),
          ],
          Expanded(
            flex: 12,
            child: Stack(
              children: [
                FutureBuilder(
                  future: MapService().style, // <- ensure the style is loaded
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      developer.log('Error getting style', name: '_map_');
                    } else if (snapshot.hasData) {
                      try {
                        MapLibreMap map = MapLibreMap(
                          key: MapService().mapKey,
                          styleString: snapshot.data!,
                          compassViewPosition: CompassViewPosition.topLeft,
                          onMapCreated: _onMapUpdated,
                          initialCameraPosition: CameraPosition(
                              target: MapService().currentPosition, zoom: 11),
                          trackCameraPosition: true,
                          onCameraMove: _onCameraMove,
                          onMapClick: _onTap,
                          onCameraIdle: _onCameraIdle,
                          scrollGesturesEnabled: true,
                          onStyleLoadedCallback: () => _onStyleLoaded(),
                          zoomGesturesEnabled: true,
                          gestureRecognizers: <Factory<
                              OneSequenceGestureRecognizer>>{
                            Factory<PanGestureRecognizer>(
                                () => PanGestureRecognizer()),
                            Factory<EagerGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                            Factory<ScaleGestureRecognizer>(
                                () => ScaleGestureRecognizer()),
                            Factory<TapGestureRecognizer>(
                                () => TapGestureRecognizer()),
                            Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer())
                          },
                        );
                        return map;
                      } catch (e) {
                        developer.log('Error building map: ${e.toString()}',
                            name: '_map_');
                      }
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return Center(
                      child: Text(
                        'Map not available - \nplease check your Internet connection',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                // Text('Map should have buit',
                //     style: TextStyle(fontSize: 25, color: Colors.black)),

                Align(
                  alignment: Alignment.bottomLeft,
                  child: StatusBar(
                    controller: MapService().statusBarController,
                  ),
                ),

                ListenableBuilder(
                  listenable:
                      UIStateService(), // Flutter now "watches" your singleton
                  builder: (context, _) {
                    final currentPage = UIStateService().page;
                    developer.log(
                        'AppMasterShell() setting currentPage: $currentPage',
                        name: '_map_');
                    if (currentPage == 0 && !kIsWeb) {
                      // If page is 0, the Navigator is REMOVED from the tree.
                      // The "Glass Wall" is gone. Map gestures will work!
                      return const CreateTripStack();
                    } else {
                      // If page is 1, show the Navigator (Shop, Home, etc.)
                      return content;
                    }
                  },
                ),
                if (kIsWeb) ...[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Overlay(
                      // <-- has to be added because outside Navigation
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) => Material(
                            type: MaterialType.transparency,
                            child: SideDrawer(
                              width: sideDrawerOpenWidth,
                              context: context,
                              controller: MapService().sideDrawerController,
                              mapController: MapService().controller,
                              webAppBarController:
                                  MapService().webAppBarController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        //   },
        //  ),
        );
  }
}

void _onStyleLoaded() async {
  developer.log('main.dart _onStyleLoaded() called', name: '_map_');
  await MapService().controller!.moveCamera(
        CameraUpdate.newLatLngZoom(
          MapService().currentPosition,
          12.0,
        ),
      );
}

void _onMapUpdated(MapLibreMapController controller) async {
  MapService().controller = controller;
  developer.log('main.dart _onMapUpdated() called', name: '_map_');
  if (MapService().statusBarController != null) {
    MapService().statusBarController!.refresh();
  }
}

void _onTap(Point<double> point, LatLng coordinates) async {
  developer.log('main.dart _onTap() called', name: '_map_');
  MapService().onTap(point, coordinates);
  // nwidget.onTap!(point, coordinates);
}

void _onCameraIdle() async {
  MapService().onIdle();
}

void _onCameraMove(CameraPosition position) async {
  MapService().onCameraMove(position);
}
