import 'package:drives/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services.dart';
import 'dart:developer' as developer;

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  String initialRoute = 'splash';

  Future<dynamic> navigateTo(String routeName, Object? arguments) async {
    initialRoute = routeName;
    try {
      if (key.currentState == null) {
        developer.log('Navigator.key.currentState is null', name: 'error');
        return;
      }
      UIStateService()
          .setPage(['trips', 'createTrip'].contains(routeName) ? 0 : 1);
      key.currentState!.pushNamed(routeName, arguments: arguments);
    } catch (e) {
      developer.log(
          'NavigationService().navigateTo($routeName) from: ${MapService().page}  error: ${e.toString()} ',
          name: 'error');
    }
    return;
  }

  int _page = 0;

  setPage(int page) {
    _page = page;
  }

  int get page => _page;

  void goBack() {
    return key.currentState!.pop();
  }
}
