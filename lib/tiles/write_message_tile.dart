import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:intl/intl.dart';
import 'package:drives/classes/utilities.dart';

class WriteMessageTile extends StatefulWidget {
  final Message message;
  final bool readOnly;
  final bool isGroup;
  final Function(int, int) onDismiss;
  final Function(int) onSelect;

  final int index;
  const WriteMessageTile({
    super.key,
    required this.index,
    required this.message,
    required this.onDismiss,
    required this.onSelect,
    this.readOnly = true,
    this.isGroup = true,
  });

  @override
  State<WriteMessageTile> createState() => _WriteMessageTileState();
}

class _WriteMessageTileState extends State<WriteMessageTile> {
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  late bool originator;
  late Future<bool> canDismissItem;
  @override
  void initState() {
    super.initState();
    originator = widget.message.sent;
    developer.log(
        'id: ${widget.message.id} message: ${widget.message.message} sent: ${widget.message.sent.toString()}',
        name: '_mail');
    if (widget.message.sender.isEmpty) {
      debugPrint('sender empty index : ${widget.index}');
    }
  }

  Future<bool> canDismiss() {
    return canDismissItem;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.readOnly
          ? originator
              ? const EdgeInsets.fromLTRB(20, 0, 0, 0)
              : const EdgeInsets.fromLTRB(0, 0, 20, 0)
          : const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Dismissible(
        key: UniqueKey(),
        direction: getDismissDirection(),
        onDismissed: (direction) {
          debugPrint('onDismiss');
          widget.onDismiss(
              widget.index, direction == DismissDirection.endToStart ? 0 : 1);
        },
        background: Container(color: Colors.blueGrey),
        child: Card(
          color: originator && widget.readOnly ? Colors.blue : null,
          elevation: 5,
          child: ListTile(
            leading: getLeading(),
            title: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Row(children: [
                        if (widget.readOnly && !originator) ...[
                          Expanded(
                              flex: 1,
                              child: Text(
                                widget.message.sender,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
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
                              ),
                            ),
                          ),
                        ]
                      ]),
                      Row(
                        children: [
                          if (!widget.readOnly) ...[
                            Expanded(
                              flex: 20,
                              child: TextFormField(
                                readOnly: widget.readOnly,
                                autofocus: false,
                                maxLines:
                                    null, // these 2 lines allow multiline wrapping
                                keyboardType: TextInputType.multiline,
                                textAlign: TextAlign.start,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.send,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      10.0, 0.0, 10.0, 10.0),
                                  focusColor: Colors.blueGrey,
                                  hintText: 'write your message.',
                                  labelText:
                                      '${widget.isGroup ? 'Group ' : ''}Message',
                                  suffix: widget.readOnly
                                      ? null
                                      : IconButton(
                                          onPressed: () =>
                                              widget.onSelect(widget.index),
                                          icon: const Icon(
                                            Icons.send,
                                            size: 25,
                                          ),
                                        ),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                                initialValue: widget.message.message,
                                onChanged: (text) => setState(
                                  () {
                                    widget.message.message = text;
                                  },
                                ),
                              ),
                            )
                          ] else ...[
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          widget.message.message,
                                          style: TextStyle(
                                              color: originator
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                  if (originator) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              widget.message.dated,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.normal),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  DismissDirection getDismissDirection() {
    if (widget.isGroup) {
      if (originator) {
        return DismissDirection.startToEnd;
      } else {
        return DismissDirection.none;
      }
    } else {
      return DismissDirection.horizontal;
    }
  }

  Widget? getLeading() {
    if (widget.readOnly) {
      if (!originator) {
        if (widget.isGroup) {
          return CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(getInitials(name: widget.message.sender)),
          );
        } else {
          if (widget.message.read) {
            return Icon(Icons.mark_chat_read_outlined, size: 18);
          } else {
            return Icon(Icons.mark_chat_unread_outlined, size: 18);
          }
        }
      }
    }
    return null;
  }

  bool dismissAction(DismissDirection direction) {
    if (widget.readOnly) {
      if (widget.isGroup && widget.message.sent) {
        return direction == DismissDirection.endToStart;
      }
      if (!widget.isGroup) {
        return true;
      }
    }
    return false;
  }
}
