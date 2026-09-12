import 'package:drives/main.dart';
import 'package:flutter/material.dart';
import 'package:drives/constants.dart';
import 'services.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();
  // key is the key for the bottom Stack level - the map
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  // uiKey is the key for the second Stack layer - the pages and side drawer
  final GlobalKey<NavigatorState> uiKey = GlobalKey<NavigatorState>();
  String initialRoute = 'splash';
  bool _isWidget = false;
  bool showSplash = true;

  bool get isWidget => _isWidget;

  Future<dynamic> navigateTo(String routeName, Object? arguments) async {
    initialRoute = routeName;
    try {
      if (key.currentState == null) {
        developer.log('Navigator.key.currentState is null', name: '_stack_');
        return;
      }

      final pages = kIsWeb
          ? ['trips', 'createTrip', 'myTrips' 'shop', 'messages']
          : []; //'trips', 'createTrip'];

      /// UIStateService() is used to switch between Page and Widget for the AppMasterShell
      //   UIStateService()
      //       .setPage(['trips', 'createTrip'].contains(routeName) ? 0 : 1);
      if (!showSplash) {
        if (pages.contains(routeName)) {
          _isWidget = true;
          developer.log(
              'NavigationService().navigateTo($routeName) isWidget == true',
              name: '_nav_');
          MapService().createTripStackController!.refresh();
          MapService()
              .routesBottomNavController!
              .setValue(routes.indexOf(routeName));
          //  UIStateService().setPage(0); // <-- Use Widget
          // key.currentState!.pushNamed(routeName, arguments: arguments);
        } else {
          _isWidget = false;
          developer.log(
              'NavigationService().navigateTo($routeName) isWidget == false',
              name: '_nav_');
          //  UIStateService().setPage(1); // <-- Use Page
          key.currentState!.pushNamed(routeName, arguments: arguments);
        }
      }
    } catch (e) {
      developer.log(
          'NavigationService().navigateTo($routeName) from: ${MapService().page}  error: ${e.toString()} ',
          name: 'error');
    }
    return;
  }

  int _page = 0;

  setPage(int page) {
    developer.log('NavigationService().setPage($page) ', name: '_stack_');
    _page = page;
  }

  int get page => _page;

  void goBack() {
    return key.currentState!.pop();
  }
}
