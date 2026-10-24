import 'dart:math';
import '/classes/initials_button.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/utilities.dart';
import '/helpers/edit_helpers.dart';
import 'package:geolocator/geolocator.dart';
import '/constants.dart';

class FollowerTile extends StatefulWidget {
  final Follower follower;

  final Future<void> Function(int) onIconClick;
  final Function(int) onLongPress;
  final int index;
  final double distance;
  final Point currentPosition;
  const FollowerTile({
    super.key,
    required this.index,
    required this.follower,
    required this.onIconClick,
    required this.onLongPress,
    required this.distance,
    required this.currentPosition,
  });

  @override
  State<FollowerTile> createState() => _FollowerTileState();
}

class _FollowerTileState extends State<FollowerTile> {
  final List<String> _statuses = [
    "(hasn't replied to invitation)",
    '',
    '(accepted but not yet joined)',
    '(has joined)'
  ];
  String _status = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    calcStatus();
    return Material(
      child: ListTile(
        shape:
            ContinuousRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
        title: SizedBox(
          height: 83,
          width: MediaQuery.of(context).size.width - 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: Text(
                      '${widget.follower.forename} ${widget.follower.surname}',
                      style: headlineStyle(
                          context: context, size: 2, color: Colors.black),
                    ),
                  ),
                  if (widget.follower.email != Setup().user.email) ...[
                    Expanded(
                      flex: 2,
                      child: Text(
                        'track',
                        style: textStyle(
                            context: context, size: 3, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Checkbox(
                        value: widget.follower.track,
                        onChanged: (value) => setState(
                            () => widget.follower.track = value ?? false),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _status,
                style:
                    textStyle(context: context, size: 2, color: Colors.black),
              ),
            ],
          ),
        ),
        subtitle: SizedBox(
          height: 60,
          width: MediaQuery.of(context).size.width - 100,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('make: ${widget.follower.manufacturer}',
                style:
                    labelStyle(context: context, color: Colors.black, size: 3)),
            Text('model: ${widget.follower.model}',
                style:
                    labelStyle(context: context, color: Colors.black, size: 3)),
            Row(children: [
              Expanded(
                flex: 1,
                child: Text('colour: ${widget.follower.carColour}',
                    style: labelStyle(
                        context: context, color: Colors.black, size: 3)),
              ),
              Expanded(
                flex: 2,
                child: Text('registration: ${widget.follower.registration}',
                    style: labelStyle(
                        context: context, color: Colors.black, size: 3)),
              ),
            ]),
          ]),
        ),
        leading: InitialsButton(
            radius: 20,
            initials: getInitials(
                name: '${widget.follower.forename} ${widget.follower.surname}'),
            onPressed: () => widget.onIconClick(widget.index),
            backgroundColor:
                uiColours.keys.toList()[widget.follower.iconColour]),
        onLongPress: () => widget.onLongPress(widget.index), //() => {},
      ),
    );
  }
  /// Whether they've joined, and - once their car has reported - how far
  /// away it is
  void calcStatus() {
    if (widget.follower.email == Setup().user.email) {
      _status = '(tracked with this device)';
      return;
    }
    int accepted = widget.follower.accepted;
    _status = accepted >= 0 && accepted < _statuses.length
        ? _statuses[accepted]
        : '';
    List<double> position = widget.follower.position;
    Point here = widget.currentPosition;
    if ((position[0] == 0 && position[1] == 0) || (here.x == 0 && here.y == 0)) {
      return;
    }
    double distance = Geolocator.distanceBetween(
        here.y.toDouble(), here.x.toDouble(), position[1], position[0]);
    String away = distance > 1000
        ? '${(distance * metersToMiles).toStringAsFixed(1)} miles away'
        : '${distance.round()} metres away';
    _status = _status.isEmpty
        ? '($away)'
        : '${_status.substring(0, _status.length - 1)}, $away)';
  }
}
