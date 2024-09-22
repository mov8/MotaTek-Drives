import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:intl/intl.dart';

class GroupDriveTile extends StatefulWidget {
  final GroupDrive groupDrive;
  final Function(int)? onEdit;
  final Function(int)? onDelete;
  final Function(int)? onSelect;

  final int index;

  const GroupDriveTile(
      {super.key,
      required this.groupDrive,
      this.index = 0,
      this.onEdit,
      this.onDelete,
      this.onSelect});

  @override
  State<GroupDriveTile> createState() => _groupDriveTileState();
}

class _groupDriveTileState extends State<GroupDriveTile> {
  DateFormat dateFormat = DateFormat('d MMM y');
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: ListTile(
        leading: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.list_alt),
          onPressed: () => widget.onEdit!(widget.index),
        ),
        onLongPress: () => widget.onEdit!(widget.index),
        //    tileColor: Color(0xFFC2DFE7),
        trailing: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.delete),
          onPressed: () => widget.onDelete,
        ),
        title: Text(
          widget.groupDrive.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Drive date: ${dateFormat.format(widget.groupDrive.driveDate)} ',
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'invited: ${widget.groupDrive.pending} accepted: ${widget.groupDrive.accepted}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),

        // onLongPress: () => widget.onLongPress(widget.index),
      ),
    );
  }
}
