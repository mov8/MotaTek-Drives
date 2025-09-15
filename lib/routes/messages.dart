import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/tiles/tiles.dart';

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
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final GroupMessagesController _groupMessagesController;
  late final UserMessagesController _userMessagesController;
  late final MessageItemsController _messageItemsController;
  final ImageRepository _imageRepository = ImageRepository();
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  MailItem _chosenItem = MailItem();
  String _email = '';
  // List<TripItem> tripItems = [];
  HomeItem homeItem = HomeItem(
      heading: 'Keep in contact ',
      subHeading: 'Message group members or individuals.',
      body:
          'Tell members about new events, or keep in contact on a group drive',
      uri: 'assets/images',
      imageUrls: '[{"url": "message.png", "caption": ""}]');
  String _title = 'Messages - summary';
  String _subTitle = 'Tap + to start a new user conversation';

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _messageItemsController = MessageItemsController();
    _groupMessagesController = GroupMessagesController();
    _userMessagesController = UserMessagesController();
    _dataLoaded = getMessages();
  }

  Future<bool> getMessages() async {
    // await getMessagesByGroup();
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Widget _getPortraitBody() {
    if (Setup().user.email.isEmpty || !Setup().hasLoggedIn) {
      return HomeTile(
        homeItem: homeItem,
        imageRepository: _imageRepository,
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_chosenItem.name.isEmpty) ...[
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    50,
                width: MediaQuery.of(context).size.width,
                child: MessageItems(
                  controller: _messageItemsController,
                  onSelect: (item, email) => setState(() {
                    _leadingWidgetController.changeWidget(1);
                    _title =
                        '${item.isGroup ? 'Group' : 'User'} - ${item.name}';
                    _chosenItem = item;
                    _subTitle = item.isGroup
                        ? 'Swipe left to delete the message'
                        : 'Swipe right to mark as read left to delete';
                    _email = email;
                  }),
                ),
              ),
            ] else ...[
              SizedBox(height: 40),
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    50,
                width: MediaQuery.of(context).size.width,
                child: _chosenItem.isGroup
                    ? GroupMessages(
                        controller: _groupMessagesController,
                        group: Group(
                          id: _chosenItem.id,
                          name: _chosenItem.name,
                        ),
                        onSelect: (idx) =>
                            setState(() => debugPrint('Message index: $idx')),
                      )
                    : UserMessages(
                        controller: _userMessagesController,
                        user: User(
                          uri: _chosenItem.id,
                          email: _email,
                        ),
                        onSelect: (idx) =>
                            setState(() => debugPrint('Message')),
                        //  onCancel: (_) => setState(
                        //    () => _userGroup = User(),
                        //  ),
                      ),
              ),
            ]
          ],
        ),
      );
    }
  }

  itemSelect(index) {
    // debugPrint('Index: $index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          initialValue: 0,
          onMenuTap: (index) {
            setState(
              () {
                if (index == 0) {
                  _leadingWidget(_scaffoldKey.currentState);
                } else {
                  if (_chosenItem.isGroup) {
                    _groupMessagesController.leave();
                  } else {
                    _userMessagesController.leave();
                  }
                  _leadingWidgetController.changeWidget(0);
                  _chosenItem = MailItem();
                  _title = 'Messages - summary';
                  _subTitle = 'Tap + to start a new user conversation';
                }
              },
            );
          },
        ), // IconButton(
        title: Text(
          _title,
          style: const TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),
        ),

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 5, 10),
            child: Row(children: [
              Expanded(
                flex: 10,
                child: Text(
                  _subTitle,
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (_title.contains('summary')) ...[
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: () => _messageItemsController.addContact(),
                    icon: Icon(
                      Icons.add,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                )
              ]
            ]),
          ),
        ),

        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
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
