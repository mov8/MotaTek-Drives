import 'package:flutter/material.dart';
import '/constants.dart';
import '/models/models.dart';

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

  void navigate() {
    Navigator.pushNamed(context, routes[_index]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    //  debugPrint('selectedIndex: $_index');
    return NavigationBar(
      elevation: 5,
      height: 60,
      surfaceTintColor: Colors.blue,
      onDestinationSelected: (int index) {
        setState(() => widget.onMenuTap(index));
        _index = index;
        Navigator.pushNamed(context, routes[index]);
      },
      indicatorColor: Colors.lightBlue,
      selectedIndex: _index,
      // labelTextStyle: WidgetStateProperty.all(
      //   const TextStyle(fontSize: 12, color: Color.fromARGB(255, 87, 23, 238)),
      // ),
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
    );
  }

  NavigationDestination _navigationDestination(
      {required int index, badgeValue = 0}) {
    const List<String> labels = [
      'Home',
      'Great Drives',
      'My Trip',
      'My Drives',
      'Shop',
      'Messages'
    ];
    const List<IconData> iconsSelected = [
      Icons.home,
      Icons.route,
      Icons.map,
      Icons.person,
      Icons.shopping_bag,
      Icons.chat_bubble
    ];
    const List<IconData> icons = [
      Icons.home_outlined,
      Icons.route_outlined,
      Icons.map_outlined,
      Icons.person_outlined,
      Icons.shopping_bag_outlined,
      Icons.chat_bubble_outline_outlined,
    ];

    if (badgeValue == 0) {
      return NavigationDestination(
        selectedIcon: Icon(iconsSelected[index]),
        icon: Icon(icons[index]),
        label: labels[index],
      );
    } else {
      return NavigationDestination(
        icon: Badge(
          label: Text(badgeValue
              .toString()), // _messages.isEmpty ? null : Text(_messages.length.toString()),
          child: Icon(icons[index]),
        ),
        selectedIcon: Badge(
          label: Text(
            badgeValue.toString(),
          ),
          child: Icon(iconsSelected[index]),
        ),
        label: labels[index],
      );
    }
  }
}
