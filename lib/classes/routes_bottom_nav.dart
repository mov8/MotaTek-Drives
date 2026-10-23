import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '/models/models.dart';

class RoutesBottomNavController {
  _RoutesBottomNavState? _routesBottomNavState;
  void _addState(_RoutesBottomNavState navState) {
    try {
      _routesBottomNavState = navState;
    } catch (e) {
      debugPrint('Attachment error: ${e.toString()}');
    }
  }

  bool get isAttached => _routesBottomNavState != null;

  void F(int id) {
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
  bool isarrowmenu = false;
  List<int> badgeValues = [0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    badgeValues[4] = Setup().shopCount;
    badgeValues[5] = Setup().messageCount;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setValue(int id) {
    developer.log('routesBottomNav.setValue($id)', name: '_nav_');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    /// The line below makes sure that the two map page bottom nav bar buttons are correct

    return const SizedBox.shrink();
  }
}
