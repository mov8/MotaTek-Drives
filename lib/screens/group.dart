import 'package:flutter/foundation.dart';
import '/constants.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/tiles/tiles.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class GroupForm extends StatefulWidget {
  const GroupForm({super.key, setup});
  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  late Future<bool> _dataLoaded;
  GroupTileController? _activeController = GroupTileController();
  List<Group> groups = [];
  GroupActions _groupActions = GroupActions.none;

  String groupName = 'Driving Group';
  bool edited = false;

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
        _activeController = controller;
        _expanded = true;
      });
    } else {
      // closing open tile
      setState(() {
        _expanded = false;
        _activeController = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ScreensAppBarBottom(
        prompt: 'Swipe left to remove ${_expanded ? 'member' : 'group'}',
        updateHeading: 'You have edited details.',
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
        textColor: const Color.fromRGBO(1, 29, 51, 1),
        updateMethod: (update) => upLoad(update: update),
        content: FutureBuilder<bool>(
          future: _dataLoaded,
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              developer.log(
                  'Error GroupForm().build() Snapshot has error: ${snapshot.error}',
                  name: 'error');
              return const SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'No data not found for "Groups I manage"',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
              );
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
          },
        ),
      );
    } else {
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
  }

  Widget portraitView({required BuildContext context}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (int idx = 0; idx < groups.length; idx++) ...[
            Dismissible(
              key: UniqueKey(), // UniqueKey is essential for dismissible
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _dismissed.add(Group(id: groups[idx].id, name: ''));
                  _changed = true;
                  setState(() => groups.removeAt(idx));
                }
              },
              child: GroupTile(
                group: groups[idx],
                controller: GroupTileController(),
                actions: _groupActions,
                index: 0,
                onEdit: (idx, update) {
                  if (update) {
                    _groupActions = GroupActions.none;
                    updateGroups(
                        groups: [groups[idx]], action: GroupAction.update);
                    groups[idx].edited = false;

                    _changed = true;
                  } else {
                    groups[idx].edited = true;
                    _changed = true;
                  }
                  setState(() => _groupActions = GroupActions.none);
                },
                onExpand: (idx, value, controller) =>
                    expansionChanged(idx, value, controller),
                onDelete: (email) {
                  if (email.isNotEmpty) {
                    _unInvite.add(Group(id: groups[0].id, name: email));
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
          ],
          SizedBox(height: 30),
        ],
      ),
    );
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
    setState(() => _groupActions = GroupActions.editName);
  }
}
