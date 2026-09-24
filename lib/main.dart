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
import 'package:go_router/go_router.dart';
import '../constants.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/screens/login_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final splashBranchKey = GlobalKey<NavigatorState>(debugLabel: 'splash');
final homeBranchKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final mapBranchKey = GlobalKey<NavigatorState>(debugLabel: 'trips');
final myTripsBranchKey = GlobalKey<NavigatorState>(debugLabel: 'myTrips');
final shopBranchKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final messagesBranchKey = GlobalKey<NavigatorState>(debugLabel: 'messages');

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // FlutterNativeSplash.remove();
  // initialise().then(() =>
  runApp(const MyApp()); //);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MapLibre Web App',
      routerConfig:
          appRouter, // Injects your clean browser navigation configuration
    );
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BaseShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: homeBranchKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Home(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: mapBranchKey,
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const CreateTrip(mapType: 'explore'),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: myTripsBranchKey,
          routes: [
            GoRoute(
              path: '/myTrips',
              builder: (context, state) => const MyTrips(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shopBranchKey,
          routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => const Shop(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: messagesBranchKey,
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => Messages(),
            ),
          ],
        )
      ],
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: rootNavigatorKey, // Covers shell & nav bar
      pageBuilder: (context, state) {
        return const MaterialPage(
          fullscreenDialog: true, // Native modal transition
          child: LoginScreen(), // Rebuilt fresh every time
        );
      },
    )
  ],
);

class BaseShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  BaseShellScreen({
    super.key,
    required this.navigationShell,
  });
  @override
  State<BaseShellScreen> createState() => _BaseShellScreen();
}

class _BaseShellScreen extends State<BaseShellScreen> {
  int currentPageIndex = 0;
  @override
  late List<Widget> destinations;
  late Future<bool> initialised;
  @override
  void initState() {
    super.initState();
    destinations = [
      for (int i = 0; i < 6; i++) _navigationDestination(index: i)
    ];
    MapService().webAppBarController ??= WebAppBarController();
    MapService().sideDrawerController ??= SideDrawerController();
    MapService().statusBarController ??= StatusBarController();
    MapService().bottomDrawerController ??= BottomDrawerController();
    MapService().routesBottomNavController ??= RoutesBottomNavController();
    MapService().createTripStackController ??= CreateTripStackController();
    MapService().homeController ??= HomeController();
    MapService().shopController ??= ShopController();
    MapService().fabsController ??= FabsController();
    initialised = initialise();
  }

  @override
  Widget build(BuildContext context) {
    MapService().createTripController ??= CreateTripController();
    return Scaffold(
      body: FutureBuilder<bool>(
          future: initialised,
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              developer.log('Snapshot error: ${snapshot.error}', name: 'error');
              return Center(
                  child: Text(
                      'Error getting the data from the server - check the Internet'));
            } else if (snapshot.hasData) {
              return widget.navigationShell;
            } else {
              return const SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }),

      // widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          final int pageIndex = NavigationService().destination(index);
          widget.navigationShell.goBranch(pageIndex,
              initialLocation: index == widget.navigationShell.currentIndex);
          setState(() => currentPageIndex = index);
        },
        surfaceTintColor: Colors.blue,
        indicatorColor: Colors.lightBlue,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            // If the tab is currently selected:
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              );
            }
            // Default style for unselected tabs:
            return const TextStyle(
              fontSize: 10,
              color: Colors.deepPurple,
            );
          },
        ),
        destinations: destinations,
      ),
    );
  }

  NavigationDestination _navigationDestination(
      {required int index, badgeValue = 0}) {
    if (badgeValue == 0) {
      return NavigationDestination(
        selectedIcon: Icon(
          routeNavIconsSelected[index],
        ),
        icon: Icon(
          routeNavIcons[index],
        ),
        label: routeNavLabels[index],
      );
    } else {
      return NavigationDestination(
        icon: Badge(
          label: Text(badgeValue
              .toString()), // _messages.isEmpty ? null : Text(_messages.length.toString()),
          child: Icon(
            routeNavIcons[index],
          ),
        ),
        selectedIcon: Badge(
          label: Text(
            badgeValue.toString(),
          ),
          child: Icon(
            routeNavIconsSelected[index],
          ),
        ),
        label: routeNavLabels[index],
      );
    }
  }

  Future<bool> initialise() async {
    await MapService().loadStyle();
    if (kIsWeb) {
      MapService().webAppBarController?.showControls();
      MapService().sideDrawerController?.setFixed(fixed: true);
      MapService().sideDrawerController?.open();
      MapService().sideDrawerController?.setVisible(visible: true);
    }
    try {
      Setup().loaded;
      /*
      if (Setup().jwt.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreen(user: Setup().user)),
        );
      }
      */
    } catch (e) {
      debugPrint('Error starting local database: ${e.toString()}');
    }
    return true;
  }
}
