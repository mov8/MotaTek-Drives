import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/utilities.dart';

class GroupDriveEnviteeTile extends StatefulWidget {
  final EventInvitation invitation;
  final Function(int)? onEdit;
  final Function(int)? onDelete;
  final Function(int)? onSelect;

  final int index;
  const GroupDriveEnviteeTile(
      {super.key,
      required this.index,
      required this.invitation,
      this.onEdit,
      this.onDelete,
      this.onSelect});

  @override
  State<GroupDriveEnviteeTile> createState() => _GroupDriveEnviteeTileState();
}

class _GroupDriveEnviteeTileState extends State<GroupDriveEnviteeTile> {
  List<IconData> invIcons = [
    Icons.thumbs_up_down_outlined,
    Icons.thumb_down_off_alt_outlined,
    Icons.thumb_up_off_alt_outlined,
    Icons.check_box_outlined,
    Icons.check_box_outline_blank,
  ];
  List<String> invState = ['undecided', 'declined', 'accepted'];
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      //  child: Expanded(

      child: ListTile(

          //   style: ListTileStyle(),
          onLongPress: () => widget.onEdit!(widget.index),
          //    tileColor: Color(0xFFC2DFE7),
          leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                getInitials(
                    name:
                        '${widget.invitation.forename} ${widget.invitation.surname}'),
                overflow: TextOverflow.ellipsis,
              )),
          trailing: threeWayButton(),
          title: Text(
            '${widget.invitation.forename} ${widget.invitation.surname}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'email: ${widget.invitation.email} ',
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
            Row(children: [
              Expanded(
                flex: 1,
                child: Text(
                  'phone: ${widget.invitation.phone}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ]),
          ])

          // onLongPress: () => widget.onLongPress(widget.index),
          ),
      // ),
    );
  }

  TextStyle getStyle(value) {
    return TextStyle(
        decoration: widget.invitation.accepted == value
            ? TextDecoration.underline
            : TextDecoration.none,
        fontWeight: widget.invitation.accepted == value
            ? FontWeight.bold
            : FontWeight.normal);
  }

  IconButton threeWayButton() {
    int iconIdx = 0;
    if (widget.invitation.accepted < 3) {
      iconIdx = widget.invitation.accepted;
    } else {
      iconIdx = widget.invitation.selected ? 3 : 4; // 4 = un-checked
    }
    return IconButton(
        icon: Icon(invIcons[iconIdx]),
        onPressed: () => widget.onSelect!(widget.index));
  }
}
