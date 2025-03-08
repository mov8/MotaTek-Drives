import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/utilities.dart';

class GroupMemberTile extends StatefulWidget {
  final GroupMember groupMember;
  final Function(int)? onEdit;
  final Function(int)? onDelete;
  final Function(int)? onSelect;

  final int index;
  const GroupMemberTile(
      {super.key,
      required this.index,
      required this.groupMember,
      this.onEdit,
      this.onDelete,
      this.onSelect});

  @override
  State<GroupMemberTile> createState() => _GroupMemberTileState();
}

class _GroupMemberTileState extends State<GroupMemberTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.groupMember.edited) {
      debugPrint('GroupMember ${widget.groupMember.forename} edited');
    } else {
      debugPrint('GroupMember ${widget.groupMember.forename} NOT edited');
    }
    return Card(
      elevation: 5,
      child: ListTile(
        onLongPress: () => widget.onEdit!(widget.index),
        leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              getInitials(
                  name:
                      '${widget.groupMember.forename} ${widget.groupMember.surname}'),
              overflow: TextOverflow.ellipsis,
            )),
        trailing: widget.onSelect == null
            ? IconButton(
                iconSize: 30,
                icon: Icon(widget.onSelect == null
                    ? Icons.edit
                    : widget.groupMember.selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank_sharp),
                onPressed: () => setState(() => widget.onEdit!(widget.index)),
              )
            : IconButton(
                iconSize: 22,
                icon: Icon(widget.groupMember.selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank),
                onPressed: () => widget.onSelect!(widget.index),
              ),
        title: Text(
          '${widget.groupMember.forename} ${widget.groupMember.surname}${widget.groupMember.edited ? '*' : ''}',
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
                    'email: ${widget.groupMember.email} ',
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
                    'phone: ${widget.groupMember.phone}',
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
