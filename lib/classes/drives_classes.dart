import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class KeyboardVisibilityListener extends StatefulWidget {
  final Widget child;
  final void Function(
    bool isKeyboardVisible,
  ) listener;

  const KeyboardVisibilityListener(
      {super.key, required this.child, required this.listener});

  @override
  State<KeyboardVisibilityListener> createState() =>
      _KeyboardVisibilityListenerState();
}

class _KeyboardVisibilityListenerState extends State<KeyboardVisibilityListener>
    with WidgetsBindingObserver {
  var _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      _isKeyboardVisible = newValue;
      widget.listener(_isKeyboardVisible);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class InvertedClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    return ui.Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: 40))
      ..fillType = PathFillType.evenOdd;

    // return new Path();
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => true;
}
