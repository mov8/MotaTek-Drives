import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
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
///

class MessagesController {
  _MessagesState? _messagesState;

  void _addState(_MessagesState messagesState) {
    _messagesState = messagesState;
  }

  bool get isAttached => _messagesState != null;

  void showDetails(tileIndex) => _messagesState!.showDetails(tileIndex);
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
  late final RoutesBottomNavController _bottomNavController;
  late final LeadingWidgetController _leadingWidgetController;
  final ImageRepository _imageRepository = ImageRepository();
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
/*
  HomeItem homeItem = HomeItem(
      heading: 'Keep in contact ',
      subHeading: 'Message group members or individuals.',
      body:
          'Tell members about new events, or keep in contact on a group drive',
      uri: 'assets/images',
      imageUrls: '[{"url": "assets/images/message.png", "caption": ""}]');
*/
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    _bottomNavController = RoutesBottomNavController();
    _leadingWidgetController = LeadingWidgetController();
    _tileSelected = widget.index;
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

  Widget _getPortraitBody() {
    /*  if (Setup().user.email.isEmpty || !Setup().hasLoggedIn) {
      return HomeTile(
        homeItem: homeItem,
        imageRepository: _imageRepository,
      );
    } else { */
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
    //   }
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
      if (widget.onSelect != null) {
        widget.onSelect!(index);
      }
      _tileSelected = index;
      if (widget.webAppBarController != null) {
        widget.webAppBarController!
            .setActionPrompt(getHeadings()['headings'] ?? 'Injected heading');
      }

      /// The next line resets the Future<bool> and should ensure the data is read for the message details
      setState(() => _dataLoaded = getMessages());
    } else {
      _leadingWidgetController.changeWidget(1);
      setState(() => _tileSelected = index);
    }
  }

  onDetailBackTap() {
    if (kIsWeb && widget.onBackClick != null) {
      widget.onBackClick!();
    }
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
    if (kIsWeb) {
      return ScreensAppBarBottom(
        key: _scaffoldKey,
        prompt: getHeadings()['subheading'] ?? '',
        textColor: const Color.fromRGBO(1, 29, 51, 1),
        leadingButton: _tileSelected > -1
            ? IconButton(
                onPressed: () => setState(() {
                      if (widget.webAppBarController != null) {
                        widget.webAppBarController!
                            .setActionPrompt(getHeadings()['headings'] ?? '');
                      }
                      _tileSelected = -1;
                    }),
                icon:
                    Icon(Icons.arrow_back, color: Color.fromRGBO(1, 29, 51, 1)))
            : null,
        actionButtons: _tileSelected == -1
            ? [
                IconButton(
                    onPressed: () => setState(() => _addContact = true),
                    icon: Icon(Icons.person_add_outlined,
                        color: Color.fromRGBO(1, 29, 51, 1)))
              ]
            : [],
        content: FutureBuilder<bool>(
          future: getMessages(), // _dataLoaded,
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
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Text(
                  'No messages',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
            );
          },
        ),
      );
    } else {
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
                      icon: Icon(Icons.person_add_outlined, size: 30),
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
}
