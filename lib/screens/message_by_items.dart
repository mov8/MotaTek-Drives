import '/classes/classes.dart';
import '/models/models.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
// import '/models/other_models.dart';
import '/services/services.dart';

class MessageItemsController {
  _MessageItemsState? _messageItemsState;

  void _addState(_MessageItemsState messageItemsState) {
    _messageItemsState = messageItemsState;
  }

  bool get isAttached => _messageItemsState != null;

  void addContact() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _messageItemsState?.addContact();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class MessageItems extends StatefulWidget {
  // var setup;
  final Function(MailItem, String) onSelect;
  final Function(MailItem)? onOpen;
  final MessageItemsController? controller;
  const MessageItems({
    super.key,
    required this.onSelect,
    this.controller,
    this.onOpen,
  });

  @override
  State<MessageItems> createState() => _MessageItemsState();
}

class _MessageItemsState extends State<MessageItems> {
  int item = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<MailItem> items = [];

  String itemName = 'Driving Group';
  bool edited = false;
  int itemIndex = 0;
  String testString = '';
  String _email = '';
  bool addingItem = false;
  bool editingItem = false;
  bool _addContact = false;
  List<MailItem> mailItems = [];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    // dataloaded = dataFromDatabase();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    mailItems = await getPrivateRepository().loadMailItems();
    if (mailItems.isEmpty) {
      mailItems.add(MailItem(id: '', name: '', isGroup: false));
      itemIndex = 0;
      edited = true;
    }
    return true;
  }

  Future<bool> dataFromWeb() async {
    mailItems = await getMessagesByGroup();
    if (mailItems.isEmpty) {
      mailItems.add(MailItem(id: '', name: '', isGroup: false));
      itemIndex = 0;
      edited = true;
    }

    return true;
  }

  void addContact() {
    setState(() => _addContact = true);
  }

/*
  void onGroupSelect(int index) {
    debugPrint('Slected index: $index');
    widget.onSelect!(items[index]);
    return;
  }
*/
  void onGroupOpen(int index) async {
    debugPrint('Opened index: $index');
    /*  widget.onOpen!(groupItems[index]);

    if (groupItems[groupIndex].groupMembers().isEmpty) {
      List<GroupMember> members =
          await getManagedGroupMembers(groups[groupIndex].id);
      groupItems[groupIndex].setGroupMembers(members);
      setState(() => {});
    }
*/
    return;
  }

  Widget portraitView() {
    debugPrint('PortraitView() called...');
    return RefreshIndicator(
      onRefresh: () async {
        try {
          mailItems.clear();
          mailItems = await getMessagesByGroup();
          debugPrint('mailItems.length : ${mailItems.length}');
        } catch (e) {
          debugPrint('error: ${e.toString()}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Column(
          children: [
            if (_addContact) ...[
              AddContactTile(
                onAddMember: (email) => newContact(email: email),
                onCancel: (_) => setState(() => _addContact = false),
              )
            ],
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: mailItems.length,
                itemBuilder: (context, index) => MessageByGroupTile(
                  index: index,
                  mailItem: mailItems[index],
                  onSelect: (_) => widget.onSelect(
                      mailItems[index], _email), // (_) => onGroupSelect(index),
                  onOpen: (_) => onGroupOpen(index),
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

          throw ('Error - FutureBuilder group.dart');
        });
  }

  newContact({required String email}) async {
    GroupMember contact = await getUserByEmail(email);
    String name = '${contact.forename} ${contact.surname}';
    mailItems.add(MailItem(id: '', name: name, isGroup: false));
    _email = email;
    setState(() => _addContact = false);
  }
}
