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
/*
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
  */
