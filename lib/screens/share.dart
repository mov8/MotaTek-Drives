import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:drives/screens/group_member.dart';
import 'package:drives/tiles/my_trip_tile.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/services/db_helper.dart';

class ShareForm extends StatefulWidget {
  // var setup;
  final MyTripItem tripItem;
  const ShareForm({super.key, required this.tripItem});

  @override
  State<ShareForm> createState() => _shareFormState();
}

class _shareFormState extends State<ShareForm> {
  int group = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  DateTime tripDate = DateTime.now();
  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  final List<List<BottomNavigationBarItem>> _bottomNavigationsBarItems = [
    [
      /// Level 0  mainMenu

      const BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'When',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.group_add),
          label: 'Add member',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.save),
          label: 'Save Group',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.send), label: 'Send', backgroundColor: Colors.blue),
    ]
  ];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  String testString = '';

  List<GroupMember> filteredGroupMembers = [];
  List<String> groupNames = ['All members'];

  DateFormat dateFormat = DateFormat('dd/MM/yyy');

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
      group = 0;
      filterGroup();
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
        title: const Text('MotaTek share a trip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text(widget.tripItem.heading,
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

  Widget portraitView() {
    // setup =  Settings().setup;

    return SingleChildScrollView(
        child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: MyTripTile(
          index: 0,
          myTripItem: widget.tripItem,
          onDeleteTrip: deleteTrip,
          onLoadTrip: loadTrip,
          onShareTrip: shareTrip,
        ),
      ),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Row(children: [
            Expanded(
                flex: 1,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
                    child: DropdownButtonFormField<String>(
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Filter by group',
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
                          groupIndex = group - 1;
                          filterGroup();
                        })
                      },
                    ))),
            Expanded(
                flex: 1,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                    child: TextFormField(
                      textInputAction: TextInputAction.done,
                      autofocus: false,
                      //    focusNode: fn1,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Trip date',
                        labelText: 'Trip date',
                        suffixIcon: IconButton(
                          onPressed: () => test(),
                          icon: const Icon(Icons.schedule),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textAlign: TextAlign.left,
                      initialValue: dateFormat.format(tripDate),
                      //     style: Theme.of(context).textTheme.bodyLarge,
                      // onChanged: (_) => (),
                    )))
          ])),
      /* Expanded(
          child: */
      SizedBox(
          height: (MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  kBottomNavigationBarHeight -
                  20) *
              0.4,
          //100,
          child: ListView.builder(
              itemCount: filteredGroupMembers.length,
              itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 5.0),
                  child: Card(
                      elevation: 5,
                      child: CheckboxListTile(
                        title: Row(children: [
                          Expanded(
                            flex: 1,
                            child: IconButton(
                                onPressed: () => onEdit(index),
                                icon: const Icon(
                                  Icons.edit,
                                  size: 30,
                                )),
                          ),
                          Expanded(
                            flex: 5,
                            child: Column(children: [
                              Row(children: [
                                Text(
                                  '${filteredGroupMembers[index].forename} ${filteredGroupMembers[index].surname}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ]),
                              Row(children: [
                                Text(
                                  'email: ${filteredGroupMembers[index].email}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ]),
                              Row(children: [
                                Text(
                                  'phone: ${filteredGroupMembers[index].phone}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ]),
                            ]),
                          )
                        ]),
                        onChanged: (value) {
                          setState(() {
                            filteredGroupMembers[index].selected = value!;
                            groupMembers[filteredGroupMembers[index].index]
                                .selected = value;
                          });
                        },
                        value: filteredGroupMembers[index].selected,
                      ))))),
      const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11),
          child: Row(children: [
            Text(
              'Enter your message:',
              textAlign: TextAlign.left,
            )
          ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextFormField(
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 20,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                borderSide: BorderSide(width: 1),
              ),
            ),
          )),
    ]));
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

  int test() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
    ).then((date) => ());
    return 1;
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

    for (int i = 0; i < groupMembers.length; i++) {
      if (group == 0 || groupMembers[i].groupIds.isEmpty) {
        groupMembers[i].index = i;
        filteredGroupMembers.add(groupMembers[i]);
      } else {
        var groupIds = jsonDecode(groupMembers[i].groupIds);
        for (int j = 0; j < groupIds.length; j++) {
          if (groupIds[j]['groupId'] == groups[groupIndex].id) {
            groupMembers[i].index = i;
            filteredGroupMembers.add(groupMembers[i]);
          }
        }
      }
    }
    setState(() {});
    return;
  }
}

Future<void> deleteTrip(int index) async {
  return;
}

Future<void> loadTrip(int index) async {
  return;
}

Future<void> shareTrip(int index) async {
  return;
}
