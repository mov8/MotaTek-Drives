import 'package:flutter/material.dart';
import 'dart:math';
import '/constants.dart';
// import 'dart:developer' as developer;

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
    double radius = size.width / 3;

    canvas.drawCircle(
        Offset(size.width / 2, radius), radius, filledLineBrush..color = color);
    var pointerPath = Path();
    pointerPath.moveTo(
        (size.width / 2) - radius, radius * 1.25); // - radius, radius);
    pointerPath.lineTo(size.width / 2, size.height * .9);
    pointerPath.lineTo((size.width / 2) + radius, radius * 1.25);
    pointerPath.close();
    canvas.drawPath(pointerPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class RoundaboutPainter extends CustomPainter {
  final int index;
  Color color;
  int exitAngle;
  double size;
  int exit;
  RoundaboutPainter(
      {this.index = 0,
      this.color = Colors.black,
      this.exitAngle = 0,
      this.size = 30,
      this.exit = 1});

  static const textStyle = TextStyle(
      color: Colors.black,
      fontFamily: 'OpenSans',
      fontSize: 16,
      fontWeight: FontWeight.bold);

  var outlineBrush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  double radius = 12.0;
  @override
  void paint(Canvas canvas, Size size) {
    Offset offset = Offset(20, 0);
    Rect rect = Rect.fromCircle(center: offset, radius: radius);

    /// drawArc starts at 3 O'clock position and draws clockwise in radians
    /// OSM returns the roundabout entry and exit angles in degrees
    /// This is converted to +ve and -ve direction change values -ve = left +ve = right
    /// ie +90 would be right @ 90 degrees a sweepAngle of 270 degrees
    ///    -90 would be left @ 90 degrees a sweepAngle of 90 degrees
    /// 0.0174532925 is the degrees to radians convertion factor

    outlineBrush.color = Colors.grey;
    canvas.drawArc(rect, 0.5 * pi, 2 * pi, false, outlineBrush);

    /// Not all exites are 100% radial
    exitAngle = exitAngle > 180 ? 180 : exitAngle;
    outlineBrush.color = Colors.black;
    double sweepAngle1 = (180 + exitAngle) * degreeToRadians;
    canvas.drawArc(rect, 0.5 * pi, sweepAngle1, false, outlineBrush);

    TextSpan textSpan = TextSpan(text: '$exit', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.paint(canvas, Offset(15, -10));

    /// Calculate the exit route
    double sweepAngle2 = (exitAngle - 90) * degreeToRadians;
    double x1 = (radius * cos(sweepAngle2) + offset.dx);
    double x2 = ((radius + 10) * cos(sweepAngle2) + offset.dx);
    double y1 = (radius * sin(sweepAngle2));
    double y2 = ((radius + 10) * sin(sweepAngle2));
    double sweepAngle3 = (exitAngle - 75) * degreeToRadians;
    double x3 = ((radius + 7) * cos(sweepAngle3) + offset.dx);
    double y3 = ((radius + 7) * sin(sweepAngle3));
    double sweepAngle4 = (exitAngle - 105) * degreeToRadians;
    double x4 = ((radius + 7) * cos(sweepAngle4) + offset.dx);
    double y4 = ((radius + 7) * sin(sweepAngle4));
    Path lanePath = Path()
      ..moveTo(offset.dx, (rect.height / 2))
      ..lineTo(offset.dx, rect.height / 2 + 10)
      ..moveTo(x3, y3)
      ..lineTo(x2, y2)
      ..moveTo(x4, y4)
      ..lineTo(x2, y2)
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..close();
    canvas.drawPath(lanePath, outlineBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class FlagBackgroundPainter extends CustomPainter {
  final int index;
  Color color;
  double size;

  // @override
  FlagBackgroundPainter({
    this.index = 0,
    this.color = Colors.blue,
    this.size = 30,
  });

  static const textStyle =
      TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 12);

  Paint filledLineBrush = Paint()
    ..style = PaintingStyle.fill
    ..strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTRB(size.width * .22, size.height * .18, size.width * .8,
            size.height * .6),
        Paint()..color = Colors.white);
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

class PolylinePainter extends CustomPainter {
  PolylinePainter(lines, mapState);
  var outLineBrush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  @override
  void paint(Canvas canvas, Size size) {
    outLineBrush.color = Colors.black;
    canvas.drawArc(Rect.fromCircle(center: Offset(0, 0), radius: 5), 0,
        (2 * pi), false, outLineBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
