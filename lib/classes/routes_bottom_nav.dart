import 'package:flutter/material.dart';

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
  final int? messageCount;

  const RoutesBottomNav(
      {super.key,
      required this.controller,
      required this.onMenuTap,
      this.initialValue = 0,
      this.messageCount});
  @override
  State<RoutesBottomNav> createState() => _RoutesBottomNavState();
}

class _RoutesBottomNavState extends State<RoutesBottomNav>
    with TickerProviderStateMixin {
  // late AnimationController _animationIconController;
  bool isarrowmenu = false;
  int _index = 0; // 0 = hamburger 1 = back
  String _messageCount = '0';
  List routes = ['home', 'trips', 'createTrip', 'myTrips', 'shop', 'messages'];

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _index = widget.initialValue;

    _messageCount =
        widget.messageCount == null ? '0' : widget.messageCount.toString();
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void setValue(id) {
    setState(() => _index = id);
  }

  void navigate() {
    Navigator.pushNamed(context, routes[_index]);
    return;
  }

  @override
  Widget build(BuildContext context) {
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
      destinations: <Widget>[
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.home,
          ),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        const NavigationDestination(
          selectedIcon: Icon(Icons.route),
          icon: Icon(Icons.route_outlined),
          label: 'Trips',
        ),
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.map,
          ),
          icon: Icon(Icons.map_outlined),
          label: 'Create Trip',
        ),
        const NavigationDestination(
          selectedIcon: Icon(Icons.person),
          icon: Icon(Icons.person_outlined),
          label: 'My Trips',
        ),
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.storefront,
          ),
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Badge(
            label: Text(
                _messageCount), // _messages.isEmpty ? null : Text(_messages.length.toString()),
            child: const Icon(Icons.messenger_outlined),
          ),
          selectedIcon: Badge(
            label: Text(_messageCount),
            child: const Icon(Icons.messenger),
          ),
          label: 'Messages',
        ),
      ],
    );
  }
}
