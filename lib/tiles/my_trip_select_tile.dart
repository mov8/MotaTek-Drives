import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';

class MyTripSelectTile extends StatefulWidget {
  final MyTripItem myTripItem;
  final List<GroupDriveByGroup> groupDrivers;
  final void Function(List<Map<String, dynamic>>)? onSelect;
  final int index;
  const MyTripSelectTile({
    super.key,
    required this.index,
    required this.myTripItem,
    required this.groupDrivers,
    this.onSelect,
  });

  @override
  State<MyTripSelectTile> createState() => _MyTripSelectTileState();
}

class _MyTripSelectTileState extends State<MyTripSelectTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: SingleChildScrollView(
          child: ExpansionTile(
            title: Text(
              widget.myTripItem.heading,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.myTripItem.getPublishedDate(
                  noPrompt: 'not yet published - will be if chosen'),
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal),
            ),
            children: [
              if (widget.groupDrivers.isEmpty) ...[
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 200,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(
                          0,
                          (MediaQuery.of(context).size.height - 550) / 2,
                          0,
                          30),
                      child: Column(
                        children: [
                          Text(
                            "Group drives need groups setting up first.",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Create one and save it.",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (widget.groupDrivers.isNotEmpty) ...[
                DriveInvitations(
                  index: widget.index,
                  groupDrivers: widget.groupDrivers,
                  myTripItem: widget.myTripItem,
                  onSelect: (value) => widget.onSelect!(value),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
