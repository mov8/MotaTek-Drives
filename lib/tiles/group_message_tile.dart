import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:intl/intl.dart';
import 'package:drives/utilities.dart';

class GroupMessageTile extends StatefulWidget {
  final Message message;
  final bool readOnly;
  final Function(int) onEdit;
  final Function(int) onSelect;

  final int index;
  const GroupMessageTile({
    super.key,
    required this.index,
    required this.message,
    required this.onEdit,
    required this.onSelect,
    this.readOnly = true,
  });

  @override
  State<GroupMessageTile> createState() => _GroupMessageTileState();
}

class _GroupMessageTileState extends State<GroupMessageTile> {
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        child: ListTile(
          leading: widget.readOnly
              ? CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(getInitials(name: widget.message.sender)),
                )
              : null,
          title: Row(children: [
            Expanded(
              flex: 5,
              child: Column(children: [
                Row(children: [
                  if (widget.readOnly) ...[
                    Expanded(
                        flex: 1,
                        child: Text(
                          widget.message.sender,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        )),
                    Expanded(
                        flex: 1,
                        child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              widget.message.dated,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ))),
                  ]
                ]),
                Row(children: [
                  if (!widget.readOnly) ...[
                    Expanded(
                        child: TextFormField(
                            readOnly: widget.readOnly,
                            autofocus: false,
                            maxLines:
                                null, // these 2 lines allow multiline wrapping
                            keyboardType: TextInputType.multiline,
                            textAlign: TextAlign.start,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.fromLTRB(
                                  10.0, 0.0, 10.0, 10.0),
                              focusColor: Colors.blueGrey,
                              hintText: 'write your message.',
                              labelText: 'Message',
                              suffix: widget.readOnly
                                  ? null
                                  : IconButton(
                                      onPressed: () =>
                                          widget.onSelect(widget.index),
                                      icon: const Icon(
                                        Icons.send,
                                        size: 25,
                                      )),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                            initialValue: widget.message.message,
                            onChanged: (text) => setState(() {
                                  widget.message.message = text;
                                })))
                  ] else ...[
                    Text(
                      widget.message.message,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    )
                  ]
                ]),
              ]),
            )
          ]),
        ));
  }
}
