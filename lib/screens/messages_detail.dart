import 'dart:developer' as developer;
import '/constants.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/tiles/tiles.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '/theme.dart';

class MessageDetailsForm extends StatefulWidget {
  final List<Message> messages;
  // The conversation: the group's id, or the person's email
  final String groupId;
  final String email;
  final bool isGroup;
  // The last message is the one being written - shown once the user asks
  // to write one (the app bar's + button)
  final bool writing;

  final sio.Socket socket;

  const MessageDetailsForm(
      {super.key,
      required this.socket,
      required this.messages,
      this.groupId = '',
      required this.email,
      this.isGroup = false,
      this.writing = false});
  @override
  State<MessageDetailsForm> createState() => _MessageDetailsFormState();
}

class _MessageDetailsFormState extends State<MessageDetailsForm> {
  int group = 0;
  List<Group> groups = [];
  String groupName = 'Driving Group';

  @override
  void initState() {
    super.initState();
  }

  Future<bool> dataFromWeb() async {
    Future.delayed(Duration(milliseconds: 200));
    return true;
  }

  void appendEmptyMessage() {
    widget.messages.add(
      Message(
          id: '',
          sender: '${Setup().user.forename} ${Setup().user.surname}',
          sent: true,
          message: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return portraitView();
  }

  Widget portraitView() {
    return Column(
      children: [
        for (int index = 0;
            index < widget.messages.length - (widget.writing ? 0 : 1);
            index++) ...[
          Dismissible(
            key: UniqueKey(), // Key('gmlt$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {},
            background: Container(color: DrivesColours.current.neutral),
            child: WriteMessageTile(
              index: index,
              message: widget.messages[index],
              onDismiss: (index, action) =>
                  dismissAction(index: index, action: action),
              onSelect: (_) => sendMessage(index),
              readOnly: (index < widget.messages.length - 1),
              isGroup: widget.isGroup,
            ),
          ),
        ],
      ],
    );
  }

  dismissAction({required int index, required int action}) {}

  void sendMessage(int index) {
    widget.messages.last.dated = dateFormatDoc.format(DateTime.now());
    if (widget.isGroup) {
      widget.socket.emit('group_message', {
        'group_id': widget.groupId,
        'message': widget.messages.last.message
      });
    } else {
      try {
        widget.socket.emit('user_message', {
          'message': widget.messages.last.message,
          'token': Setup().jwt,
          'user_email': widget.email,
        });
      } catch (e) {
        developer.log('user_message error: ${e.toString()}', name: 'error');
      }
    }
    setState(() => appendEmptyMessage());
  }

  void onDelete(int index) {
    return;
  }
}
