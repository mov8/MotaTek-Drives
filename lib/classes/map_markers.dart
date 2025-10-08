import 'package:drives/models/models.dart';

import 'package:drives/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LabelWidget extends StatelessWidget {
  final String description;
  final int top;
  final int left;
  const LabelWidget(
      {super.key,
      required this.top,
      required this.left,
      required this.description});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: MapLabelPainter(
            top: top, left: left, labelText: description, pixelRatio: 1));
  }
}

class MarkerLabel extends Marker {
  final int id;
  final int userId;
  final int driveId;
  final int type;
  final String description;
  final BuildContext ctx;
  // final MarkerWidget marker;
  // final LatLng markerPoint;
  // @override
  // late final Widget child;

  const MarkerLabel(this.ctx, this.id, this.userId, this.driveId, this.type,
      this.description, double width, double height,
      {required LatLng markerPoint, required Widget marker})
      : super(child: marker, point: markerPoint, width: width, height: height);

  // Future<Bitma
}

class PinMarkerWidget extends StatelessWidget {
  final Color color;
  final double width;
  final int index;
  final IconData overlay;
  final Color iconColor;
  final Function(int)? onPress;
  final double rating;
  const PinMarkerWidget(
      {super.key,
      this.color = Colors.blue,
      this.width = 50,
      this.index = -1,
      this.overlay = Icons.hail,
      this.iconColor = Colors.white,
      this.rating = 1,
      this.onPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      splashColor: Colors.blue,
      borderRadius: BorderRadius.circular(width / 2),
      onTap: () => {onPress!(index)},
      onLongPress: () => (debugPrint('LongPress')),
      child: CustomPaint(
        painter: LocationPinPainter(color: color, size: 50),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 15), //18),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 20 * .85,
                child: Icon(overlay, size: width * .8, color: iconColor),
              ),
              ...List.generate(
                5,
                (index) => buildIcons(index: index, score: rating),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIcons({int index = 0, double score = 1}) {
    List<double> tops = [14, 4, 0, 4, 14];
    List<double> lefts = [10, 14, 24, 34, 38];
    return Positioned(
      top: tops[index], // * width / 30,
      left: lefts[index] * .8, // * 30 / width,
      child: Icon(
        score >= index + 1
            ? Icons.star
            : score > index
                ? Icons.star_half
                : Icons.star_outline,
        //  Icons.star,
        size: 10,
        color: Colors.yellow,
      ),
    );
  }
}

class EndMarkerWidget extends StatelessWidget {
  final Color color;
  final double width;
  final int index;
  final IconData overlay;
  final Color iconColor;
  final Function(int)? onPress;
  final bool begining;
  const EndMarkerWidget(
      {super.key,
      this.color = Colors.transparent,
      this.width = 50,
      this.index = -1,
      this.overlay = Icons.hail,
      this.iconColor = Colors.blueAccent,
      this.begining = true, // 0 = start 1 = end
      this.onPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      splashColor: Colors.blue,
      borderRadius: BorderRadius.circular(width / 2),
      onTap: () => {onPress!(index)},
      onLongPress: () => (debugPrint('LongPress')),
      child: Padding(
        padding: EdgeInsets.fromLTRB(width * .5, width * .5, 0, 0),
        child: CustomPaint(
          painter: FlagBackgroundPainter(
              index: index, color: Colors.white, size: 30),
          child:
              Icon(begining ? Icons.tour : Icons.sports_score, size: width * 2),
        ),
      ),
    );
  }
}

IconData markerIcon(int type, {double size = 0}) {
  type = type == -1 ? 17 : type;
  return IconData(poiTypes.toList()[type]['iconMaterial'],
      fontFamily: 'MaterialIcons');
}
