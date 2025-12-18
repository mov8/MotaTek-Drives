import '/constants.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/screens/screens.dart';
import '/helpers/create_trip_helpers.dart';
import '/helpers/edit_helpers.dart';
import '/classes/route.dart' as mt;
// import 'dart:developer' as developer;

class ManeuverTile extends StatefulWidget {
  final List<Maneuver> maneuvers;
  final Function(int) onLongPress;
  final List<mt.Route> routes;
  final int index;

  const ManeuverTile({
    super.key,
    required this.index,
    required this.maneuvers,
    required this.routes,
    required this.onLongPress,
  });

  @override
  State<ManeuverTile> createState() => _ManeuverTileState();
}

class _ManeuverTileState extends State<ManeuverTile> {
  int _sweepAngle = 0;
  @override
  void initState() {
    super.initState();
    if (widget.maneuvers[widget.index].type.contains('roundabout')) {
      _sweepAngle = getRoundaboutAngle(
          maneuvers: widget.maneuvers,
          index: widget.index,
          routes: widget.routes);
      /*
      _sweepAngle = widget.maneuvers[widget.index].bearingAfter -
          widget.maneuvers[widget.index].bearingBefore;
      _sweepAngle = _sweepAngle < -90 ? 360 + _sweepAngle : _sweepAngle;
      _sweepAngle = _sweepAngle > 180 ? 180 : _sweepAngle;

    */
    }
    //  developer.log(
    //      'maneuverTile initState - maneuver - after ${widget.maneuvers[widget.index].bearingAfter} - before: ${widget.maneuvers[widget.index].bearingBefore}',
    //      name: '_roundabout');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        leading: getNavIcon(
          maneuvers: widget.maneuvers,
          index: widget.index,
          angle: _sweepAngle,
        ),
        title: Text(
          '${modifyModifier(widget.maneuvers, widget.index)}', //${widget.maneuvers[widget.index].roadFrom}',
          style: textStyle(context: context, size: 2, color: Colors.black),
        ), // before: ${widget.maneuver.bearingBefore}  after: ${widget.maneuver.bearingAfter} - ($_sweepAngle})',
        subtitle: Text(getSubtitle(maneuver: widget.maneuvers[widget.index]),
            style: textStyle(context: context, size: 3, color: Colors.black)),
        onLongPress: () => widget.onLongPress(widget.index),
      ),
    );
  }
}

String getSubtitle({required Maneuver maneuver}) {
  if (maneuver.type.contains('arrive')) {
    return '';
  }
  if (maneuver.roadTo.isNotEmpty) {
    return 'drive ${modifyDistance(maneuver.distance)} towards ${maneuver.roadTo}';
  } else {
    return 'drive ${modifyDistance(maneuver.distance)}';
  }
}

String modifyDistance(double distance) {
  if (distance < 161) {
    return '${(distance * metersToYards).toInt()} yards';
  } else {
    return '${(distance * metersToMiles).toStringAsFixed(2)} miles';
  }
}

String modifyModifier(List<Maneuver> maneuvers, int index) {
  String modifier = '';
  if (index == 0) {
    modifier = maneuvers[index].roadFrom.isNotEmpty
        ? 'depart from ${maneuvers[index].roadFrom}'
        : 'depart';
  } else if (maneuvers[index].modifier == 'depart') {
    modifier = 'trip start depart from';
  } else if (maneuvers[index].type.contains('arrive') &&
      index < maneuvers.length - 1) {
    modifier = 'waypoint';
  } else if (maneuvers[index].type.contains('arrive')) {
    modifier = 'trip end';
  } else if (maneuvers[index].modifier.contains('arrive')) {
    modifier = 'arrive trip end';
  } else if (maneuvers[index].type.contains('roundabout')) {
    if (maneuvers[index].type.contains('exit')) {
      modifier =
          '${maneuvers[index].type} ${maneuvers[index].modifier} exit ${maneuvers[index].exit}';
    } else {
      modifier =
          'at next roundabout take exit ${maneuvers[index].exit} ${maneuvers[index].modifier}';
    }
  } else if (maneuvers[index].modifier.contains('right') ||
      maneuvers[index].modifier.contains('left') ||
      maneuvers[index].type.contains('exit roundabout')) {
    modifier = '${maneuvers[index].type} ${maneuvers[index].modifier}';
  } else if (maneuvers[index].modifier.contains('straight')) {
    modifier = 'continue straight on';
  }
  modifier = modifier.replaceAll('slight ', 'slightly ');
  if (modifier.contains('slight ')) {
    debugPrint('modifier [$modifier]');
  }

  return modifier;
}

Widget getNavIcon(
    {required List<Maneuver> maneuvers, int index = 0, int angle = 0}) {
  Icon navIcon = const Icon(Icons.arrow_upward, size: 40);
  if (index == -2) {
    navIcon = const Icon(
      Icons.alt_route_outlined,
      size: 40,
      color: Colors.white,
    );
  } else if (index == -1) {
    navIcon = const Icon(
      Icons.u_turn_right_sharp,
      size: 40,
      color: Colors.white,
    );
  } else if (index == 0) {
    navIcon = const Icon(Icons.flag_outlined, size: 40);
  } else if (index < maneuvers.length - 1 &&
      maneuvers[index].type.contains('arrive')) {
    navIcon = const Icon(Icons.pin_drop, size: 40);
  } else if (maneuvers[index].type.contains('arrive')) {
    navIcon = const Icon(Icons.flag, size: 40);
  } else if (maneuvers[index].type.contains('roundabout')) {
    return Container(
      width: 40,
      alignment: AlignmentGeometry.centerLeft,
      child: CustomPaint(
        painter:
            RoundaboutPainter(exitAngle: angle, exit: maneuvers[index].exit),
      ),
    );
  } else if (maneuvers[index].modifier.contains('right')) {
    navIcon = maneuvers[index].modifier.contains('slight')
        ? const Icon(Icons.turn_slight_right, size: 40)
        : const Icon(Icons.turn_right, size: 40);
  } else if (maneuvers[index].modifier.contains('left')) {
    navIcon = maneuvers[index].modifier.contains('slight')
        ? const Icon(Icons.turn_slight_left, size: 40)
        : const Icon(Icons.turn_left, size: 40);
  }

  return navIcon;
}
