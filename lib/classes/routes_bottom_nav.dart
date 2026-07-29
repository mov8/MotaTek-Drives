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
    // debugPrint('Setting bottomNavBar.index t0:$id');
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
    NavigationService().page = _index;
    developer.log('RoutesBottomNav().navigate(${routes[_index]})',
        name: '_map_');

    return;
  }

  @override
  Widget build(BuildContext context) {
    //  debugPrint('selectedIndex: $_index');
    return Align(
      alignment: AlignmentGeometry.bottomStart,
      child: NavigationBar(
        elevation: 5,
        height: 60,
        surfaceTintColor: Colors.blue,
        onDestinationSelected: (int index) {
          MapService().setPage(page: index);
          setState(() => widget.onMenuTap(index));
          if ([1, 2].contains(index)) {
            UIStateService().setPage(0); //setMode(AppDisplayMode.navigator);
          }
          _index = index;
          MapService().setPage(page: index);
          Navigator.pushNamedAndRemoveUntil(
              context, routes[index], (route) => false);
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
