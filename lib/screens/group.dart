import 'dart:convert';
import 'package:drives/tiles/group_member_tile.dart';
import 'package:drives/screens/group_member.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/drives_classes.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/services/db_helper.dart';

class GroupForm extends StatefulWidget {
  // var setup;

  const GroupForm({super.key, setup});

  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  int group = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  int _chosen = 0;
  String testString = '';

  List<GroupMember> filteredGroupMembers = [];
  List<String> groupNames = ['New group', 'Un-grouped'];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    dataloaded = dataFromDatabase();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();

    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    groups = await loadGroups();
    groupMembers = await loadGroupMembers();
    if (groups.isNotEmpty) {
      for (int i = 0; i < groups.length; i++) {
        groupNames.add(groups[i].name);
      }
    } else {
      groups.add(Group(id: -1, name: '', edited: true));
      groupIndex = 0;
      edited = true;
      choosing = false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // groups = [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text('MotaTek groups',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text(
                  groups.isNotEmpty
                      ? '$groupName${groupIndex >= 0 && groups[groupIndex].edited ? '*' : ''}'
                      : 'Create groups',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ))),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<bool>(
        future: dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
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
        },
      ),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Widget portraitView() {
    // setup =  Settings().setup;

    return /* KeyboardVisibilityListener(
      listener: _listener,
      child: */
        Column(children: [
      if (choosing) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: DropdownButtonFormField<String>(
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Group name',
              ),
              value: groupNames[_chosen],
              items: groupNames
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!), // bodyLarge!),
                      ))
                  .toList(),
              onChanged: (item) => {
                setState(() {
                  filteredGroupMembers.clear();
                  groupName = item.toString();
                  group = groupNames.indexOf(item.toString());
                  if (group == 0) {
                    var id = -1;
                    for (int i = 0; i < groups.length; i++) {
                      if (groups[i].id <= id) --id;
                    }
                    groups.add(Group(id: id, name: '', edited: true));
                    groupIndex = groups.length - 1;
                    edited = true;
                    choosing = false;
                  } else {
                    groupIndex = group - 2;
                    if (groupIndex >= 0) {
                      edited = groups[groupIndex].edited;
                    }
                    filterGroup();
                  }
                })
              },
            )),
      ] else ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextFormField(
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (val) => setState(() {
                groups[groupIndex].groupName = val;

                if (groups[groupIndex].name.isNotEmpty) {
                  if (groupNames.length - groups.length < 2) {
                    groupNames.add(groups[groups.length - 1].name);
                  } else {
                    groupNames[groupIndex + 2] = groups[groupIndex].name;
                  }
                  _chosen = groupIndex + 2;
                  groupName = groups[groupIndex].name;
                  choosing = true;
                }
              }),
              autofocus: true,
              focusNode: fn1,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter group name',
                labelText: 'Group name',
              ),
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.left,
              initialValue: groups[groupIndex].name,
              //     style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (text) => groups[groupIndex].edited = true,
            ))
      ],
      Expanded(
          child: SizedBox(
              height: (MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  kBottomNavigationBarHeight -
                  20 * 0.93), // 200,
              child: ListView.builder(
                  itemCount: filteredGroupMembers.length,
                  itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: GroupMemberTile(
                        groupMember: filteredGroupMembers[index],
                        index: index,
                        onDelete: onDelete,
                        onEdit: onEdit,
                        // ToDo: calculate how far away
                      ))))),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  void _listener(bool value) {
    if (value) {
      debugPrint('Listener called true');
    } else {
      debugPrint('Listener called false');
      if (groups[groupIndex].name.isNotEmpty) {
        if (groupNames.length - groups.length < 2) {
          groupNames.add(groups[groups.length - 1].name);
        } else {
          groupNames[groupIndex + 2] = groups[groupIndex].name;
        }
        _chosen = groupIndex + 2;
        groupName = groups[groupIndex].name;
      }
      setState(() => choosing = true);
    }
    return;
  }

  Widget _handleChips() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(spacing: 10, children: [
          if (!choosing && groups.length > 1) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () => setState(() {
                choosing = true;
                if (groupIndex >= 0 && groups[groupIndex].name.isEmpty) {
                  groups.removeAt(groupIndex);
                }
                groupIndex = groups.isNotEmpty ? -1 : 0;
              }),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              label: const Text('Back',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ] else if (choosing && groupIndex >= 0) ...[
            if (groups[groupIndex].name.isNotEmpty) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => newMember(),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.group_add,
                  color: Colors.white,
                ),
                label: const Text('New Member',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              ActionChip(
                onPressed: () => setState(() {
                  choosing = false;
                  fn1.requestFocus();
                }),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                avatar: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                label: const Text('Edit Group Name',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
            if (groups[groupIndex].edited &&
                groups[groupIndex].name.isNotEmpty) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => saveGroup(),
                backgroundColor: Colors.blue,
                avatar: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Group',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
            if (group > 1 && groups[groupIndex].name.isNotEmpty) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => (),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                label: const Text('Delete Group',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ],
        ]));
  }

  void onDelete(int index) {
    return;
  }

  Future<bool> saveGroup() async {
    int currentId = groups[groupIndex].id;
    saveGroupLocal(groups[groupIndex]).then((id) {
      if (currentId < 0) {
        for (int i = 0; i < filteredGroupMembers.length; i++) {
          updateGroupMembers(filteredGroupMembers[i], currentId, id);
        }
      }
      groups[groupIndex].id = id;
      for (int i = 0; i < filteredGroupMembers.length; i++) {
        saveGroupMemberLocal(filteredGroupMembers[i]).then((id) {
          groupMembers[filteredGroupMembers[i].index].id = id;
          groupMembers[filteredGroupMembers[i].index].edited = false;
          setState(() {});
        });
      }
    });
    setState(() {
      groups[groupIndex].edited = false;
      groupName = groups[groupIndex].name;
      filterGroup();
    });
    return true;
  }

  updateGroupMembers(GroupMember member, int oldValue, int newValue) {
    String result = '';
    if (member.groupIds.isNotEmpty) {
      var groupIds = jsonDecode(member.groupIds);
      groupIds.removeWhere((element) => element['groupId'] == oldValue);
      for (int i = 0; i < groupIds.length; i++) {
        result = '$result, {"groupId": ${groupIds[i]['groupId']}}';
      }
    }
    result = '$result, {"groupId": $newValue}';
    result = '[${result.substring(2)}]';
    member.groupIds = result;
    debugPrint(result);
  }

  void newMember() {
    groupMembers.add(GroupMember(
        stId: '-1',
        groupIds:
            groupIndex >= 0 ? '[{"groupId": ${groups[groupIndex].id}}]' : '',
        forename: '',
        surname: ''));
    filterGroup();
    onEdit(filteredGroupMembers.length - 1);
  }

  void onEdit(int index) async {
    // edited = true;
    int parentIndex = filteredGroupMembers[index].index;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GroupMemberForm(
                groupMember: filteredGroupMembers[index],
                groupName: groupIndex >= 0
                    ? groups[groupIndex].name
                    : 'Un-grouped', // groupName,
                groups: groups,
              )),
    ).then((value) {
      setState(() {
        /// if deleted in GroupMemberForm filteredGroupMembers[index].index is set to -1
        if (filteredGroupMembers[index].index == -1) {
          groupMembers.removeAt(parentIndex);
        } else if (filteredGroupMembers[index].forename.isEmpty &&
            filteredGroupMembers[index].surname.isEmpty) {
          Utility().showConfirmDialog(context, "Missing information",
              "Records without a forename and surname can't be saved");
          groupMembers.removeAt(filteredGroupMembers[index].index);
        } else {
          edited = filteredGroupMembers[index].edited ? true : edited;
          if (groupIndex >= 0) {
            groups[groupIndex].edited = filteredGroupMembers[index].edited
                ? true
                : groups[groupIndex].edited;
          }
        }
        filterGroup();
      });
    });
    return;
  }

  filterGroup() {
    filteredGroupMembers.clear();
    bool isEdited = groupIndex >= 0 ? groups[groupIndex].edited : false;
    for (int i = 0; i < groupMembers.length; i++) {
      if (groupMembers[i].groupIds.isEmpty) {
        if (group == 1) {
          isEdited = groupMembers[i].edited ? true : isEdited;
          groupMembers[i].index = i;
          filteredGroupMembers.add(groupMembers[i]);
        }
      } else if (group != 1) {
        var groupIds = jsonDecode(groupMembers[i].groupIds);
        for (int j = 0; j < groupIds.length; j++) {
          if (groupIds[j]['groupId'] == groups[groupIndex].id) {
            isEdited = groupMembers[i].edited ? true : isEdited;
            groupMembers[i].index = i;
            filteredGroupMembers.add(groupMembers[i]);
          }
        }
      }
    }
    setState(() {
      if (groupIndex >= 0) {
        groups[groupIndex].edited = isEdited;
      }
    });
    return;
  }
}

int test() {
  return 1;
}
