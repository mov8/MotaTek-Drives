import 'package:flutter/material.dart';
import 'dart:math';

class TargetPainter extends CustomPainter {
  final double top;
  final double left;
  final Color color;
  final double radius = 20;
  final double inset = 5;

  @override
  TargetPainter({required this.top, required this.left, required this.color});
  var outLineBrush = Paint()
    ..color = const Color.fromARGB(234, 13, 13, 14)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(Rect.fromCircle(center: Offset(left, top), radius: radius),
        0, (2 * pi), false, outLineBrush);
    canvas.drawLine(Offset(left - radius - inset, top),
        Offset(left - inset, top), outLineBrush);
    canvas.drawLine(Offset(left + radius + inset, top),
        Offset(left + inset, top), outLineBrush);
    canvas.drawLine(Offset(left, top - radius - inset),
        Offset(left, top - inset), outLineBrush);
    canvas.drawLine(Offset(left, top + radius + inset),
        Offset(left, top + inset), outLineBrush);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
