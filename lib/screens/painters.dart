import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'package:latlng/latlng.dart';
import 'dart:math';
import '/constants.dart';
import 'dart:developer' as developer;

// import 'package:latlong2/latlong.dart' hide Path;

class TargetPainter extends CustomPainter {
  final double top;
  final double left;
  final Color color;
  final double radius = 20;
  final double inset = 5;

  // @override
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

class HighlightPainter extends CustomPainter {
  final Size boundary;
  final double proportion;
  final Color color;
  final int dashes;
  Map<String, dynamic> mbr = {};
  Point? sw;
  Point? ne;
  HighlightPainter(
      {required this.boundary,
      required this.proportion,
      required this.color,
      this.dashes = 4});
  var outLineBrush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  @override

  ///   +--    ----    ----    --+
  ///   To have 4 segments (n) the line has to divided into 6  (n+2)
  ///   space = n/6
  ///   line 1/2 segment, n-2 full segments, 1/2 segment
  ///
  paint(Canvas canvas, Size size) {
    double deltaX = boundary.width - (boundary.width * proportion) * 0.5;
    double deltaY = boundary.height - (boundary.height * proportion) * 0.5;
    double bottom = deltaY;
    double right = deltaX;
    double top = boundary.height - deltaY;
    double left = boundary.width - deltaX;
    double segLength = (right - left) / (dashes + 2);

    mbr = {'top': top, 'left': left, 'bottom': bottom, 'right': right};
    sw = Point(bottom, left);
    ne = Point(top, right);
    outLineBrush.color = color;
    double newX = left;

    for (int i = 0; i < dashes; i++) {
      double dash = i > 0 && i < dashes - 1 ? segLength : segLength * .5;
      canvas.drawLine(
          Offset(newX, top), Offset(newX + dash, top), outLineBrush);
      canvas.drawLine(
          Offset(newX, bottom), Offset(newX + dash, bottom), outLineBrush);
      newX = newX + segLength + dash;
    }
    double newY = top;

    segLength = (bottom - top) / (dashes + 2);
    for (int i = 0; i < dashes; i++) {
      double dash = i > 0 && i < dashes - 1 ? segLength : segLength * .5;
      canvas.drawLine(
          Offset(right, newY), Offset(right, newY + dash), outLineBrush);
      canvas.drawLine(
          Offset(left, newY), Offset(left, newY + dash), outLineBrush);
      newY = newY + segLength + dash;
    }
  }

  Map<String, dynamic> get swNe => {'sw': sw, 'ne': ne};

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* 
LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth / 2,
      height: constraints.maxHeight / 2,
    );
  },
);
*/

/// LinearScale creates a linear distance scale calculated on the current map settings:
/// It calculates the maps distance L -> R in meters and pixels and creates the scale
/// bar appropriately. The minimum value is always 0, and the maximum is 1, 10, 100 ...
/// depending on the map's scale. It will vary its rendered length to be as close as it
/// can to the chosen length - where 1 = whole container width 0.1 = 10% etc.
/// 100 |          |         | 0 Miles
///     ======================
///
///

class LinearScale extends CustomPainter {
  double width;
  double start;
  double height;
  Color? color;
  double mapWidthPixels;
  double mapWidthMeters;
  double screenWidth;
  bool isMiles = true;
  bool alignRight = true;
  TextStyle? textStyle;
  double offset;
  Function(double)? onDraw;
  @override
  LinearScale(
      {this.start = 0,
      this.width = 200,
      this.height = 20,
      Color? color,
      TextStyle? textStyle,
      this.mapWidthPixels = 100,
      this.mapWidthMeters = 1000,
      this.screenWidth = 200,
      this.offset = 0,
      this.onDraw})
      : color = color ?? Colors.white,
        textStyle = textStyle ??
            TextStyle(
                color: Colors.white, fontFamily: 'OpenSans', fontSize: 11);

  var outLineBrush = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white
    ..strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (mapWidthPixels > 0) {
        double baseUnitsPerPixel =
            (mapWidthMeters / mapWidthPixels) * (isMiles ? metersToYards : 1);
        double mapUnitsPerPixel =
            baseUnitsPerPixel * (isMiles ? yardsToMiles : 0.001);

        // default to meters / yards
        double displayUnits = baseUnitsPerPixel;
        String keyUnits = isMiles ? 'yards' : 'meters';
        bool scale = false;

        /// Want to ensure that if the scale width is more than 1 mile / km then
        /// switch from meters / yards to miles
        /// scale = true;

        /// if ((displayUnits * width) >= 1) {
        if ((mapUnitsPerPixel * width) >= 1) {
          displayUnits = mapUnitsPerPixel;
          keyUnits = isMiles ? 'miles' : 'km';
        }

        // double targetLength = 400;

        /// Only convert to miles / km if the LinearScale raw width will be >= 1 (mapWidth km / miles)
        ///
        /// 1609.34 meters / mile (metersPerMile)
        /// Calculate the map width in miles / km
        /// Calculate the map width in pixels
        /// Calculate the raw pixel length of the LinearScale from the %age of screen width requested
        /// Calculate the length of the LinearScale in miles
        /// Find the closest length base 10 to the raw length - final pixel LinearScale length
        /// Recalculate LinearScale length for new base 10 max value

        // double mapWidthUnits = isMiles ? metersToMiles : 1;
        // double unitConvert = isMiles ? metersPerMile : 1000;
        // double keyToMapRatio = width / mapWidthPixels;

        double targetLength = width * displayUnits;
        int max = 1;
        if (targetLength > 100) {
          int exponent = (log(targetLength) / ln10)
              .floor(); // log() is natural logarithm - base e
          int lower = pow(10, exponent).toInt();
          int upper = pow(10, exponent + 1).toInt();
          max = (targetLength - lower) < (upper - targetLength) ? lower : upper;
        } else if (targetLength > 0) {
          max = -1;
          int factor = targetLength > 10 ? targetLength ~/ 10 : 0;
          while (max < 0) {
            int lower = factor == 0 ? 1 : (factor * 10);
            int upper = lower + (factor == 0 ? 9 : 10);
            int mid = upper - 5;

            /// want 1 5 10 15 20 .. 100
            if (targetLength <= upper) {
              if ((targetLength - lower) < (upper - targetLength)) {
                max = targetLength - 2.5 > lower ? mid : lower;
              } else {
                max = targetLength + 2.5 > upper ? upper : mid;
              }
            }
            factor++;
          }
        }

        TextSpan textSpan = TextSpan(text: '$max', style: textStyle);

        var textPainterStart = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textSpan = TextSpan(text: '0 $keyUnits', style: textStyle);
        var textPainterEnd = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainterStart.layout(
          // define the box for text
          minWidth: 2,
          maxWidth: 100,
        );

        textPainterEnd.layout(
          minWidth: 20,
          maxWidth: 100,
        );

        double _length = (max / displayUnits) +
            textPainterEnd.width +
            textPainterStart.width +
            10;
        // - start;

        double start = (mapWidthPixels - _length);
        double end = start + (max / displayUnits);
        double middle = start + ((end - start) / 2);

        canvas.drawLine(Offset(start, 5), Offset(start, 15), outLineBrush);
        canvas.drawLine(Offset(middle, 10), Offset(middle, 15), outLineBrush);
        canvas.drawLine(Offset(end, 5), Offset(end, 15), outLineBrush);
        canvas.drawLine(Offset(start, 15), Offset(end, 15), outLineBrush);

        textPainterStart.paint(
            canvas, Offset(start - textPainterStart.width - 5, 5));

        textPainterEnd.paint(canvas, Offset(end + 5, 5));

        if (onDraw != null) {
          onDraw!(mapWidthPixels - start - textPainterStart.width - 5);
        }
      }
    } catch (e) {
      debugPrint('Error painting scale: ${e.toString()}');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate != this);
    // return false;
  }
}

class BarMessagePainter extends CustomPainter {
  double start;
  double width;
  String message;
  TextStyle? textStyle;
  Function(double)? onDraw;

  BarMessagePainter(
      {this.start = 0,
      this.width = 200,
      this.message = '',
      this.textStyle,
      this.onDraw});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      textStyle ??=
          TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 11);

      TextSpan textSpan = TextSpan(text: message, style: textStyle);

      var textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 10,
        maxWidth: width,
      );

      textPainter.paint(canvas, Offset(start, 5));

      if (onDraw != null) {
        onDraw!(textPainter.width + 5);
      }
    } catch (e) {
      developer.log('Error painters.dart BarMessagePainter(): ${e.toString()}',
          name: 'error');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return this != oldDelegate;
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

  //static const textStyle =
  //    TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 12);

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
