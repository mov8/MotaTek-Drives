import 'dart:convert';
import 'package:drives/group_member_tile.dart';
import 'package:drives/screens/group_member.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';
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

  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  final List<List<BottomNavigationBarItem>> _bottomNavigationsBarItems = [
    [
      /// Level 0  mainMenu
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.contacts),
          label: 'Contacts',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.group_add),
          label: 'New Member',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.save),
          label: 'Save Group',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.delete),
          label: 'Delete Group',
          backgroundColor: Colors.blue),
    ]
  ];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  String testString = '';

  List<GroupMember> filteredGroupMembers = [];
  List<String> groupNames = ['New group', 'Un-grouped'];

  @override
  void initState() {
    super.initState();
    dataloaded = dataFromDatabase();
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
            try {
              insertSetup(Setup());
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Back to main screen',
            onPressed: () {
              debugPrint('debug print');
              try {
                // insertPort(widget.port);
                // insertGauge(widget.gauge);
              } catch (e) {
                debugPrint('Error saving data : ${e.toString()}');
              }
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data has been updated')));
            },
          )
        ],
      ),
      bottomNavigationBar: _handleBottomNavigationBar(),
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

  Column portraitView() {
    // setup =  Settings().setup;

    return Column(children: [
      if (choosing) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: DropdownButtonFormField<String>(
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Group name',
              ),
              value: groupNames[0],
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter group name',
                labelText: 'Group name',
              ),
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.left,
              initialValue: '',
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (text) => groups[groups.length - 1].groupName = text,
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
                      )))))
    ]);
  }

  BottomNavigationBar _handleBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0, //BottomNav.values.indexOf(_bottomNavMenu),
      showUnselectedLabels: true,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color.fromARGB(255, 214, 211, 211),
      backgroundColor: Colors.blue,
      items: _bottomNavigationsBarItems[
          0], //  _bottomNavigationsBarIndex + onTapOffset],
      onTap: ((idx) {
        switch (idx) {
          case 0:
            setState(() {
              choosing = true;
            });
            break;
          case 1:
            //    debugPrint(
            //        'testString: $testString -> groups[${groups.length - 1}].name: ${groups[groups.length - 1].name} testGroup.name: ${testGroup.name}');
            break;
          case 2:
            newMember();
            break;
          case 3:
            saveGroup();
            break;
        }
      }),
    );
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
          filteredGroupMembers[i].id = id;
          filteredGroupMembers[i].edited = false;
          setState(() {});
        });
      }
    });
    setState(() {
      groups[groupIndex].edited = false;
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
        if (filteredGroupMembers[index].forename.isEmpty &&
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
