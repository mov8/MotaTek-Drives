import 'package:drives/classes/other_classes.dart';
import 'package:drives/screens/create_trip_stack.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
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
      _routesBottomNavState?.setValue(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error RoutesBottomNavController: $err');
    }
  }

  void navigate() {
    assert(isAttached, 'Controller must be attached to widget');
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
  List<Widget> _destinations = [];

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    developer.log('RoutesBottomNav().initState() called', name: '_nav_');
    _index = widget.initialValue;
    //  badgeValues[1] = Setup().tripCount;
    badgeValues[4] = Setup().shopCount;
    badgeValues[5] = Setup().messageCount;
    _destinations = List<Widget>.generate(
      6,
      (index) => _navigationDestination(
        index: index,
        badgeValue: badgeValues[index],
      ),
    );
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void setValue(int id) {
    developer.log('routesBottomNav.setValue($id)', name: '_nav_');
    setState(() => _index = id);
  }

  @override
  Widget build(BuildContext context) {
    //  debugPrint('selectedIndex: $_index');
    // int newIndex = 0;

    /// The line below makes sure that the two map page bottom nav bar buttons are correct
    // _index = NavigationService().isWidget ? NavigationService().page : _index;

    return NavigationService().isWidget // <-- Use Widget
        ? Align(
            alignment: Alignment.bottomLeft,
            child: NavigationBar(
              key: Key('bnb1'),
              elevation: 5,
              height: 60,
              surfaceTintColor: Colors.blue,
              onDestinationSelected: (int index) {
                developer.log('NavigationBar().onDestinationSelected($index)',
                    name: '_nav_');
                NavigationService().navigateTo(routes[index], TripArguments());
                MapService()
                    .setPage(page: index); //   <-- Ensures correct cache loaded
                _index = index;
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
              destinations: _destinations,
            ),
          ) //;
        : NavigationBar(
            // <-- Use Page
            elevation: 5,
            height: 60,
            surfaceTintColor: Colors.blue,
            onDestinationSelected: (int index) {
              try {
                developer.log('NavigationBar().onDestinationSelected($index)',
                    name: '_nav_');
                MapService()
                    .setPage(page: index); //   <-- Ensures correct cache loaded
                NavigationService().navigateTo(routes[index], null);
                _index = index;
                developer.log(
                    'RoutesBottomNav() _index: $_index  index: $index',
                    name: '_nav_');
              } catch (e) {
                developer.log(
                    'Error with NavigatonService().navigateTo() error: ${e.toString()}',
                    name: 'error');
              }
            },
            indicatorColor: Colors.lightBlue,
            selectedIndex: _index, //NavigationService().page, //_index,
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
            destinations: _destinations,
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
