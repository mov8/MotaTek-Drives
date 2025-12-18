import 'package:flutter/material.dart';
import '/classes/classes.dart';

class MessageByGroupTile extends StatefulWidget {
  final MailItem mailItem;

  final Function(int)? onSelect;
  final Function(int)? onOpen;

  final int index;
  const MessageByGroupTile(
      {super.key,
      required this.index,
      required this.mailItem,
      this.onSelect,
      this.onOpen});

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
        //  backgroundColor: Colors.transparent,
        leading: Badge.count(
          backgroundColor: widget.mailItem.unreadMessages > 0
              ? const Color.fromRGBO(158, 14, 4, 1)
              : const Color.fromARGB(255, 91, 129, 194),
          textColor: widget.mailItem.unreadMessages > 0
              ? Colors.white
              : const Color.fromRGBO(241, 238, 238, 1),
          count: widget.mailItem.unreadMessages,
          child: const Icon(Icons.messenger_outlined, size: 30),
        ),

        title: Text(
          '${widget.mailItem.name} ',
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
                    'messages: ${widget.mailItem.messages} ',
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
                    'unread messages: ${widget.mailItem.unreadMessages}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildList({
    int index = 0,
  }) {
    return Text('Hi $index');
  }
}
