import 'package:flutter/material.dart';
import '/models/other_models.dart';
import 'package:intl/intl.dart';

class MessageTile extends StatefulWidget {
  final MessageLocal message;
  final Function(int) onEdit;
  final Function(int) onSelect;

  final int index;
  const MessageTile({
    super.key,
    required this.index,
    required this.message,
    required this.onEdit,
    required this.onSelect,
  });

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => setState(() {
        widget.message.selected = !widget.message.selected;
        widget.onSelect(widget.index);
      }),
      onLongPress: () => widget.onEdit(widget.index),
      leading: IconButton(
          onPressed: () {
            setState(() {
              widget.message.read = !widget.message.read;
              //!widget.message.read;
            });
          },

          //onEdit(index),
          icon: Icon(
            widget.message.read ? Icons.mark_chat_read : Icons.mark_chat_unread,
            size: 25,
          )),
      trailing: widget.message.selected
          ? const Icon(
              Icons.check_box,
              size: 20,
            )
          : null,
      title: Row(children: [
        Expanded(
          flex: 5,
          child: Column(children: [
            Row(children: [
              Expanded(
                  flex: 1,
                  child: Text(
                    '${widget.message.groupMember.forename} ${widget.message.groupMember.surname}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )),
              Expanded(
                  flex: 1,
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        ' ${dateFormat.format(widget.message.received)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ))),
            ]),
            Row(children: [
              Expanded(
                  child: Text(
                'message: ${widget.message.message}',
                style: const TextStyle(fontSize: 14),
                softWrap: true,
              ))
            ]),
          ]),
        )
      ]),
    );
  }
}
