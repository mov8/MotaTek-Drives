import '/screens/messages_summary.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/screens/screens.dart';
import '/tiles/tiles.dart';
import '/services/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '/constants.dart';
// import 'dart:developer' as developer;

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
  late final LeadingWidgetController _leadingWidgetController;
  final ImageRepository _imageRepository = ImageRepository();
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<MailItem> _mailItems = [];
  final List<Message> _messages = [];
  int _tileSelected = -1;
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
      imageUrls: '[{"url": "assets/images/message.png", "caption": ""}]');

  @override
  void initState() {
    super.initState();
    _bottomNavController = RoutesBottomNavController();
    _leadingWidgetController = LeadingWidgetController();
    socket.onConnectError((_) => debugPrint('connect error'));
    socket.onError((data) => debugPrint('Error: ${data.toString()}'));
    socket.onConnect((_) {
      socket.emit('user_connect', {'token': Setup().jwt});
    });

    socket.on('message_from_group', (data) {
      try {
        if (_tileSelected > -1 && _mailItems[_tileSelected].isGroup) {
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
    return true;
  }

  Widget _getPortraitBody() {
    if (Setup().user.email.isEmpty || !Setup().hasLoggedIn) {
      return HomeTile(
        homeItem: homeItem,
        imageRepository: _imageRepository,
      );
    } else {
      return _tileSelected == -1
          ? MessagesSummaryForm(
              mailItems: _mailItems,
              onTap: (index) => setState(() => onSummaryTileTap(index: index)),
              onNewContact: () => setState(() => _addContact = false),
              addContact: _addContact)
          : MessageDetailsForm(
              mailItem: _mailItems[_tileSelected], socket: socket);
    }
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

  onSummaryTileTap({required int index}) {
    _leadingWidgetController.changeWidget(1);
    setState(() => _tileSelected = index);
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Map<String, String> getHeadings() {
    Map<String, String> headings = {
      'heading': 'Drives Messaging',
      'subheading': 'Chat with groups or individuals'
    };
    if (_tileSelected > -1) {
      if (_mailItems[_tileSelected].isGroup) {
        headings['heading'] =
            'Group message - ${_mailItems[_tileSelected].name}';
        headings['subheading'] =
            'messages received: ${_mailItems[_tileSelected].received} - sent ${_mailItems[_tileSelected].sent}';
      } else {
        headings['heading'] =
            'User message - ${_mailItems[_tileSelected].name}';
        headings['subheading'] =
            'unread messages: ${_mailItems[_tileSelected].unreadMessages}';
      }
    }

    return headings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          initialValue: 0,
          value: 0,
          onMenuTap: (index) {
            if (index == 0) {
              _leadingWidget(_scaffoldKey.currentState);
            } else {
              _tileSelected = -1;
              setState(() => _leadingWidgetController.changeWidget(0));
            }
          },
        ),
        title: Text(getHeadings()['heading']!,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        actions: _tileSelected == -1
            ? [
                IconButton(
                    icon: Icon(Icons.person_add, size: 30),
                    onPressed: () => setState(() => _addContact = true)),
                IconButton(
                    onPressed: () => {},
                    icon: Icon(Icons.help_outline_outlined)),
              ]
            : [
                IconButton(
                    onPressed: () => {},
                    icon: Icon(Icons.help_outline_outlined))
              ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(getHeadings()['subheading']!,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
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
