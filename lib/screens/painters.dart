import 'package:flutter/material.dart';
import 'dart:math';

// import 'package:latlong2/latlong.dart' hide Path;

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

/// Draws a map location pin of the correct colour
/// The icon can be superimposed and an inkwell
/// used to handle the user tap events

class LocationPinPainter extends CustomPainter {
  final int index;
  Color color;
  double size;
  Icon icon;
  String text;
  double score;
  // @override
  LocationPinPainter(
      {this.index = 0,
      this.color = Colors.blue,
      this.size = 30,
      this.icon = const Icon(Icons.home),
      this.text = '3.5',
      this.score = 3.5});

  static const textStyle =
      TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 12);

  Paint filledLineBrush = Paint()
    ..style = PaintingStyle.fill
    ..strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
/*    
    final textSpan = TextSpan(
      text: score.toString(),
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(
        maxWidth: 120,
      );

*/
//    int textWidth = textPainter.width.toInt() + 20;
//    int textHeight = textPainter.height.toInt();

    double radius = size.width / 3;
    //  Offset offset = Offset(size.width / 2, radius);
    canvas.drawCircle(
        Offset(size.width / 2, radius), radius, filledLineBrush..color = color);
/*
    double left = size.width - (radius * 2.4);
    double top = 0.2;
    //radius * 1.25;
    double right = left + (radius * 1.8);
    double bottom = top + (radius * 2);
    canvas.drawArc(
        Rect.fromLTRB(left, top, right, bottom),
        -pi,
        pi * score / 5,
        false,
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4);

*/
    var pointerPath = Path();
    pointerPath.moveTo(
        (size.width / 2) - radius, radius * 1.25); // - radius, radius);
    pointerPath.lineTo(size.width / 2, size.height * .9);
    pointerPath.lineTo((size.width / 2) + radius, radius * 1.25);
    pointerPath.close();
    canvas.drawPath(pointerPath, Paint()..color = color);
//    textPainter.paint(canvas,
//        Offset((size.width / 2) - (textWidth / 4), radius + textHeight - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// Allows text to be placed on the map
/// with a pointy tag.
///

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
