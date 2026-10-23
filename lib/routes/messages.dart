import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '/screens/messages_summary.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/screens/screens.dart';
import '/services/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '/constants.dart';
import 'package:go_router/go_router.dart';

/// Messages route supports 3 message views:
/// 1 Summary - the user and group messages are mixed
/// 2 Group messages
/// 3 User messages
/// Messages initiates with the Summary View
/// it changes the view by changing the body: content Widget
///

class MessagesController {
  _MessagesState? _messagesState;

  void _addState(_MessagesState messagesState) {
    _messagesState = messagesState;
  }

  bool get isAttached => _messagesState != null;

  void showDetails(tileIndex) => _messagesState!.showDetails(tileIndex);

  /// Web: the conversations in the SideDrawer (or, logged out, the message)
  void fillSideDrawer() => _messagesState?.sideBarItems();

  /// Web: shows a conversation to the right of the SideDrawer
  void select(int index) => _messagesState?.select(index);
}

class Messages extends StatefulWidget {
  int index;
  Function(int)? onSelect;
  Function? onBackClick;
  MessagesController? controller;
  WebAppBarController? webAppBarController;
  Messages({
    super.key,
    this.index = -1,
    this.controller,
    this.webAppBarController,
    this.onSelect,
    this.onBackClick,
  });
  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final GlobalKey _scaffoldKey = GlobalKey();
  late final Future<bool> _dataLoaded;
  List<MailItem> _mailItems = [];
  List<Message> _messages = [];
  late int _tileSelected; // = -1;
  bool _addContact = false;

  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });
  @override
  void initState() {
    super.initState();
    (widget.controller ?? MapService().messagesController)?._addState(this);
    _tileSelected = widget.index;
    socket.onError(
        (data) => developer.log('Error: ${data.toString()}', name: 'error'));
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
    try {
      socket.connect();
    } catch (e) {
      developer.log('error connecting to socket.io: ${e.toString()}',
          name: 'error');
    }
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

  void showDetails(int tileIndex) {}

  Future<bool> getMessages() async {
    if (_tileSelected == -1) {
      _mailItems = await getMessagesByGroup();
      return true;
    } else {
      try {
        if (_mailItems[_tileSelected].isGroup) {
          _messages = await getGroupMessages(_mailItems[_tileSelected].id);
          return true;
        } else {
          _messages = await getUserMessages(_mailItems[_tileSelected].id);
          return true;
        }
      } catch (e) {
        developer.log('Error message_detail.dart getMessages() ${e.toString()}',
            name: 'error');
        return false;
      }
    }
  }

  /// Logged out: the image and an invitation to log in - the whole screen on
  /// a phone, the whole SideDrawer on the web
  Widget _loggedOutView() {
    return Stack(children: [
      Positioned.fill(
        child: Image.asset(
          'assets/images/message.png',
          fit: BoxFit.cover,
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5), // // Light shadow top
                Colors.black.withValues(alpha: 0.7), // Dark contrast bottom
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            Text(
                'Messaging allows you to keep in contact with members of your Drives group.',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            SizedBox(height: 10),
            Text(
                'It is very useful if you are driving together with friends, or in group organised by your club.',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            SizedBox(height: 10),
            Text(
                'To use Messaging you have to be logged into the Drives server.',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            SizedBox(height: 10),
            Text('To login tap the button below:',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            SizedBox(height: 30),
            ActionChip(
              label: Text('Login Now',
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              onPressed: () => kIsWeb
                  ? MapService()
                      .sideDrawerController
                      ?.setContent(content: BottomDrawerItems.login)
                  : context.push('/login'),
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      )
    ]);
  }

  Widget _getPortraitBody() {
    if (Setup().jwt.isEmpty) {
      return _loggedOutView();
    }
    return _tileSelected == -1
        ? MessagesSummaryForm(
            mailItems: _mailItems,
            onTap: (index) => setState(() => onSummaryTileTap(index: index)),
            onNewContact: () => setState(() => _addContact = false),
            addContact: _addContact,
          )
        : MessageDetailsForm(
            messages: _messages,
            email: _mailItems[_tileSelected].email,
            isGroup: _mailItems[_tileSelected].isGroup,
            socket: socket,
          );
  }

  void appendEmptyMessage() {
    _messages.add(
      Message(
        id: '',
        sender: '${Setup().user.forename} ${Setup().user.surname}',
        sent: true,
        message: '',
      ),
    );
  }

  /// If a summary tile is tapped we want to change the WebAppBarContent to reflect the tile
  /// selected, and the content in the Side Drawer. For some reason if a setState() is called
  /// then the Side Drawer becomes inactive, after the MessagesDetail is shown.
  onSummaryTileTap({required int index}) {
    if (kIsWeb) {
      select(index);
    } else {
      // The app bar shows Back while the thread is showing
      MapService().persistentAppBarController?.setBack(
            page: NavigationService().page,
            onBack: () {
              if (mounted) setState(() => _tileSelected = -1);
            },
          );
      setState(() => _tileSelected = index);
    }
  }

  /// Web: loads the conversation and shows it to the right
  void select(int index) {
    _tileSelected = index;
    setState(() => _dataLoaded = getMessages());
    sideBarItems(); // highlights nothing yet, but keeps the list current
  }

  /// Web: the conversations fill the SideDrawer, with a button to add a
  /// contact - or, logged out, the image and invitation to log in
  Future<void> sideBarItems() async {
    if (!kIsWeb || !mounted || NavigationService().page != 5) return;
    if (_tileSelected == -1) await _dataLoaded; // the conversations
    Widget content = Setup().jwt.isEmpty
        ? _loggedOutView()
        : Container(
            color: Colors.white,
            child: Column(children: [
              ListTile(
                title: const Text('Messages',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_outlined, size: 30),
                  onPressed: () {
                    _addContact = true;
                    sideBarItems();
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: MessagesSummaryForm(
                    mailItems: _mailItems,
                    onTap: (index) => select(index),
                    onNewContact: () {
                      _addContact = false;
                      sideBarItems();
                    },
                    addContact: _addContact,
                  ),
                ),
              ),
            ]),
          );
    MapService().sideDrawerController!.open();
    MapService().sideDrawerController!.setContent(
        content: BottomDrawerItems.messages, drawerItems: [content]);
    MapService().sideDrawerController!.setFixed(fixed: true);
    MapService().sideDrawerController!.setVisible(visible: true);
  }

  /// Web: the selected conversation, to the right of the SideDrawer
  Widget _webDetails() {
    if (Setup().jwt.isEmpty ||
        _tileSelected == -1 ||
        _tileSelected >= _mailItems.length) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.38 + 10, 5, 10, 5),
      child: MessageDetailsForm(
        key: ValueKey(_tileSelected),
        messages: _messages,
        email: _mailItems[_tileSelected].email,
        isGroup: _mailItems[_tileSelected].isGroup,
        socket: socket,
      ),
    );
  }

  onDetailBackTap() {
    if (kIsWeb && widget.onBackClick != null) {
      widget.onBackClick!();
    }
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
    if (kIsWeb) {
      // The conversations are in the SideDrawer (sideBarItems())
      return Scaffold(
        backgroundColor: Colors.blue,
        body: FutureBuilder<bool>(
          future: _dataLoaded,
          builder: (BuildContext context, snapshot) => snapshot.hasData
              ? _webDetails()
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.blue,
        key: _scaffoldKey,
        // The main drawer is on the shell Scaffold in main.dart
        //     appBar: PersistentAppBar(
        //         controller: MapService().persistentAppBarController!, page: 5),

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
      );
    }
  }
}
