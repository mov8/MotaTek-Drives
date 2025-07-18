import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/utilities.dart';

class FollowerTile extends StatefulWidget {
  final Follower follower;
  // final AsyncCallback onLoadTrip;
  final Future<void> Function(int) onIconClick;
  final Function(int) onLongPress;
  final int index;
  final double distance;
  const FollowerTile({
    super.key,
    required this.index,
    required this.follower,
    required this.onIconClick,
    required this.onLongPress,
    required this.distance,
  });

  @override
  State<FollowerTile> createState() => _FollowerTileState();
}

class _FollowerTileState extends State<FollowerTile> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
        title: Text(
          '${widget.follower.forename} ${widget.follower.surname} (${widget.follower.forename == 'Frank' ? 5 : 9} mins)',
          style: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        subtitle:
            Text('${widget.follower.car} reg: ${widget.follower.registration}'),
        leading: ElevatedButton(
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

          child: Text(
            getInitials(
                name: '${widget.follower.forename} ${widget.follower.surname}'),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
