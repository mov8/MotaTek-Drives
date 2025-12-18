import '/constants.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import '/tiles/tiles.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

class MessageDetailsForm extends StatefulWidget {
  // var setup;
  final MailItem mailItem;
  final sio.Socket socket;
  const MessageDetailsForm(
      {super.key, required this.mailItem, required this.socket});
  @override
  State<MessageDetailsForm> createState() => _MessageDetailsFormState();
}

class _MessageDetailsFormState extends State<MessageDetailsForm> {
  int group = 0;
  late Future<bool> dataloaded;
  List<Group> groups = [];
  List<Message> _messages = [];

  String groupName = 'Driving Group';

  @override
  void initState() {
    super.initState();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    if (widget.mailItem.isGroup) {
      widget.socket.emit('leave_group');
    }
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    if (widget.mailItem.isGroup) {
      _messages = await getGroupMessages(widget.mailItem.id);
      widget.socket.emit(
          'group_join', {'token': Setup().jwt, 'group': widget.mailItem.id});
    } else {
      _messages = await getUserMessages(widget.mailItem.id);
    }
    appendEmptyMessage();
    return true;
  }

  void appendEmptyMessage() {
    _messages.add(
      Message(
          id: '',
          sender: '${Setup().user.forename} ${Setup().user.surname}',
          sent: true,
          message: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: dataloaded,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Snapshot has error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return portraitView();
        } else {
          return const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          );
        }
        throw ('Error - FutureBuilder group.dart');
      },
      //  ),
    );
  }

  Widget portraitView() {
    return ListView(
      children: List.generate(
        _messages.length,
        (index) => Dismissible(
          key: UniqueKey(), // Key('gmlt$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => (),

          background: Container(color: Colors.blueGrey),
          child: WriteMessageTile(
            index: index,
            message: _messages[index],
            onDismiss: (index, action) =>
                dismissAction(index: index, action: action),
            onSelect: (_) => sendMessage(index),
            readOnly: (index < _messages.length - 1),
          ),
        ),
      ),
    );
  }

  dismissAction({required int index, required int action}) {}

  void sendMessage(int index) {
    if (widget.mailItem.isGroup) {
      widget.socket
          .emit('group_message', _messages[_messages.length - 1].message);
    } else {
      try {
        widget.socket.emit('user_message', {
          'message': _messages[_messages.length - 1].message,
          'token': Setup().jwt,
          'user_email': widget.mailItem.email,
        });
        _messages[_messages.length - 1].dated =
            dateFormatDoc.format(DateTime.now());
      } catch (e) {
        // developer.log('user_message error: ${e.toString()}', name: '_messages');
      }
      //  setState(() => appendEmptyMessage());
    }
    setState(() => appendEmptyMessage());
  }

  void onDelete(int index) {
    return;
  }
}
