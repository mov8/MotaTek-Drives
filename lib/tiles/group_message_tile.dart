import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:intl/intl.dart';
import 'package:drives/classes/utilities.dart';

class GroupMessageTile extends StatefulWidget {
  final Message message;
  final bool readOnly;
  final Function(int) onDismiss;
  final Function(int) onSelect;

  final int index;
  const GroupMessageTile({
    super.key,
    required this.index,
    required this.message,
    required this.onDismiss,
    required this.onSelect,
    this.readOnly = true,
  });

  @override
  State<GroupMessageTile> createState() => _GroupMessageTileState();
}

class _GroupMessageTileState extends State<GroupMessageTile> {
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  late bool originator;
  late Future<bool> canDismissItem;
  @override
  void initState() {
    super.initState();
    originator = '${Setup().user.forename} ${Setup().user.surname}' ==
        widget.message.sender;
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
        key: Key('mt${widget.index}'),
        onDismissed: (direction) => widget.onDismiss(widget.index),
        confirmDismiss: (derection) => canDismissItem,
        background: Container(color: Colors.blueGrey),
        child: Card(
          color: originator && widget.readOnly ? Colors.blue : null,
          elevation: 5,
          child: ListTile(
            leading: widget.readOnly && !originator
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
                          textInputAction: TextInputAction.send,
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
                                              fontWeight: FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          )),
                    ]
                  ]),
                ]),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
