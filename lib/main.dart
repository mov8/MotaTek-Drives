import 'package:drives/screens/create_trip_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'classes/classes.dart';
import '/services/services.dart'; // hide NavigationService;
import 'routes/routes.dart';
import 'dart:math';
import 'models/models.dart';
import 'package:flutter/gestures.dart';
import 'package:hive/hive.dart';
import '../constants.dart';

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

  Map<String, WidgetBuilder> appRoutes = {
    'splash': (BuildContext context) => const Splash(),
    '${routes[0]}': (BuildContext context) => const Home(),
    '${routes[1]}': (BuildContext context) => const MyTrips(), //Trips(),
    '${routes[2]}': (BuildContext context) => const Shop(), //CreateTrip(),
    '${routes[3]}': (BuildContext context) => const MyTrips(),
    '${routes[4]}': (BuildContext context) => const Shop(),
    '${routes[5]}': (BuildContext context) => Messages(),
  };

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

      /// Removing the initialRoute causes problems - don't !
      initialRoute: NavigationService().initialRoute,
      routes: appRoutes,

      builder: (context, child) {
        /// Persistent Map is MapLibre's recommendation so the Map is placed at the route of a Stack
        /// All other screens / Widgets are displayed over the top. For CreateTrip() / Trips() their
        /// Widgets are displayed via the CreateTripStack() widget. In the Web versions MyTrips(), and
        /// Messages are displayed in the SideBar. This has similar dimensions to a mobile's screen. The
        /// details are shown in the remaining 2/3 of the screen.
        /// The web version only can do the admin tasks like changing shop and home contents

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

            /// The child is the Navigator widget that contains all screens to
            /// which the test scaling will be applied
            child: AppMasterShell(
                content: child!,
                controller: MapService().appMasterShellController),
          ),
        );
      },
    ),
  ); //);
}

CreateTripStackController _createTripStackController =
    CreateTripStackController();

/// AppMasterShell allows the WebAppBar, MLMap, SideDrawer and StatusBar to be available

class AppMasterShellController {
  _AppMasterShellState? _appMasterShellState;
  void _addState(_AppMasterShellState appMasterShellState) {
    _appMasterShellState = appMasterShellState;
  }

  bool get isAttached => _appMasterShellState != null;
  void update() {
    _appMasterShellState?.update();
  }
}

class AppMasterShell extends StatefulWidget {
  final AppMasterShellController? controller;
  final Widget content;
  const AppMasterShell({super.key, required this.content, this.controller});
  @override
  State<AppMasterShell> createState() => _AppMasterShellState();
}

class _AppMasterShellState extends State<AppMasterShell> {
  final PageStorageBucket _shellStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  void update() => setState(() => ());

  @override
  Widget build(BuildContext context) {
    /// The whole app rebuilds if the browser size changes so have to make
    /// sure the controllers don't get re-instantiated when the browser re-sizes
    MapService().webAppBarController ??= WebAppBarController();
    MapService().sideDrawerController ??= SideDrawerController();
    MapService().statusBarController ??= StatusBarController();
    MapService().bottomDrawerController ??= BottomDrawerController();
    MapService().routesBottomNavController ??= RoutesBottomNavController();
    MapService().createTripStackController ??= CreateTripStackController();
    MapService().homeController ??= HomeController();
    MapService().shopController ??= ShopController();
    MapService().appMasterShellController ??= AppMasterShellController();

    double sideDrawerOpenWidth = 0.4;
    return Scaffold(
      body: PageStorage(
        // <-- has to be added because outside Navigation
        bucket: _shellStorageBucket,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Column(children: [
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
              child: Stack(children: [
                FutureBuilder(
                  future: MapService().style, // <- ensure the style is loaded
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      developer.log('Error getting style', name: 'error');
                    } else if (snapshot.hasData) {
                      try {
                        MapLibreMap map = MapLibreMap(
                          key: MapService().mapKey,
                          styleString: snapshot.data!,
                          compassViewPosition: CompassViewPosition.topLeft,
                          onMapCreated: _onMapUpdated,
                          initialCameraPosition: CameraPosition(
                              target: LatLng(
                                  MapService().currentPosition.latitude,
                                  MapService().currentPosition.longitude),
                              zoom: 11),
                          trackCameraPosition: true,
                          onCameraMove: _onCameraMove,
                          onMapClick: _onTap,
                          onCameraIdle: _onCameraIdle,
                          scrollGesturesEnabled: true,
                          onStyleLoadedCallback: () => _onStyleLoaded(),
                          zoomGesturesEnabled: true,
                          gestureRecognizers: Set()
                            ..add(
                              Factory<EagerGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            ),
                        );
                        return GestureDetector(onLongPress: () {}, child: map);
                      } catch (e) {
                        developer.log('Error building map: ${e.toString()}',
                            name: 'error');
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
                Align(
                  alignment: Alignment.bottomLeft,
                  child: StatusBar(
                    controller: MapService().statusBarController,
                  ),
                ),
                CreateTripStack(), // <-- all non-page overlays
                if (!NavigationService().isWidget) ...[
                  widget.content,
                  if (kIsWeb)
                    SideDrawer(
                      width: sideDrawerOpenWidth,
                      context: context,
                      controller: MapService().sideDrawerController,
                      mapController: MapService().controller,
                      webAppBarController: MapService().webAppBarController,
                    ),
                ],

                //    if (!NavigationService().showSplash)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 105,
                  child: Material(
                    child: Overlay(
                      // <-- has to be added because outside Navigation
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) => Material(
                            //  key: NavigationService().uiKey,
                            type: MaterialType.transparency,
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: StackNavBar(index: 0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

/* 
class AppMasterShell extends StatefulWidget {
  final AppMasterShellController? controller;
  final Widget content;
  const AppMasterShell({super.key, required this.content, this.controller});
  @override
  State<AppMasterShell> createState() => _AppMasterShellState();
}

class _AppMasterShellState extends State<AppMasterShell> {
  final PageStorageBucket _shellStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  void update() => setState(() => ());
*/
/*
class ShellBody extends StatefulWidget {
  final ShellBodyController? controller;
  const ShellBody({super.key, this.controller});
  @override
  State<ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<ShellBody> {
  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  void update() => setState(() => ());
}
*/
void _onStyleLoaded() async {
  await MapService().controller!.moveCamera(
        CameraUpdate.newLatLngZoom(
          MapService().currentPosition,
          12.0,
        ),
      );
}

void _onMapUpdated(MapLibreMapController controller) async {
  MapService().setMapController(controller);
  if (MapService().statusBarController != null) {
    MapService().statusBarController!.refresh();
  }
  _createTripStackController.refresh();
}

void _onTap(Point<double> point, LatLng coordinates) async {
  MapService().onTap(point, coordinates);
}

void _onCameraIdle() async {
  MapService().onIdle();
}

void _onCameraMove(CameraPosition position) async {
  MapService().onCameraMove(position);
}
