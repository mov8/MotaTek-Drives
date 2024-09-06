import 'package:drives/tiles/message_by_group_tile.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/services/db_helper.dart';

class MessageByGroups extends StatefulWidget {
  // var setup;
  final Function(Group)? onSelect;
  const MessageByGroups({
    super.key,
    this.onSelect,
  });

  @override
  State<MessageByGroups> createState() => _MessageByGroupsState();
}

class _MessageByGroupsState extends State<MessageByGroups> {
  int group = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<Group> groups = [];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  String testString = '';
  bool addingMember = false;
  bool addingGroup = false;
  bool editingGroup = false;

  List<GroupMember> allMembers = [];

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
    groups = await loadGroups();
    if (groups.isEmpty) {
      groups.add(Group(id: '', name: '', edited: true));
      groupIndex = 0;
      edited = true;
    }
    return true;
  }

  Future<bool> dataFromWeb() async {
    // groups = await getGroups();\
    groups = await getMessagesByGroup();
    return true;
  }

  void onGroupSelect(int index) {
    debugPrint('Slected index: $index');
    widget.onSelect!(groups[index]);
    return;
  }

  Widget portraitView() {
    debugPrint('PortraitView() called...');
    return RefreshIndicator(
        onRefresh: () async {
          groups = await getMessagesByGroup();
        },
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, index) => MessageByGroupTile(
                    index: index,
                    group: groups[index],
                    onSelect: (_) => onGroupSelect(index),
                  ),
                ),
              ),
              //  ]),
            ])));
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
