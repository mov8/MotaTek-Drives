import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';

class GroupDriveAddDriversTile extends StatefulWidget {
  final MyTripItem myTripItem;
  final List<Group> groups;
  final void Function(int)? onSelectTrip;
  final void Function(int, bool)? onExpandChange;
  final int index;
  const GroupDriveAddDriversTile({
    super.key,
    required this.index,
    required this.myTripItem,
    required this.groups,
    required this.onSelectTrip,
    this.onExpandChange,
  });

  @override
  State<GroupDriveAddDriversTile> createState() =>
      _GroupDriveAddDriversTileState();
}

class _GroupDriveAddDriversTileState extends State<GroupDriveAddDriversTile> {
  late GroupTileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GroupTileController();
  }

  @override
  Widget build(BuildContext context) {
    // List<Photo> photos = photosFromJson(widget.myTripItem.images);
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                flex: 1,
                child: Icon(Icons.directions_car_outlined, size: 35),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: Text(
                  widget.myTripItem.heading,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: const Text(
            'Choose drivers to invite',
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onExpansionChanged: (expanded) {
            //  widget.onExpandChange!(widget.index, expanded);
          },
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 250,
              child: Column(
                children: [
                  if (widget.groups.isEmpty) ...[
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height - 250,
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(
                              0,
                              (MediaQuery.of(context).size.height - 400) / 2,
                              0,
                              30),
                          child: Column(
                            children: [
                              Text(
                                "You haven't created any groups yet.",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Create one with the people you'd like to invite.",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: widget.groups.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 5.0),
                        child: GroupTile(
                          group: widget.groups[index],
                          controller: _controller,
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
