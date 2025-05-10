import 'package:drives/tiles/message_by_group_tile.dart';
import 'package:drives/classes/classes.dart';
import 'package:flutter/material.dart';
// import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class MessageItems extends StatefulWidget {
  // var setup;
  final Function(MailItem) onSelect;
  final Function(MailItem)? onOpen;
  const MessageItems({
    super.key,
    required this.onSelect,
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

  bool addingItem = false;
  bool editingItem = false;

  List<MailItem> mailItems = [];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
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
    mailItems = await loadMailItems();
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
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: mailItems.length,
                itemBuilder: (context, index) => MessageByGroupTile(
                  index: index,
                  mailItem: mailItems[index],
                  onSelect: (_) => widget.onSelect(
                      mailItems[index]), // (_) => onGroupSelect(index),
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
}
