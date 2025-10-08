import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/services/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:drives/constants.dart';
import 'dart:developer' as developer;

/// Messages route supports 3 message views:
/// 1 Summary - the user and group messages are mixed
/// 2 Group messages
/// 3 User messages
/// Messages initiates with the Summary View
/// it changes the view by changing the body: content Widget

class Messages extends StatefulWidget {
  const Messages({
    super.key,
  });
  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  late final RoutesBottomNavController _bottomNavController;
  // late final MessageItemsController _messageItemsController;
  final ImageRepository _imageRepository = ImageRepository();
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<bool> _expanded = [];
  List<MailItem> _mailItems = [];
  List<Message> _messages = [];
  int _openTile = -1;
  bool _addContact = false;

  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  HomeItem homeItem = HomeItem(
      heading: 'Keep in contact ',
      subHeading: 'Message group members or individuals.',
      body:
          'Tell members about new events, or keep in contact on a group drive',
      uri: 'assets/images',
      imageUrls: '[{"url": "message.png", "caption": ""}]');
  // String _title = 'Messages - summary';
  // String _subTitle = 'Tap + to start a new user conversation';

  @override
  void initState() {
    super.initState();
    _bottomNavController = RoutesBottomNavController();
    // _messageItemsController = MessageItemsController();

    socket.onConnectError((_) => debugPrint('connect error'));
    //socket.onConnectError((_) => debugPrint('connect error'));

    socket.onError((data) => debugPrint('Error: ${data.toString()}'));

    socket.onConnect((_) {
      socket.emit('user_connect', {'token': Setup().jwt});
    });

    socket.on('message_from_group', (data) {
      try {
        if (_openTile > -1 && _mailItems[_openTile].isGroup) {
          _messages[_messages.length - 1] = Message.fromSocketMap(data);
          setState(() => appendEmptyMessage());
        }
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    });

    socket.on('user_message', (data) {
      try {
        _messages[_messages.length - 1] = Message.fromSocketMap(data);
        setState(() => appendEmptyMessage());
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    });

/*
    if (socket.connected) {
      socket
          .emit('group_join', {'token': Setup().jwt, 'group': widget.group.id});
    }
*/
    socket.connect();
    _dataLoaded = getMessages();
  }

  @override
  void dispose() {
    if (socket.connected) {
      try {
        socket.emit('cleave');
      } catch (e) {
        debugPrint('error disposing of group_messages: ${e.toString()}');
      }
    }
    super.dispose();
  }

  Future<bool> getMessages() async {
    _mailItems = await getMessagesByGroup();
    _expanded = List.generate(_mailItems.length, (index) => false);
    return true;
  }

  Widget _getPortraitBody() {
    if (Setup().user.email.isEmpty || !Setup().hasLoggedIn) {
      return HomeTile(
        homeItem: homeItem,
        imageRepository: _imageRepository,
      );
    } else {
      return Column(children: [
        if (_addContact) ...[
          AddContactTile(
            onAddMember: (email) => newContact(email: email),
            onCancel: (_) => setState(() => _addContact = false),
          )
        ],
        Expanded(
            child: ListView.builder(
          itemCount: _mailItems.length,
          itemBuilder: (context, index) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: MessageExpansionTile(
              index: index,
              mailItem: _mailItems[index],
              onOpen: (index, value) => _getMessages(index, value),
              onDismiss: (val1, val2) => (),
              onSelect: (val) => (),
              onSend: (val) => sendMessage(val),
              expanded: _expanded[index],
              messages: _messages,
            ),
          ),
        ))
      ]);
    }
  }

  void _getMessages(int index, bool value) async {
    _expanded = List.generate(_mailItems.length, (index) => false);
    if (value) {
      if (_mailItems[index].isGroup) {
        _messages = await getGroupMessages(_mailItems[index].id);
      } else {
        _messages = await getUserMessages(_mailItems[index].id);
      }
      appendEmptyMessage();
      setState(() => _expanded[index] = true);
      _openTile = index;
      try {
        socket.emit('group_join',
            {'token': Setup().jwt, 'group': _mailItems[_openTile].id});
      } catch (e) {
        developer.log('socketIo error: ${e.toString()}', name: '_messages');
      }
    } else {
      setState(() => _openTile = -1);
      if (_mailItems[index].isGroup) {
        socket.emit('leave_group');
      }
    }
  }

  void sendMessage(int index) {
    if (_mailItems[_openTile].isGroup) {
      socket.emit('group_message', _messages[_messages.length - 1].message);
    } else {
      try {
        socket.emit('user_message', {
          'message': _messages[_messages.length - 1].message,
          'token': Setup().jwt,
          'user_email': _mailItems[_openTile].email,
        });
      } catch (e) {
        developer.log('user_message error: ${e.toString()}', name: '_messages');
      }
      setState(() => appendEmptyMessage());
    }
    // setState(() => appendEmptyMessage());
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

  itemSelect(index) {
    // debugPrint('Index: $index');
  }

  _leadingMethod(context) {
    context!.openDrawer();
  }

  _newContact() {
    setState(() => _addContact = true);
  }

  newContact({required String email}) async {
    GroupMember contact = await getUserByEmail(email);
    String name = '${contact.forename} ${contact.surname}';
    _expanded = List.generate(_mailItems.length, (index) => false);
    _mailItems.add(MailItem(id: '', name: name, isGroup: false, email: email));
    _expanded.add(true);
    _messages.clear();
    appendEmptyMessage();
    _openTile = _mailItems.length - 1;
    setState(() => _addContact = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: ScreensAppBar(
        heading: 'Drives messaging',
        prompt: 'Chat with groups or individuals',
        showDrawer: true,
        leadingIcon: Icon(Icons.menu, size: 30),
        leadingMethod: () => _leadingMethod(_scaffoldKey.currentState),
        overflowIcons: [Icon(Icons.person_add)],
        overflowPrompts: ['Make new contact'],
        overflowMethods: [() => _newContact()],
        showOverflow: true,
      ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
            return _getPortraitBody();
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
          throw ('Error - FutureBuilder in main.dart');
        },
      ),
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        onMenuTap: (_) => {},
        initialValue: 5,
      ),
    );
  }
}
