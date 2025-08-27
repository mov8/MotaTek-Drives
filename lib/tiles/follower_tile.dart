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
  @override
  Widget build(BuildContext context) {
    String status = '(not yet joined)';
    if (widget.follower.position != LatLng(0.0, 0.0)) {
      double distance = Geolocator.distanceBetween(
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
          widget.follower.position.latitude,
          widget.follower.position.longitude);
      if (distance > 1000) {
        status =
            '(${(distance * metersToMiles).toStringAsFixed(1)} miles away)';
      } else {
        status = '(${distance.round()} meters away)';
      }
    }

    return Material(
      child: ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
        title: SizedBox(
          height: 80,
          width: MediaQuery.of(context).size.width - 100,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${widget.follower.forename} ${widget.follower.surname}',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(
              status,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            ),
          ]),
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
            initials: getInitials(
                name: '${widget.follower.forename} ${widget.follower.surname}'),
            onPressed: () => widget.onIconClick(widget.index),
            backgroundColor:
                uiColours.keys.toList()[widget.follower.iconColour]),

        /* ElevatedButton(
          style: ElevatedButton.styleFrom(
            // maximumSize: const Size(20, 20),
            // fixedSize: const Size(55, 55),
            backgroundColor: uiColours.keys.toList()[widget.follower
                .iconColour], //widget.follower.iconColour, // Button color
            foregroundColor: Colors.black, // Text color
            shadowColor: Colors.grey, // Shadow color
            elevation: 5,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          onPressed: () =>
              widget.onIconClick(widget.index), // Handle button tap

          child: Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              0,
            ),
            child: Text(
              getInitials(
                  name:
                      '${widget.follower.forename} ${widget.follower.surname}'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        */
        onLongPress: () => widget.onLongPress(widget.index), //() => {},
      ),
    );
  }
}

/*

May want to display when last pinged
var startTime = DateTime(2020, 02, 20, 10, 30); // TODO: change this to your DateTime from firebase
var currentTime = DateTime.now();
var diff = currentTime.difference(startTime).inDays;
 */
