import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/routes_bottom_nav.dart';
import 'package:drives/screens/message_by_groups.dart';
import 'package:drives/screens/group_messages.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/leading_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
  });
  @override
  State<MessagesScreen> createState() => _messagesScreenState();
}

class _messagesScreenState extends State<MessagesScreen> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final GroupMessagesController _groupMessagesController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<TripItem> tripItems = [];
  Group _messageGroup = Group(
    name: '',
  );

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    // _bottomNavController.setValue(4);
    _groupMessagesController = GroupMessagesController();
    _dataLoaded = getMessages();
  }

  Future<bool> getMessages() async {
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Widget _getPortraitBody() {
    return SingleChildScrollView(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_messageGroup.name == '') ...[
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    50,
                width: MediaQuery.of(context).size.width,
                child: MessageByGroups(
                  onSelect: (idx) => setState(
                    () {
                      debugPrint('Message index: ${idx.name}');
                      _messageGroup = idx;
                      _leadingWidgetController.changeWidget(1);
                    },
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    50,
                width: MediaQuery.of(context).size.width,
                child: GroupMessages(
                  controller: _groupMessagesController,
                  group: _messageGroup,
                  onSelect: (idx) => debugPrint('Message index: $idx'),
                  onCancel: (_) => setState(
                    () {
                      _messageGroup = Group(name: '');
                    },
                  ),
                ),
              ),
            ]
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
            controller: _leadingWidgetController,
            onMenuTap: (index) {
              if (index == 0) {
                _leadingWidget(_scaffoldKey.currentState);
              } else {
                setState(() => _messageGroup.name = '');
                _groupMessagesController.leave();
                _leadingWidgetController.changeWidget(0);
              }
            }), // IconButton(
        title: const Text(
          'Messages',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
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
