//import 'dart:math';
//import 'dart:async';
//import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:drives/classes/classes.dart' hide Position, distanceBetween;
import 'package:flutter/material.dart';
import '../routes/home.dart';

/// MarkdownService is a convenient way of carrying around the controllers
/// and image repositories that are shared between the HomeScreen() and Home()
/// and ShopScreen() and Shop()

class MarkdownService {
  static final MarkdownService _instance = MarkdownService._internal();
  factory MarkdownService() => _instance;
  MarkdownService._internal();

  HomeController? homeController = HomeController();

  final ImageRepository imageRepository = ImageRepository();

  final ValueNotifier<int?> scrollToSideDrawerIndex = ValueNotifier<int?>(null);

  void requestScroll(int index) {
    scrollToSideDrawerIndex.value = index;
  }
}
