import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/classes/my_trip_item.dart';

class GroupDriveAddTile extends StatefulWidget {
  final List<MyTripItem> myTripItems;
  final List<GroupDriveByGroup> groupDrivers;
  final void Function(List<Map<String, dynamic>>)? onSelectTrip;
  final void Function(int, bool)? onExpandChange;
  final int index;
  const GroupDriveAddTile({
    super.key,
    required this.index,
    required this.myTripItems,
    required this.groupDrivers,
    required this.onSelectTrip,
    this.onExpandChange,
  });

  @override
  State<GroupDriveAddTile> createState() => _GroupDriveAddTileState();
}

class _GroupDriveAddTileState extends State<GroupDriveAddTile> {
  //int _driveIndex = -1;
  @override
  Widget build(BuildContext context) {
    // List<Photo> photos = photosFromJson(widget.myTripItem.images);
    return Column(
      children: [
        Text(
          'Choose one of your saved drives to share',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (widget.myTripItems.isEmpty) ...[
          Center(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(
                    0, (MediaQuery.of(context).size.height - 400) / 2, 0, 30),
                child: Column(
                  children: [
                    Text("You must have a drive to share.",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("You haven't created and saved any trips yet.",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text(
                      "Create one in My Trip and save it.",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        //  Expanded(
        //    flex: 1,
        //    child:
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          // This tells the
          //ListView to calculate its full height based on its children.
          // WARNING: This is bad for performance on very long lists!
          shrinkWrap: true,
          itemCount: widget.myTripItems.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
            child: MyTripSelectTile(
              myTripItem: widget.myTripItems[index],
              groupDrivers: widget.groupDrivers,
              onSelect: (value) => widget.onSelectTrip!(value),
              index: index,
            ),
          ),
        ),
        //  ),
      ],
    );
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
