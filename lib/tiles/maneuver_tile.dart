import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';

class ManeuverTile extends StatefulWidget {
  final Maneuver maneuver;
  final Function(int) onLongPress;
  final int index;
  final int maneuvers;
  final double distance;

  const ManeuverTile({
    super.key,
    required this.index,
    required this.maneuver,
    required this.maneuvers,
    required this.onLongPress,
    required this.distance,
  });

  @override
  State<ManeuverTile> createState() => _maneuverTileState();
}

class _maneuverTileState extends State<ManeuverTile> {
  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      leading: getNavIcon(widget.maneuver.modifier, widget.maneuver.type,
          widget.index, widget.maneuvers),
      title: Text(
          '${modifyModifier(widget.maneuver.modifier, widget.maneuver.type, widget.index, widget.maneuvers)} ${widget.maneuver.roadFrom}'),
      subtitle: Text(widget.maneuver.type.contains('arrive')
          ? ''
          : 'drive ${modifyDistance(widget.maneuver.distance)} towards ${widget.maneuver.roadTo}'),
      onLongPress: () => widget.onLongPress(widget.index),
    ));
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

String modifyModifier(String modifier, String type, int index, int maneuvers) {
  if (index == 0) {
    modifier = 'depart from';
  } else if (modifier == 'depart') {
    modifier = 'trip start depart from';
  } else if (type.contains('arrive') && index < maneuvers - 1) {
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

Icon getNavIcon(String modifier, String type, int index, int maneuvers) {
  Icon navIcon = const Icon(
    Icons.arrow_upward,
    size: 40,
  );
  if (index < maneuvers - 1 && type.contains('arrive')) {
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
