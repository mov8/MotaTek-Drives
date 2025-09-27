import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';

class DirectionTile extends StatefulWidget {
  final Maneuver direction;
  final int index;
  final int directions;
  final double metersToManeuver;
  final int distance;
  final RouteDelta? routeDelta;

  const DirectionTile({
    super.key,
    required this.direction,
    required this.index,
    required this.directions,
    this.metersToManeuver = 0,
    this.distance = 0,
    this.routeDelta,
  });

  @override
  State<DirectionTile> createState() => _DirectionTileState();
}

class _DirectionTileState extends State<DirectionTile> {
  String _roadFrom = '';
  String _roadTo = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        height: 100,
        width: MediaQuery.of(context).size.width, // - 100,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Column(
            children: [
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
                    getDirections(
                        index: widget.index, maneuver: widget.direction)[0],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(flex: 3, child: SizedBox(width: 1)),
              ]),
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox(width: 1)),
                  Expanded(
                      flex: 20,
                      child: Text(
                          getDirections(
                              index: widget.index,
                              maneuver: widget.direction)[1],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.normal))),
                  const Expanded(flex: 3, child: SizedBox(width: 1)),
                ],
              ),
              if (widget.distance != 0)
                Row(
                  children: [
                    Text(
                        'Distance from route ${widget.routeDelta!.distance}m route: ${widget.routeDelta!.routeIndex}  point: ${widget.routeDelta!.pointIndex}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String modifyDistance({double distance = 0}) {
    /// 1 M = 1.0936133 yards
    /// 160.934 M = 0.1
    /// num3 = double.parse((-12.3412).toStringAsFixed(2));
    if (distance == 0) {
      return '';
    }

    if (distance < 161) {
      return '${(distance * 1.0936133).toInt()} yards';
    } else {
      return '${(distance / 1609.34).toStringAsFixed(2)} miles';
    }
  }

  List<String> getDirections({required int index, required Maneuver maneuver}) {
    List<String> directions = ['', ''];

    /// When the index changes it's then pointing to the next waypoint
    /// so the next waypoint's road_from is our next destination

    if (_roadTo.isEmpty) {
      _roadTo = maneuver.roadTo;
    }
    if (_roadFrom.isEmpty) {
      _roadFrom = maneuver.roadFrom;
    }
    if (_roadTo != maneuver.roadFrom) {
      _roadFrom = _roadTo;
      _roadTo = maneuver.roadFrom;
    }
    if (index == 0 || maneuver.modifier == 'depart') {
      String direction =
          maneuver.modifier.isNotEmpty ? ' (${maneuver.modifier})' : '';
      directions[0] = 'depart from ${maneuver.roadFrom}$direction';
      directions[1] = 'start the drive towards ${maneuver.roadTo}';
    } else if (maneuver.modifier.contains('arrive') ||
        maneuver.type.contains('arrive')) {
      directions[0] = 'arrived at destination';
      directions[1] = 'arrived at ${maneuver.roadFrom}';
    } else {
      if (maneuver.type.contains('roundabout')) {
        directions[0] =
            'in ${modifyDistance(distance: widget.metersToManeuver)} take the ${exitName(widget.direction.exit)}';
        directions[1] = 'at roundabout ${widget.direction.modifier}';
      } else if (maneuver.modifier.contains('right') ||
          maneuver.modifier.contains('left')) {
        if (widget.metersToManeuver > 0) {
          directions[0] =
              'in ${modifyDistance(distance: widget.metersToManeuver)} turn ${maneuver.modifier}';
        } else {
          directions[0] = 'turn ${maneuver.modifier}';
        }
        directions[1] =
            "turn ${maneuver.modifier} ${maneuver.roadTo.isNotEmpty ? ' into ${maneuver.roadFrom}' : ''}";
      }
    }

    if (maneuver.modifier.contains('straight') || maneuver.modifier.isEmpty) {
      if (widget.metersToManeuver > 0) {
        directions[0] =
            'continue for ${modifyDistance(distance: widget.metersToManeuver)}';
        directions[1] = 'continue on $_roadFrom towards $_roadTo';
      } else {
        directions[0] = 'continue along $_roadFrom';
        directions[1] = 'continue on $_roadFrom towards $_roadTo';
      }
    }

    if (directions[0].isEmpty) {
      debugPrint('Emty data');
    }

    return directions;
  }

  String exitName(int exit) {
    switch (exit) {
      case 1:
        return 'first exit';
      case 2:
        return 'second exit';
      case 3:
        return 'third exit';
      case 4:
        return 'fourth exit';
      case 5:
        return 'fifth exit';
      case 6:
        return 'sixth exit';
      default:
        return 'exit';
    }
  }
}

Icon getNavIcon(String modifier, String type, int index, int directions) {
  Icon navIcon = const Icon(
    Icons.arrow_upward,
    size: 40,
  );
  if (index == 0) {
    navIcon = const Icon(
      Icons.flag_outlined,
      size: 40,
    );
  } else if (type.contains('arrive') && index < directions - 1) {
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
