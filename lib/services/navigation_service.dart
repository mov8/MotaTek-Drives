import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  Future<void> navigateTo(String routeName, Object? arguments) {
    return key.currentState!.pushNamed(routeName, arguments: arguments);
  }

  int page = 0;

  void goBack() {
    return key.currentState!.pop();
  }
}
