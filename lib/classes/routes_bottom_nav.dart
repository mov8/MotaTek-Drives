import 'package:drives/classes/other_classes.dart';
import 'package:drives/screens/create_trip_stack.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '/main.dart';
import '/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

class RoutesBottomNavController {
  _RoutesBottomNavState? _routesBottomNavState;
  void _addState(_RoutesBottomNavState navState) {
    try {
      _routesBottomNavState = navState;
      //    debugPrint('_routesBottomNavState attached OK');
    } catch (e) {
      debugPrint('Attachment error: ${e.toString()}');
    }
  }

  bool get isAttached => _routesBottomNavState != null;

  void setValue(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      developer.log('RoutesNavController().setValue($id)', name: '_index_');
      _routesBottomNavState?.setValue(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error RoutesBottomNavController: $err');
    }
  }

  void navigate() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _routesBottomNavState?.navigate();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error RoutesBottomNavController: $err');
    }
  }
}

class RoutesBottomNav extends StatefulWidget {
  final Function(int) onMenuTap;
  final RoutesBottomNavController controller;
  final int initialValue;

  const RoutesBottomNav({
    super.key,
    required this.controller,
    required this.onMenuTap,
    this.initialValue = 0,
  });
  @override
  State<RoutesBottomNav> createState() => _RoutesBottomNavState();
}

class _RoutesBottomNavState extends State<RoutesBottomNav>
    with TickerProviderStateMixin {
  // late AnimationController _animationIconController;
  bool isarrowmenu = false;
  List<int> badgeValues = [0, 0, 0, 0, 0, 0];
  int _index = 0; // 0 = hamburger 1 = back

  final CreateTripStackController _createTripStackController =
      CreateTripStackController();

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _index = widget.initialValue;
    //  badgeValues[1] = Setup().tripCount;
    badgeValues[4] = Setup().shopCount;
    badgeValues[5] = Setup().messageCount;
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void setValue(id) {
    setState(() => _index = id);
  }

/*
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    developer.log('onGenerateRoute() called settings.name: ${settings.name}',
        name: '_map_');
    if (['trips', 'createTrip'].contains(settings.name)) {
      return PageRouteBuilder(
        opaque: false, // <--- THIS IS THE MAGIC BULLET
        barrierColor: null,
        settings: settings,
        pageBuilder: (context, _, __) => const CreateTripStack(),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(context, routes[_index], (route) => false);
    }
  }
*/

  void navigate() {
    //   NavigationService().page = _index;
    developer.log('RoutesBottomNav().navigate(${routes[_index]})',
        name: '_map_');
    return;
  }

  @override
  Widget build(BuildContext context) {
    //  debugPrint('selectedIndex: $_index');
    // int newIndex = 0;
    developer.log(
        'RoutesBottomNav().widget.initialValue: ${widget.initialValue} MapService().page: ${MapService().page}',
        name: '_index_');

    /// The line below makes sure that the two map page bottom nav bar buttons are correct
    _index = UIStateService().page == 0 ? NavigationService().page : _index;

    return UIStateService().page == 0
        ? Align(
            alignment: Alignment.bottomLeft,
            child: NavigationBar(
              elevation: 5,
              height: 60,
              surfaceTintColor: Colors.blue,
              onDestinationSelected: (int index) {
                UIStateService().setPage([1, 2].contains(index) ? 0 : 1);
                NavigationService().navigateTo(routes[index], TripArguments());
                MapService()
                    .setPage(page: index); //   <-- Ensures correct cache loaded
                NavigationService()
                    .setPage(index); //  <-- Controls this the RoutesBottomNav
              },
              indicatorColor: Colors.lightBlue,
              selectedIndex: _index,
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
              destinations: List<Widget>.generate(
                  6,
                  (index) => _navigationDestination(
                      index: index, badgeValue: badgeValues[index])),
            ),
          ) //;
        : NavigationBar(
            elevation: 5,
            height: 60,
            surfaceTintColor: Colors.blue,
            onDestinationSelected: (int index) {
              try {
                UIStateService().setPage([1, 2].contains(index) ? 0 : 1);
                _index = index;
                NavigationService()
                    .setPage(index); //  <-- Controls this the RoutesBottomNav
                MapService()
                    .setPage(page: index); //   <-- Ensures correct cache loaded
                NavigationService().navigateTo(routes[index], null);
              } catch (e) {
                developer.log(
                    'Error with NavigatonService().navigateTo() error: ${e.toString()}',
                    name: 'error');
              }
            },
            indicatorColor: Colors.lightBlue,
            selectedIndex: _index,
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
            destinations: List<Widget>.generate(
              6,
              (index) => _navigationDestination(
                  index: index, badgeValue: badgeValues[index]),
            ),
          );
  }

  NavigationDestination _navigationDestination(
      {required int index, badgeValue = 0}) {
    if (badgeValue == 0) {
      return NavigationDestination(
        selectedIcon: Icon(routeNavIconsSelected[index]),
        icon: Icon(routeNavIcons[index]),
        label: routeNavLabels[index],
      );
    } else {
      return NavigationDestination(
        icon: Badge(
          label: Text(badgeValue
              .toString()), // _messages.isEmpty ? null : Text(_messages.length.toString()),
          child: Icon(routeNavIcons[index]),
        ),
        selectedIcon: Badge(
          label: Text(
            badgeValue.toString(),
          ),
          child: Icon(routeNavIconsSelected[index]),
        ),
        label: routeNavLabels[index],
      );
    }
  }
}
