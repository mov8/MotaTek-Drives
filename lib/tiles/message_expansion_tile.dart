import 'package:drives/tiles/write_message_tile.dart';
import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/other_models.dart';

class MessageExpansionTile extends StatefulWidget {
  final MailItem mailItem;
  final List<Message> messages;
  final Function(int)? onSelect;
  final Function(int, int)? onDismiss;
  final Function(int, bool)? onOpen;
  final bool expanded;

  final int index;
  const MessageExpansionTile(
      {super.key,
      required this.index,
      required this.mailItem,
      this.messages = const [],
      this.onSelect,
      this.onDismiss,
      this.onOpen,
      this.expanded = false});

  @override
  State<MessageExpansionTile> createState() => _MessageByGroupTileState();
}

class _MessageByGroupTileState extends State<MessageExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: ExpansionTile(
        // onTap: () => widget.onSelect!(widget.index),
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
        onExpansionChanged: (value) => widget.onOpen!(widget.index, value),
        initiallyExpanded: widget.expanded,
        children: List.generate(
          widget.messages.length,
          (index) => Dismissible(
            key: UniqueKey(), // Key('gmlt$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => (),

            background: Container(color: Colors.blueGrey),
            child: WriteMessageTile(
              index: index,
              message: widget.messages[index],
              onDismiss: (index, action) =>
                  dismissAction(index: index, action: action),
              onSelect: (_) => onSendMessage(index),
              readOnly: (index < widget.messages.length - 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList({
    int index = 0,
  }) {
    return Text('Hi $index');
  }

  Future<void> dismissAction({required int index, required int action}) async {
    String id = widget.messages[index].id;

    if (action == 0) {
      //  await deleteMessage(messageId: id);
      //  setState(() => messages.removeAt(index));
    } else {
      //  await updateMessage(messageId: id);
    }
  }

  void onSendMessage(int index) {
    // socket.emit('group_message', messages[index].message);
    /*
    messages[index].sent = true;
    messages[index].dated = dateFormatDocTime.format(DateTime.now());
    messages.add(Message(
      id: '',
      sender: '${Setup().user.forename} ${Setup().user.surname}',
      message: '',
    ));
    */
    widget.onSelect!(index);
    return;
  }
}
