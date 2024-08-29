import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';

class DirectionTile extends StatefulWidget {
  final Maneuver direction;
  final int index;
  final int directions;

  const DirectionTile({
    super.key,
    required this.direction,
    required this.index,
    required this.directions,
  });

  @override
  State<DirectionTile> createState() => _directionTileState();
}

class _directionTileState extends State<DirectionTile> {
  @override
  Widget build(BuildContext context) {
    return Material(
        child: SizedBox(
            height: 100,
            width: MediaQuery.of(context).size.width, // - 100,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        flex: 3,
                        child: getNavIcon(
                            widget.direction.modifier,
                            widget.direction.type,
                            widget.index,
                            widget.directions)),
                    Expanded(
                      flex: 20,
                      child: Text(
                        '${modifyModifier(widget.direction.modifier, widget.direction.type, widget.index, widget.directions)} ${widget.direction.roadFrom}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Expanded(flex: 3, child: SizedBox(width: 1)),
                  ]),
                  Row(children: [
                    const Expanded(flex: 3, child: SizedBox(width: 1)),
                    Expanded(
                        flex: 20,
                        child: Text(
                            widget.direction.type.contains('arrive')
                                ? ''
                                : 'drive ${modifyDistance(widget.direction.distance)} towards ${widget.direction.roadTo}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal))),
                    const Expanded(flex: 3, child: SizedBox(width: 1)),
                  ])
                ]))));
  }
}

String modifyDistance(double distance) {
// 1 M = 1.0936133 yards
// 160.934 M = 0.1
// num3 = double.parse((-12.3412).toStringAsFixed(2));
  if (distance < 161) {
    return '${(distance * 1.0936133).toInt()} yards';
  } else {
    return '${(distance / 1609.34).toStringAsFixed(2)} miles';
    //return '${double.parse((distance / 1609.34).toStringAsFixed(2))} miles';
  }
}

String modifyModifier(String modifier, String type, int index, int directions) {
  if (index == 0) {
    modifier = 'depart from';
  } else if (modifier == 'depart') {
    modifier = 'trip start depart from';
  } else if (type.contains('arrive') && index < directions - 1) {
    modifier = 'waypoint';
  } else if (type.contains('arrive')) {
    modifier = 'trip end';
  } else if (modifier.contains('arrive')) {
    modifier = 'arrive trip end';
  } else if (modifier.contains('right') || modifier.contains('left')) {
    modifier = '$type $modifier';
  } else if (modifier.contains('straight')) {
    modifier = 'continue on';
  }
  return modifier;
}

Icon getNavIcon(String modifier, String type, int index, int directions) {
  Icon navIcon = const Icon(
    Icons.arrow_upward,
    size: 40,
  );
  if (type.contains('arrive') && index < directions - 1) {
    navIcon = const Icon(
      Icons.pin_drop,
      size: 40,
    );
  } else if (type.contains('arrive')) {
    navIcon = const Icon(
      Icons.flag,
      size: 40,
    );
  } else if (type.contains('roundabout')) {
    navIcon = modifier.contains('right')
        ? const Icon(
            Icons.roundabout_right,
            size: 40,
          )
        : const Icon(
            Icons.roundabout_left,
            size: 40,
          );
  } else if (modifier.contains('right')) {
    navIcon = modifier.contains('slight')
        ? const Icon(
            Icons.turn_slight_right,
            size: 40,
          )
        : const Icon(
            Icons.turn_right,
            size: 40,
          );
  } else if (modifier.contains('left')) {
    navIcon = modifier.contains('slight')
        ? const Icon(
            Icons.turn_slight_left,
            size: 40,
          )
        : const Icon(
            Icons.turn_left,
            size: 40,
          );
  }

  return navIcon;
}
