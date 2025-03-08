import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';

class MessageByGroupTile extends StatefulWidget {
  final Group group;

  final Function(int)? onSelect;

  final int index;
  const MessageByGroupTile(
      {super.key, required this.index, required this.group, this.onSelect});

  @override
  State<MessageByGroupTile> createState() => _MessageByGroupTileState();
}

class _MessageByGroupTileState extends State<MessageByGroupTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: ListTile(
        onTap: () => widget.onSelect!(widget.index),
        leading: Badge(
          label: Text(widget.group.unreadMessages.toString()),
          child: const Icon(Icons.messenger_outlined),
        ),
        title: Text(
          '${widget.group.name} ',
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
                    'messages: ${widget.group.messages} ',
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
                    'unread messages: ${widget.group.unreadMessages}',
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
