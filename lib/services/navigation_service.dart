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

  /// Current version
  bool get isWidget => _isWidget;

  Future<dynamic> navigateTo(String routeName, Object? arguments) async {
    initialRoute = routeName;
    try {
      if (key.currentState == null) {
        return;
      }

      final pages = kIsWeb
          ? ['trips', 'createTrip', 'myTrips' 'shop', 'messages']
          : ['trips', 'createTrip'];

      if (!showSplash) {
        if (pages.contains(routeName)) {
          _isWidget = true;
          MapService().appMasterShellController!.update(); // <-- update UI
        } else {
          _isWidget = false;
          try {
            key.currentState!.pushNamed(routeName, arguments: arguments);
          } catch (e) {
            developer.log('Error pushNamed($routeName)', name: '_nav_');
          }
        }

        MapService()
            .routesBottomNavController!
            .setValue(routes.indexOf(routeName));
      }
    } catch (e) {
      developer.log(
          'NavigationService().navigateTo($routeName) from: ${MapService().page}  error: ${e.toString()} ',
          name: 'error');
    }
    return;
  }

  int _page = 0;

  int get page => _page;

  void goBack() {
    return key.currentState!.pop();
  }
}
