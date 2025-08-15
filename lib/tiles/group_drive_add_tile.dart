import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/classes/my_trip_item.dart';

class GroupDriveAddTile extends StatefulWidget {
  final List<MyTripItem> myTripItems;
  final List<GroupDriveByGroup> groupDrivers;
  final void Function(int)? onSelectTrip;
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
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          title: const Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Icon(Icons.directions_car_outlined, size: 35)),
              SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: Text(
                  'Plan a new group drive',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: const Text(
            'Choose one of your saved drives to share',
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onExpansionChanged: (expanded) {
            //  widget.onExpandChange!(widget.index, expanded);
          },
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              // child:
              //  SingleChildScrollView(
              //   child:
              // Expanded(
              child: Column(
                children: [
                  if (widget.myTripItems.isEmpty) ...[
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
                                  "You haven't created and saved any trips yet.",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text("Create one in My Trip and save it.",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: widget.myTripItems.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 5.0),
                        child: MyTripSelectTile(
                          myTripItem: widget.myTripItems[index],
                          groupDrivers: widget.groupDrivers,
                          //  onSelect: (idx) => setState(() => _driveIndex = idx),
                          //  controller: _controller,
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //     ),
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
