import 'package:flutter/material.dart';
import 'package:drives/constants.dart';

class RoutesBottomNavController {
  _RoutesBottomNavState? _routesBottomNavState;
  void _addState(_RoutesBottomNavState navState) {
    try {
      _routesBottomNavState = navState;
      debugPrint('_routesBottomNavState attached OK');
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
  final int? tripCount;
  final int? shopCount;
  final int? messageCount;

  const RoutesBottomNav(
      {super.key,
      required this.controller,
      required this.onMenuTap,
      this.initialValue = 0,
      this.tripCount,
      this.shopCount,
      this.messageCount});
  @override
  State<RoutesBottomNav> createState() => _RoutesBottomNavState();
}

class _RoutesBottomNavState extends State<RoutesBottomNav>
    with TickerProviderStateMixin {
  // late AnimationController _animationIconController;
  bool isarrowmenu = false;
  int _index = 0; // 0 = hamburger 1 = back
  int _messageCount = 0;
  int _shopCount = 0;
  int _tripCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _index = widget.initialValue;
    _tripCount = widget.tripCount ?? 0;
    _shopCount = widget.shopCount ?? 0;
    _messageCount = widget.messageCount ?? 0;
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void setValue(id) {
    debugPrint('Setting bottomNavBar.index t0:$id');
    setState(() => _index = id);
  }

  void navigate() {
    Navigator.pushNamed(context, routes[_index]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('selectedIndex: $_index');
    return NavigationBar(
      height: 60,
      surfaceTintColor: Colors.blue,
      onDestinationSelected: (int index) {
        setState(() => widget.onMenuTap(index));
        _index = index;
        Navigator.pushNamed(context, routes[index]);
      },
      indicatorColor: Colors.lightBlue,
      selectedIndex: _index,
      destinations: List<Widget>.generate(
          6, (index) => _navigationDestination(index: index, badgeValue: 0)),
    );
  }

  NavigationDestination _navigationDestination(
      {required int index, badgeValue = 0}) {
    const List<String> labels = [
      'Home',
      'Great Drives',
      'This Trip',
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
          label: Text(badgeValue.toString()),
          child: Icon(iconsSelected[index]),
        ),
        label: labels[index],
      );
    }
  }
}
