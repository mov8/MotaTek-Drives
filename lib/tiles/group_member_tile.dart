import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/utilities.dart';

class GroupMemberTile extends StatefulWidget {
  final GroupMember groupMember;
  final Function(int) onEdit;
  final Function(int) onDelete;

  final int index;
  const GroupMemberTile({
    super.key,
    required this.index,
    required this.groupMember,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<GroupMemberTile> createState() => _groupMemberTileState();
}

class _groupMemberTileState extends State<GroupMemberTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.groupMember.edited) {
      debugPrint('GroupMember ${widget.groupMember.forename} edited');
    } else {
      debugPrint('GroupMember ${widget.groupMember.forename} NOT edited');
    }
    return Material(
        child: Card(
            child: ListTile(
                //   style: ListTileStyle(),
                tileColor: Colors.white24,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      getInitials(
                          name:
                              '${widget.groupMember.forename} ${widget.groupMember.surname}'),
                      overflow: TextOverflow.ellipsis,
                    )),
                trailing: IconButton(
                  iconSize: 30,
                  icon: const Icon(Icons.edit),
                  onPressed: () => widget.onEdit(widget.index),
                ),
                title: Text(
                  '${widget.groupMember.forename} ${widget.groupMember.surname}${widget.groupMember.edited ? '*' : ''}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: Text('email: ${widget.groupMember.email} ',
                              style: const TextStyle(fontSize: 18)))
                    ],
                  ),
                  Row(children: [
                    Expanded(
                        flex: 1,
                        child: Text('phone: ${widget.groupMember.phone}',
                            style: const TextStyle(fontSize: 18))),
                  ]),
                ]))

            // onLongPress: () => widget.onLongPress(widget.index),
            ));
  }
}
