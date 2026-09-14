import 'package:flutter/material.dart';
import '/constants.dart';
import '/models/models.dart';

class RoutesTopNavController {
  _RoutesTopNavState? _routesTopNavState;
  void _addState(_RoutesTopNavState navState) {
    try {
      _routesTopNavState = navState;
      //    debugPrint('_routesTopNavState attached OK');
    } catch (e) {
      debugPrint('Attachment error: ${e.toString()}');
    }
  }

  bool get isAttached => _routesTopNavState != null;

  void setValue(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _routesTopNavState?.setValue(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error RoutesTopNavController: $err');
    }
  }

  void navigate() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _routesTopNavState?.navigate();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error RoutesTopNavController: $err');
    }
  }
}

class RoutesTopNav extends StatefulWidget {
  Function(int)? onMenuTap;
  RoutesTopNavController? controller;
  final int initialValue;

  RoutesTopNav({
    super.key,
    this.controller,
    this.onMenuTap,
    this.initialValue = 0,
  });
  @override
  State<RoutesTopNav> createState() => _RoutesTopNavState();
}

class _RoutesTopNavState extends State<RoutesTopNav>
    with TickerProviderStateMixin {
  // late AnimationController _animationIconController;
  bool isarrowmenu = false;
  List<int> badgeValues = [0, 0, 0, 0, 0, 0];
  int _index = 0; // 0 = hamburger 1 = back
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    /*
    _index = widget.initialValue;
    //  badgeValues[1] = Setup().tripCount;
    badgeValues[4] = Setup().shopCount;
    badgeValues[5] = Setup().messageCount;
    _tabController = TabController(length: 6, vsync: this);
    */
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void setValue(id) {
    // debugPrint('Setting topNavBar.index t0:$id');
    setState(() => _index = id);
  }

  void navigate() {
    Navigator.pushNamed(context, routes[_index]);
    return;
  }

  List<IconData> icons = [
    Icons.home_outlined,
    Icons.route_outlined,
    Icons.map_outlined,
    Icons.person_outlined,
    Icons.shopping_bag_outlined,
    Icons.chat_bubble_outline_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    //  debugPrint('selectedIndex: $_index');
    return Scaffold(
      appBar: AppBar(
          title: const Text('Drives'),
          bottom: TabBar(
            tabs: [for (int i = 0; i < 5; i++) Tab(icon: Icon(icons[i]))],
          )),
      body: TabBarView(controller: _tabController, children: [
        for (int i = 0; i < 5; i++) Center(child: Text('Page ${i + 1}'))
      ]),
    );
  }
}
