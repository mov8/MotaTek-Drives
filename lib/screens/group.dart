import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/services/services.dart';
import 'package:drives/classes/classes.dart';
import 'package:uuid/uuid.dart';

//enum GroupState { createGroups, addMembers }

class GroupForm extends StatefulWidget {
  const GroupForm({super.key, setup});
  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  late Future<bool> dataloaded;
  late GroupTileController _controller;
  List<Group> groups = [];
  List<bool> expanded = [];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  bool _changed = false;
  bool _expanded = false;
  bool _addingGroup = false;

  final List<Group> _dismissed = [];
  final List<Group> _unInvite = [];

  @override
  void initState() {
    super.initState();
    dataloaded = dataFromWeb();
    _controller = GroupTileController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    groups = await getManagedGroups();
    groupIndex = 0;
    for (int i = 0; i < groups.length; i++) {
      expanded.add(false);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (groups.isNotEmpty) {}
    return Scaffold(
      appBar: ScreensAppBar(
        heading: 'Drives group management',
        prompt: 'Add members or swipe left to remove.',
        updateHeading: 'You have changed group details.',
        updateSubHeading: 'Press Update to confirm the changes or Ignore',
        update: _changed,
        showAction: _changed,
        updateMethod: () => upLoad(),
      ),
      body: FutureBuilder<bool>(
        future: dataloaded,
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
        child: Column(
          children: [
            if (groups.isEmpty) ...[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 250,
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
                    //      confirmDismiss: (direction) async {
                    //        return direction == DismissDirection.endToStart;
                    //      },
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
                      controller: _controller,
                      index: index,
                      onEdit: (index, update) {
                        if (update) {
                          updateGroups(
                              groups: [groups[index]],
                              action: GroupAction.update);
                          setState(() => groups[index].edited = false);
                          _changed = true;
                        } else {
                          groups[index].edited = true;
                          _changed = true;
                        }
                      },
                      onExpand: (index, value) => onExpand(index, value),
                      // onAdd: (index) => onAdd(index),
                      onDelete: (email) {
                        if (email.isNotEmpty) {
                          _unInvite
                              .add(Group(id: groups[index].id, name: email));
                          setState(() => _changed = true);
                        } else {
                          groups.removeLast();
                          setState(() => _addingGroup = false);
                        }
                      },
                      onAdd: (value) => setState(() => _changed = true),
                      // onInvite: (index, value) => onInvite(index),
                      expanded: expanded[index],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (!_expanded && !_addingGroup)
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(20, 10, 10, 30),
          child: Wrap(
            spacing: 5,
            children: [
              if (!_expanded && !_addingGroup)
                ActionChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    setState(
                      () {
                        expanded.add(true);
                        groups.add(Group(
                            id: Uuid().v7().toString().replaceAll('-', ''),
                            name: ''));
                        _addingGroup = true;
                      },
                    );
                    _controller.newGroup();
                  }, // widget.onAddLink!(index),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.groups_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Add a new group",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              if (hasChanged() || _dismissed.isNotEmpty)
                ActionChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => upLoad(),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Upload changes",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
    ]);
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

  upLoad() {
    if (_dismissed.isNotEmpty) {
      updateGroups(groups: _dismissed, action: GroupAction.delete);
    }
    if (_changed) {
      updateGroups(groups: groups, action: GroupAction.update);
    }
    if (_unInvite.isNotEmpty) {
      updateGroups(groups: _unInvite, action: GroupAction.uninvite);
    }
    setState(() => _changed = false);
  }

  /// There is a bit of a problem with an expansion tile's expanded state updating its parent
  /// as calling setState() in the parent to reflect the expansion change prevents the expansiontile expanding
  /// The solution is to set each expansion tile's expanded state through its initiallyExpanded: parameter.
  /// The parent has to maintain a list of expansion states for each tile and update it when the
  /// tile expands of contracts through a callback. The maintained state is then used to set the initiallyExpanded
  /// so the parent's setState() leaves the tile in the correct expansion state.

  onExpand(int index, bool value) {
    expanded[index] = value;
    if (value) {
      _expanded = true;
    } else {
      _expanded = false;
      for (int i = 0; i < expanded.length; i++) {
        if (expanded[i]) {
          _expanded = true;
        }
      }
    }
    setState(() => (_expanded));
  }
}
