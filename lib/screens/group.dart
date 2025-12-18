import '/constants.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/models/other_models.dart';
import '/tiles/tiles.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

//enum GroupState { createGroups, addMembers }

class GroupForm extends StatefulWidget {
  const GroupForm({super.key, setup});
  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  late Future<bool> _dataLoaded;
  GroupTileController? _activeController = GroupTileController();
  List<Group> groups = [];
//  List<bool> expanded = [];
  GroupActions _groupActions = GroupActions.none;

  String groupName = 'Driving Group';
  bool edited = false;
  int? _index = 0;

  bool _changed = false;
  bool _expanded = false;
  final List<Group> _dismissed = [];
  final List<Group> _unInvite = [];

  @override
  void initState() {
    super.initState();
    _dataLoaded = dataFromWeb();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    groups = await getManagedGroups();
    // groupIndex = 0;
    for (int i = 0; i < groups.length; i++) {
      _expanded = false;
    }
    return true;
  }

  expansionChanged(int index, bool expanded, GroupTileController controller) {
    if (expanded) {
      try {
        _activeController?.contract();
      } catch (_) {
        debugPrint('Contract() failed');
      }
      setState(() {
        _index = index;
        _activeController = controller;
        _expanded = true;
      });
    } else {
      // closing open tile
      setState(() {
        _expanded = false;
        _index = null;
        _activeController = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (groups.isNotEmpty) {}
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(
        heading: 'Drives group management',
        prompt: 'Swipe left to remove ${_expanded ? 'member' : 'group'}',
        updateHeading: 'You have edited details.',
        updateSubHeading: 'Save or Ignore changes',
        update: _changed,
        showAction: _changed,
        overflowIcons: _expanded
            ? [Icon(Icons.person_add), Icon(Icons.edit)]
            : [Icon(Icons.group_add)],
        overflowPrompts: _expanded
            ? ['Invite new member', 'Edit group name']
            : ['Add group'],
        overflowMethods: _expanded ? [addMember, editGroup] : [addGroup],
        showOverflow: true,
        updateMethod: (update) => upLoad(update: update),
      ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitView(context: context);
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
          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView({required BuildContext context}) {
    return Column(children: [
      Expanded(
        flex: 1,
        child: Column(
          children: [
            if (groups.isEmpty) ...[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 300,
                child: Align(
                  alignment: Alignment.center,
                  child: Text("No groups added yet.",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 5.0),
                  child: Dismissible(
                    key: UniqueKey(), // UniqueKey is essential for dismissible
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _dismissed.add(Group(id: groups[index].id, name: ''));
                        _changed = true;
                        setState(() => groups.removeAt(index));
                      }
                    },
                    background: Container(color: Colors.blueGrey),
                    child: GroupTile(
                      group: groups[index],
                      controller: GroupTileController(),
                      actions: _groupActions,
                      index: index,
                      //   editing: _editName,
                      onEdit: (index, update) {
                        if (update) {
                          _groupActions = GroupActions.none;
                          updateGroups(
                              groups: [groups[index]],
                              action: GroupAction.update);
                          groups[index].edited = false;

                          _changed = true;
                        } else {
                          groups[index].edited = true;
                          _changed = true;
                        }
                        setState(() => _groupActions = GroupActions.none);
                      },
                      onExpand: (index, value, controller) =>
                          expansionChanged(index, value, controller),
                      onDelete: (email) {
                        if (email.isNotEmpty) {
                          _unInvite
                              .add(Group(id: groups[index].id, name: email));
                          setState(() => _changed = true);
                        } else {
                          setState(() => groups.removeLast());
                        }
                      },
                      onCancel: (_) =>
                          setState(() => _groupActions = GroupActions.none),
                      onAdd: (value) => setState(() => _changed = true),
                      expanded: _expanded,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    ]);
  }

  void addGroup() {
    setState(
      () {
        _expanded = true;
        groups.add(
            Group(id: Uuid().v7().toString().replaceAll('-', ''), name: ''));
        _groupActions = GroupActions.addGroup;
      },
    );
  }

  void editGroup() {
    setState(() => _groupActions = GroupActions.editName);
  }

  void addMember() {
    setState(() => _groupActions = GroupActions.addMember);
  }

  bool hasChanged() {
    bool changed = false;
    if (_dismissed.isNotEmpty || _unInvite.isNotEmpty || _changed) {
      return true;
    }
    for (int i = 0; i < groups.length; i++) {
      if (groups[i].edited || groups[i].userId.isEmpty) {
        changed = true;
        break;
      }
    }
    _changed = changed;
    return changed;
  }

  upLoad({bool update = false}) {
    if (update) {
      if (_dismissed.isNotEmpty) {
        updateGroups(groups: _dismissed, action: GroupAction.delete);
      }
      if (_changed) {
        updateGroups(groups: groups, action: GroupAction.update);
      }
      if (_unInvite.isNotEmpty) {
        updateGroups(groups: _unInvite, action: GroupAction.uninvite);
      }
    }
    setState(() => _changed = false);
  }

  editGroupName() {
    developer.log('editGroupName setState() 276', name: '_groupTile');
    setState(() => _groupActions = GroupActions.editName);
  }
}
