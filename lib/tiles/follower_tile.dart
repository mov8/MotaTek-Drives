import '/classes/initials_button.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/utilities.dart';
import '/helpers/edit_helpers.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '/constants.dart';

class FollowerTile extends StatefulWidget {
  final Follower follower;
  // final AsyncCallback onLoadTrip;

  final Future<void> Function(int) onIconClick;
  final Function(int) onLongPress;
  final int index;
  final double distance;
  final LatLng currentPosition;
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
        //  shape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.all(
        //       Radius.circular(10),
        //     ),
        //   ),
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
            /*
            Row(children: [
             
              Expanded(
                flex: 1,
                child: Text('make: ${widget.follower.manufacturer}'),
              ),
              Expanded(
                flex: 2,
                child: Text('model: ${widget.follower.model}'),
              ),
            ]),
            */
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

  changePosition({LatLng position = const LatLng(0, 0)}) {
    if (widget.follower.position != LatLng(0.0, 0.0)) {
      double distance = Geolocator.distanceBetween(
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
          widget.follower.position.latitude,
          widget.follower.position.longitude);
      if (distance > 1000) {
        _status =
            '(${(distance * metersToMiles).toStringAsFixed(1)} miles away)';
      } else {
        _status = '(${distance.round()} meters away)';
      }
    }
  }

  calcStatus() {
    _status = '(tracked with this device)';
    if (widget.follower.email != Setup().user.email) {
      _status = _statuses[widget.follower.accepted];
      if (widget.follower.position != LatLng(0.0, 0.0)) {
        double distance = Geolocator.distanceBetween(
            widget.currentPosition.latitude,
            widget.currentPosition.longitude,
            widget.follower.position.latitude,
            widget.follower.position.longitude);
        if (distance > 1000) {
          _status =
              '(${(distance * metersToMiles).toStringAsFixed(1)} miles away)';
        } else {
          _status = '(${distance.round()} meters away)';
        }
      }
      return;
    }
  }
}

/*

May want to display when last pinged
var startTime = DateTime(2020, 02, 20, 10, 30); // TODO: change this to your DateTime from firebase
var currentTime = DateTime.now();
var diff = currentTime.difference(startTime).inDays;
 */
