import 'package:drives/classes/create_trip_stack.dart';
import 'package:drives/helpers/edit_helpers.dart';
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
import 'package:path_provider/path_provider.dart';
import '/screens/login_screen.dart';
import '/screens/import_export.dart';
import '/helpers/helpers.dart';

/// Don't want these to be recreated on every build
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final splashBranchKey = GlobalKey<NavigatorState>(debugLabel: 'splash');
final homeBranchKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final publishedBranchKey = GlobalKey<NavigatorState>(debugLabel: 'published');
final mapBranchKey = GlobalKey<NavigatorState>(debugLabel: 'trips');
final myTripsBranchKey = GlobalKey<NavigatorState>(debugLabel: 'myTrips');
final shopBranchKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final messagesBranchKey = GlobalKey<NavigatorState>(debugLabel: 'messages');
final loginBranchKey = GlobalKey<NavigatorState>(debugLabel: 'login');
final transferBranchKey = GlobalKey<NavigatorState>(debugLabel: 'transfer');
void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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

/// GoRouter simplifies the navigation. A StatefulSell.indexedStack requires a base page
/// BaseShellScreen() over which the other screens displayed in a Stack.
/// 3 Methods for navigating between screens:
///   1 context.go('/screen') Replaces the whole navigation stack - top-level navigation
///   2 context.push('/screen') Pushes onto the stack - can then use pop to go back
///   3 context.pushReplacement('/screen') for one-off transition ie. from login screen to home screen
///
///  TODO:  In reality the whole app should be restructured as a single map screem with a persistant appBar
///         and bottomNav. The only thing that needs to change is the body. It would simplify the whole app.
///

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BaseShellScreen(
          navigationShell: navigationShell,
          controller: MapService().baseShellController,
        );
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
          navigatorKey: publishedBranchKey,
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) =>
                  const CreateTrip(mapType: 'published'),
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
      pageBuilder: (context, state) {
        return const MaterialPage(
          fullscreenDialog: true, // Native modal transition
          child: LoginScreen(), // Rebuilt fresh every time
        );
      },
    ),

    /// Below is an example of how to pass an object with go_router
    /// There are 3 ways to pass data between screens
    ///   1 passing a simple parameter
    ///   2 reading parameters from the url context.go('/screen?id=5&colour=black)
    ///   3 sending objects using the state.extra method see below
    /// https://verygood.ventures/blog/routing-best-practices-in-flutter/
    GoRoute(
      path: '/transfer',
      name: 'source',
      pageBuilder: (context, state) {
        if (state.extra != null) {
          final tripItem = state.extra! as MyTripItem;
          return MaterialPage(
              fullscreenDialog: true, child: ImportExport(tripItem: tripItem));
        } else {
          return const MaterialPage(
              fullscreenDialog: true, child: ImportExport());
        }
      },
    ),
  ],
);

class BaseShellController {
  _BaseShellScreen? _baseShellScreen;
  void _addState(_BaseShellScreen shellState) {
    try {
      _baseShellScreen = shellState;
    } catch (e) {
      developer.log('Error attaching BaseShellScreen state: ${e.toString()}',
          name: 'error');
    }
  }

  bool get isAttached => _baseShellScreen != null;
}

class BaseShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final BaseShellController? controller;
  const BaseShellScreen(
      {super.key, required this.navigationShell, this.controller});
  @override
  State<BaseShellScreen> createState() => _BaseShellScreen();
}

class _BaseShellScreen extends State<BaseShellScreen> {
  int currentPageIndex = 0;
  late List<Widget> destinations;
  late Future<bool> initialised;
  @override
  void initState() {
    super.initState();
    widget.controller!._addState(this);

    MapService().webAppBarController ??= WebAppBarController();
    MapService().sideDrawerController ??= SideDrawerController();
    MapService().statusBarController ??= StatusBarController();
    MapService().bottomDrawerController ??= BottomDrawerController();
    MapService().routesBottomNavController ??= RoutesBottomNavController();
    MapService().createTripStackController ??= CreateTripStackController();
    MapService().homeController ??= HomeController();
    MapService().shopController ??= ShopController();
    MapService().fabsController ??= FabsController();
    MapService().baseShellController ??= BaseShellController();
    MapService().bottomNavController ??= BottomNavController();
    MapService().createTripController ??= CreateTripController();
    MapService().persistentAppBarController ??= PersistentAppBarController();
    initialised = initialise();
  }

  @override
  Widget build(BuildContext context) {
    MapService().createTripController ??= CreateTripController();
    return Scaffold(
      appBar: PersistentAppBar(
          controller: MapService().persistentAppBarController!),
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
      bottomNavigationBar: BottomNav(
          controller: MapService().bottomNavController,
          navigationShell: widget.navigationShell),
    );
  }

  /// initialise() loads the MapLibre style from the api, loads the data into Setup() using
  /// Setup().loaded, and initialises the Hive database, and initialises the web specific
  /// UI starting conditions through controllers. All this should happen when the
  /// Splash screen is displayed

  Future<bool> initialise() async {
    bool loaded = await MapService().loadStyle();
    if (kIsWeb) {
      MapService().webAppBarController?.showControls();
      MapService().sideDrawerController?.setFixed(fixed: true);
      MapService().sideDrawerController?.open();
      MapService().sideDrawerController?.setVisible(visible: true);
    }
    try {
      // Setup().loaded gets jwt from SecureStorage and gets user and Setup() data from Hive
      Setup().loaded;
      await Hive.initFlutter(Setup().appDocumentDirectory);
    } catch (e) {
      developer.log(
          'Main().initialise() Hive.initFlutter() error: ${e.toString()}',
          name: 'error');
    }
    return true;
  }
}

/// PersistentAppBar is to solve the problem of GoRouters StatefulBranch that makes the branch pages
/// persist. Changing the appBar UI is problematic so only solution was creating a persistent appBar
/// that mirrors the BottomNav. Now only the body of the pages are built for each page.

class PersistentAppBarController {
  _PersistentAppBarState? _persistentAppBarState;
  void _addState(_PersistentAppBarState navState) {
    try {
      _persistentAppBarState = navState;
    } catch (e) {
      developer.log('error attaching BottomNav().controller: ${e.toString}',
          name: 'error');
    }
  }

  bool _isAttached() => _persistentAppBarState != null;

  void update(String title) {
    if (_isAttached()) {
      _persistentAppBarState?.update(title);
    }
  }
}

class PersistentAppBar extends StatefulWidget implements PreferredSizeWidget {
  final PersistentAppBarController controller;
  final int page;
  final String heading;
  final String subheading;
  final Function(dynamic)? callback;
  const PersistentAppBar(
      {super.key,
      required this.controller,
      this.page = 0,
      this.heading = 'Heading',
      this.subheading = 'Subheading',
      this.callback});
  @override
  State<PersistentAppBar> createState() => _PersistentAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PersistentAppBarState extends State<PersistentAppBar> {
  final LeadingWidgetController _leadingWidgetController =
      LeadingWidgetController();

  void _leadingWidget(context) {
    context?.openDrawer();
    return;
  }

  late int _tileSelected;
  String _title = 'Drives community';
  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _tileSelected = 0;
  }

  void update(String title) {
    setState(() => _title = title.isNotEmpty ? title : _title);
  }

  /// 0 = none
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: false,
      leading: LeadingWidget(
        controller: _leadingWidgetController,
        onMenuTap: (index) =>
            _leadingWidget(context), //_scaffoldKey.currentState),
      ), // IconButton(
      title: Text(
        _title, //NavigationService().heading,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (widget.page == 2)
          IconButton(
            onPressed: () {
              context.push('/transfer');
            },
            icon: Icon(
              Icons.import_export_outlined,
              size: 35,
            ),
          ),
        if (widget.page == 5) ...[
          if (Setup().jwt.isNotEmpty) ...[
            if (_tileSelected == -1) ...[
              IconButton(
                  icon: Icon(Icons.person_add_outlined, size: 30),
                  onPressed: () => widget.callback!(true)),
              IconButton(
                  onPressed: () => {},
                  icon: Icon(Icons.help_outline_outlined, size: 35)),
            ],
          ],
        ],
        IconButton(
          onPressed: () => {
            if (Setup().jwt.isEmpty) {context.push('/login')},
          },
          icon: Icon(
            Setup().jwt.isEmpty
                ? Icons.no_accounts_outlined
                : Icons.account_circle_outlined,
            size: 35,
          ),
        )
      ],
    );
  }
}

class BottomNavController {
  _BottomNavState? _bottomNavState;
  void _addState(_BottomNavState navState) {
    try {
      _bottomNavState = navState;
    } catch (e) {
      developer.log('error attaching BottomNav().controller: ${e.toString}',
          name: 'error');
    }
  }

  bool _isAttached() => _bottomNavState != null;

  void update() {
    if (_isAttached()) {
      _bottomNavState?.update();
    }
  }

  void setHighlight(int value) {
    if (_isAttached()) {
      _bottomNavState!.setHighlight(value);
    }
  }
}

class BottomNav extends StatefulWidget {
  StatefulNavigationShell navigationShell;
  BottomNavController? controller;
  BottomNav({super.key, this.controller, required this.navigationShell});
  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late final List<Widget> destinations;
  late int currentPageIndex;
  @override
  initState() {
    super.initState();
    widget.controller?._addState(this);
    destinations = [
      for (int i = 0; i < 6; i++) _navigationDestination(index: i)
    ];
    currentPageIndex = 0;
  }

  void update() {
    setState(() => {});
  }

  void setHighlight(int value) {
    currentPageIndex = value;
  }

  final List<String> _titles = [
    'Drives community',
    'Published trips',
    'Explore',
    'My favourites',
    'Marketplace',
    'Messages'
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentPageIndex,
      onDestinationSelected: (int index) {
        widget.navigationShell.goBranch(index,
            initialLocation: index == widget.navigationShell.currentIndex);
        int titleIndex = index; // > 1 ? ++index : index;
        MapService().persistentAppBarController?.update(_titles[titleIndex]);
        NavigationService().selected(index);
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
}
