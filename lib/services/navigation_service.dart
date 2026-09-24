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
  final GlobalKey<NavigatorState> uiKey = GlobalKey<NavigatorState>();
  bool showSplash = true;

  // uiKey is the key for the second Stack layer - the pages and side drawer
  /* 
  String initialRoute = 'splash';
  bool _isWidget = false;
  bool showSplash = true;

  /// Current version
  bool get isWidget => _isWidget;

  Future<dynamic> navigateTo(String routeName, Object? arguments) async {
    developer.log('NavigationService().navigateTo($routeName)', name: '_nav_');
    initialRoute = routeName; //<-- used in Main().scaffold
    try {
      final pages = kIsWeb
          ? ['trips', 'createTrip', 'myTrips' 'shop', 'messages']
          : ['trips', 'createTrip'];

      if (!showSplash) {
        developer.log(
            'NavigationService().key.currentState ${key.currentState == null ? "IS" : "ISN'T"} NULL before pushing $routeName',
            name: '_nav_');
        if (pages.contains(routeName)) {
          _isWidget = true;
          //  MapService().appMasterShellController!.update(); // <-- update UI
        } else if (key.currentState != null) {
          _isWidget = false;
          key.currentState!.pushNamed(routeName, arguments: arguments);
        }
      }

      //  MapService()
      //      .routesBottomNavController!
      //      .setValue(routes.indexOf(routeName));
    } catch (e) {
      developer.log(
          'NavigationService().navigateTo($routeName) from: ${MapService().page}  error: ${e.toString()} ',
          name: 'error');
    }
    return;
  }
  */

  List<String> headings = [
    'Home',
    'Published - trips to explore',
    'Explore - plan a trip',
    'Favourite - your personal trips',
    'Shop offers - ',
    'Messages - keep in touch'
  ];

  String get heading => headings[_page];

  int _page = 0;
  int get page => _page;

  int destination(int newPage) {
    _page = newPage;
    if ((kIsWeb & [1, 2, 3, 5].contains(newPage)) ||
        (!kIsWeb && [1, 2].contains(_page))) {
      MapService().createTripController.update();
      return 1;
    }
    int page = newPage > 0 ? --newPage : newPage;
    return page;
  }

  selected(int num) => _page = num;
/*
  void goBack() {
    return key.currentState!.pop();
  }
*/
}
