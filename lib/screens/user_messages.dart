import 'package:drives/tiles/group_message_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drives/constants.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

import 'package:socket_io_client/socket_io_client.dart' as sio;

class UserMessagesController {
  _UserMessagesState? _userMessagesState;

  void _addState(_UserMessagesState serMessagesState) {
    _userMessagesState = serMessagesState;
  }

  bool get isAttached => _userMessagesState != null;

  void leave() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _userMessagesState?.leave();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class UserMessages extends StatefulWidget {
  // var setup;
  final UserMessagesController controller;
  final Function(int)? onSelect;
  final Function(int)? onCancel;
  final User user;
  const UserMessages({
    super.key,
    required this.controller,
    required this.user,
    this.onSelect,
    this.onCancel,
  });

  @override
  State<UserMessages> createState() => _UserMessagesState();
}

class _UserMessagesState extends State<UserMessages> {
  int group = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<Message> messages = [];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  String testString = '';
  bool addingMember = false;
  bool addingGroup = false;
  bool editingGroup = false;

  List<GroupMember> allMembers = [];
  StreamSocket streamSocket = StreamSocket();

  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  // final _channel = WebSocketChannel.connect(
  // Uri.parse('wss://echo.websocket.events'),
  //  'http://10.101.1.150:5000/'
  //  Uri.parse('ws://10.101.1.150:5000/socket.io/'),
  // );
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    // dataloaded = dataFromDatabase();
    dataloaded = dataFromWeb();
    widget.controller._addState(this);

    socket.onConnect((_) => debugPrint('connecting'));
    socket.onConnectError((_) => debugPrint('connect error'));
    socket.onConnectError((_) => debugPrint('connect error'));

    socket.onError((data) => debugPrint('Error: ${data.toString()}'));

    socket.on('text', (data) {
      try {
        messages[messages.length - 1] = Message.fromSocketMap(data);
        messages.add(Message(
          id: '',
          sender: '${Setup().user.forename} ${Setup().user.surname}',
          message: '',
        ));
        // widget.user.messages = messages.length;
        setState(() {});
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    });

    socket.connect();
    debugPrint('should have connected');
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    if (socket.connected) {
      try {
        socket.emit('cleave');
      } catch (e) {
        debugPrint('error disposing of group_messages: ${e.toString()}');
      }
    }

    fn1.dispose();
    streamSocket.dispose();
    super.dispose();
  }

  void leave() {
    widget.onCancel!(1);
    if (socket.connected) {
      socket.emit('cleave');
    }
    Navigator.pop(context);
  }

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    messages = await getUserMessages(widget.user);
    messages.add(Message(
      id: '',
      sender: '${Setup().user.forename} ${Setup().user.surname}',
      message: '',
    ));
    return true;
  }

  void onSendMessage(int index) {
    socket.emit('group_message', messages[index].message);
    widget.onSelect!(index);
    return;
  }

  Widget portraitView() {
    debugPrint('PortraitView() called...');
    return RefreshIndicator(
      onRefresh: () async {
        await dataFromWeb();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) => GroupMessageTile(
                  index: index,
                  message: messages[index],
                  onDismiss: (_) => (),
                  onSelect: (_) => onSendMessage(index),
                  readOnly: (index < messages.length - 1),
                ),
              ),
            ),
          ],
        ),
      ),
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
          debugPrint('Snapshot has data:');
          return portraitView();
        } else {
          return const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator()));
        }
        throw ('Error - FutureBuilder group_messages.dart');
      },
    );
  }
}
