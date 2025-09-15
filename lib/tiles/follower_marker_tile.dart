import 'package:flutter/material.dart';

class FollowerMarkerTile extends StatefulWidget {
  final int index;
  final String manufacturer;
  final String model;
  final String colour;
  final String registration;

  const FollowerMarkerTile({
    super.key,
    required this.index,
    this.manufacturer = '',
    this.model = '',
    this.colour = '',
    this.registration = '',
  });

  @override
  State<FollowerMarkerTile> createState() => _FollowerMarkerTileState();
}

class _FollowerMarkerTileState extends State<FollowerMarkerTile> {
  String status = '(not yet joined)';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Card(
        child: SizedBox(
          height: 120,
          width: 150,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${widget.manufacturer} ${widget.model}',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(
              'Colour ${widget.colour}',
              style: const TextStyle(
                  fontSize: 18, overflow: TextOverflow.ellipsis),
            ),
            Text(
              'Registration ${widget.registration}',
              style: const TextStyle(
                  fontSize: 18, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
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
