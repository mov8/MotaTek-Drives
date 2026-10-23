import 'package:flutter/material.dart';
import '/helpers/edit_helpers.dart';

class FollowerMarkerTile extends StatefulWidget {
  final int index;
  final String manufacturer;
  final String model;
  final String colour;
  final String registration;

  const FollowerMarkerTile({
    super.key,
    required this.index,
    required BuildContext context,
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
            Text('${widget.manufacturer} ${widget.model}',
                style:
                    textStyle(context: context, color: Colors.black, size: 2)),
            Text(
              'Colour ${widget.colour}',
              style: textStyle(context: context, color: Colors.black, size: 2),
            ),
            Text(
              'Registration ${widget.registration}',
              style: textStyle(context: context, color: Colors.black, size: 2),
            ),
          ]),
        ),
      ),
    );
  }
}
