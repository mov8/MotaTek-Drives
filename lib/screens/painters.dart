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
  // final Color _color = color;
  var outLineBrush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  @override
  void paint(Canvas canvas, Size size) {
    outLineBrush.color = color;
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

/// Allows text to be placed on the map
/// with a pointy tag.

class MapLabelPainter extends CustomPainter {
  final int top;
  final int left;
  final String labelText;
  final double pixelRatio;

  // final ui.Image image;
  @override
  MapLabelPainter(
      /*this.image,*/
      {required this.top,
      required this.left,
      required this.labelText,
      required this.pixelRatio});

  static const textStyle =
      TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 11);
  // Size size = Size(width, height)
//  top = top ~/2;

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.drawImage(image, Offset.zero, Paint());
    final textSpan = TextSpan(
      text: labelText,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(
        maxWidth: 120,
      );
    int textWidth = textPainter.width.toInt() + 20;
    int textHeight = textPainter.height.toInt();

    final dx = (textWidth + 10);
    final dy = textHeight * 0.8;
    // final offset = Offset(-1 * dx + 10, dy.toDouble());
    final offset = Offset(0, dy.toDouble());
    //  top = top ~/2;

    canvas.drawRRect(
        RRect.fromLTRBAndCorners(
            // left / 2 - dx, top / 2.toDouble(), left + dx, top + textHeight + 20,
            -20,
            0,
            dx.toDouble(),
            0 + textHeight + 20,
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10)),
        Paint()..color = Colors.blue);

    var arrowPath = Path();
    arrowPath.moveTo((textWidth) / 2 - 20, textHeight + 20);
    arrowPath.lineTo((textWidth) / 2 - 10, textHeight + 30);
    arrowPath.lineTo((textWidth) / 2, textHeight + 20);
    arrowPath.close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.blue);

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
