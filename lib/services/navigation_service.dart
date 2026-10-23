import 'package:flutter/material.dart';
import 'services.dart';
import 'package:flutter/foundation.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();
  // key is the key for the bottom Stack level - the map
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> uiKey = GlobalKey<NavigatorState>();
  bool showSplash = true;

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
  int _highlight = 0;
  int get page => _page;

  int destination(int newPage) {
    _highlight = newPage;
    _page = newPage;
    if ((kIsWeb & [1, 2, 3, 5].contains(newPage)) ||
        (!kIsWeb && [1, 2].contains(_page))) {
      MapService().createTripController!.update();
      return 4; // 1;
    }
    int page = newPage > 0 ? --newPage : newPage;
    return page;
  }

  int setHighlight(int value) {
    _highlight = value;
    return _highlight;
  }

  int highlight() {
    return _highlight;
  }

  int selected(int num) {
    _page = num;
    MapService().createTripController!.update();
    return num;
  }
}
