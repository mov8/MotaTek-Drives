import 'package:drives/classes/initials_button.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/utilities.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drives/constants.dart';

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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
        title: SizedBox(
          height: 80,
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
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (widget.follower.email != Setup().user.email) ...[
                    Expanded(
                      flex: 2,
                      child: Text(
                        'track',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Checkbox(
                          value: widget.follower.track,
                          onChanged: (value) => setState(
                              () => widget.follower.track = value ?? false)),
                    ),
                  ],
                ],
              ),
              Text(
                _status,
                style: const TextStyle(overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        subtitle: SizedBox(
          height: 50,
          width: MediaQuery.of(context).size.width - 100,
          child: Column(children: [
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
            Row(children: [
              Expanded(
                flex: 1,
                child: Text('colour: ${widget.follower.carColour}'),
              ),
              Expanded(
                flex: 2,
                child: Text('registration: ${widget.follower.registration}'),
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
