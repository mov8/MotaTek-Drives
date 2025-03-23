import 'package:drives/tiles/group_message_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drives/constants.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

import 'package:socket_io_client/socket_io_client.dart' as sio;

class GroupMessagesController {
  _GroupMessagesState? _groupMessagesState;

  void _addState(_GroupMessagesState groupMessagesState) {
    _groupMessagesState = groupMessagesState;
  }

  bool get isAttached => _groupMessagesState != null;

  void leave() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _groupMessagesState?.leave();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class GroupMessages extends StatefulWidget {
  // var setup;
  final GroupMessagesController controller;
  final Function(int)? onSelect;
  final Function(int)? onCancel;
  final Group group;
  const GroupMessages({
    super.key,
    required this.controller,
    required this.group,
    this.onSelect,
    this.onCancel,
  });

  @override
  State<GroupMessages> createState() => _GroupMessagesState();
}

class _GroupMessagesState extends State<GroupMessages> {
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

    socket.onConnect((_) {
      debugPrint('onConnect connected');
      socket
          .emit('group_join', {'token': Setup().jwt, 'group': widget.group.id});
    });

    socket.on('message_from_group', (data) {
      try {
        messages[messages.length - 1] = Message.fromSocketMap(data);
        messages.add(Message(
          id: '',
          sender: '${Setup().user.forename} ${Setup().user.surname}',
          message: '',
        ));
        widget.group.messages = messages.length;
        setState(() {});
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    });

    if (socket.connected) {
      socket
          .emit('group_join', {'token': Setup().jwt, 'group': widget.group.id});
    }

    socket.connect();
    debugPrint('should have connected');
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    if (socket.connected) {
      socket.emit('group_leave', {'group': widget.group.id});
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
      socket.emit('group_leave', {'group': widget.group.id});
      socket.emit('cleave');
    }
    // Navigator.pop(context);
  }

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    messages = await getGroupMessages(widget.group);
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
                  onEdit: (_) => (),
                  onSelect: (_) => onSendMessage(index),
                  readOnly: (index < messages.length - 1),
                ),
              ),
            ),
            //     StreamBuilder(
            //        stream: streamSocket.getResponse,
            //         builder: (context, snapshot) {
            //           return Text(snapshot.hasData ? '${snapshot.data}' : '>');
            //         }),
            // ]),
            /*
            Align(
              alignment: Alignment.bottomLeft,
              child: Wrap(
                spacing: 5,
                children: [
                  ActionChip(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onPressed: () {
                      widget.onCancel!(1);
                      debugPrint('Back chip pressed');
                    },
                    backgroundColor: Colors.blue,
                    avatar: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    label: const Text('Back',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  )
                ],
              ),
            ) */
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
