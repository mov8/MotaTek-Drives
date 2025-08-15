import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/my_trip_tile.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';

class ShareForm extends StatefulWidget {
  // var setup;
  final MyTripItem tripItem;
  const ShareForm({super.key, required this.tripItem});

  @override
  State<ShareForm> createState() => _ShareFormState();
}
/*
 late List<GroupDriveByGroup> _groups;
_groups = await getMembersByGroup();
                        child: MyTripSelectTile(
                          myTripItem: widget.myTripItems[index],
                          groupDrivers: widget.groupDrivers,
                          onSelect: (idx) => setState(() => _driveIndex = idx),
                          //  controller: _controller,
                          index: index,
                        ),

*/

class _ShareFormState extends State<ShareForm> {
  late List<GroupDriveByGroup> _groups;

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
        title: const Text(
          'Drives share a trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              widget.tripItem.heading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
      ),
      //  bottomNavigationBar: _handleBottomNavigationBar(),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text('Invite other drives to enjoy your drive',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          DriveInvitations(
            index: 1,
            groupDrivers: _groups,
            myTripItem: widget.tripItem,
          )
        ]),
      ),
    );
  }
}
/*
  int group = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  DateTime _tripDate = DateTime.now();
  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  String testString = '';
  bool _expanded = false;

  List<GroupMember> filteredGroupMembers = [];
  List<GroupMember> allMembers = [];
  List<String> groupNames = ['All members'];
  late GroupDriveInvitation invitation;

  DateFormat dateFormat = DateFormat('dd/MM/yyy');

  var dateTxt = TextEditingController();

  @override
  void initState() {
    super.initState();
    dataloaded = dataFromWeb(); //dataFromDatabase();
    dateTxt.text = dateFormat.format(_tripDate);
    invitation = GroupDriveInvitation(
        driveId: widget.tripItem.driveUri, title: widget.tripItem.heading);
  }

  Future<bool> dataFromDatabase() async {
    groups = await loadGroups();
    groupMembers = await loadGroupMembers();
    if (groups.isNotEmpty) {
      for (int i = 0; i < groups.length; i++) {
        groupNames.add(groups[i].name);
      }
      group = 0;
    } else {
      //   groups.add(Group(id: -1, name: '', edited: true));
      groupIndex = 0;
      edited = true;
      choosing = false;
    }
    return true;
  }

  Future<bool> dataFromWeb() async {
    groups = await getGroups();
    //  groupMembers = await getGroupMembers();
    filteredGroupMembers.clear();
    if (groups.isNotEmpty) {
      for (Group group in groups) {
        groupNames.add(group.name);

        for (GroupMember member in group.groupMembers()) {
          member.selected = true;
          allMembers.add(member);
          filteredGroupMembers.add(member);
          filteredGroupMembers[filteredGroupMembers.length - 1].index =
              filteredGroupMembers.length - 1;
        }
      }
    } else {
      groups.add(
        Group(id: '', name: '', edited: true),
      );
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
        title: const Text(
          'Drives share a trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              widget.tripItem.heading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        /*   actions: <Widget>[
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
                const SnackBar(
                  content: Text('Data has been updated'),
                ),
              );
            },
          )
        ],
        */
      ),
      //  bottomNavigationBar: _handleBottomNavigationBar(),
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
                child: CircularProgressIndicator(),
              ),
            );
          }

          throw ('Error - FutureBuilder group.dart');
        },
      ),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Widget portraitView() {
    // Expanded must be the child of a Column or Row
    // else an Incorrect use of ParentWidget error is thrown
    return Column(children: [
      Expanded(
        // SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: MyTripTile(
                index: 0,
                myTripItem: widget.tripItem,
                onDeleteTrip: deleteTrip,
                onLoadTrip: loadTrip,
                onShareTrip: shareTrip,
                onExpandChange: (expanded) {
                  setState(() => (_expanded = expanded));
                },
              ),
            ),
            if (!_expanded) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Row(
                  children: [
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
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.w400)), // bodyLarge!),
                                ),
                              )
                              .toList(),
                          onChanged: (item) => {
                            setState(() {
                              filteredGroupMembers.clear();
                              groupName = item.toString();
                              // group =
                              //     groups.indexWhere((grp) => grp.name == item);
                              group = groupNames.indexOf(item.toString());
                              groupIndex = group - 1;
                              if (group == 0) {
                                filteredGroupMembers = allMembers;
                              } else {
                                filteredGroupMembers =
                                    groups[groupIndex].groupMembers();
                              }
                            })
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                        child: TextFormField(
                          controller: dateTxt,
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
                              onPressed: () => tripDate(),
                              icon: const Icon(Icons.schedule),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
            Expanded(
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 7, 0),
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                getInitials(
                                    name:
                                        '${filteredGroupMembers[index].forename} ${filteredGroupMembers[index].surname}'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(children: [
                            Row(children: [
                              Text(
                                '${filteredGroupMembers[index].forename} ${filteredGroupMembers[index].surname}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
                          allMembers[filteredGroupMembers[index].index]
                              .selected = value;
                        });
                      },
                      value: filteredGroupMembers[index].selected,
                    ),
                  ),
                ),
              ),
            ),
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
                autofocus: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 15,
                onChanged: (val) => invitation.message = val,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _handleChips(),
            )
          ],
        ),
      )
    ]);
  }

  Widget _handleChips() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(spacing: 10, children: [
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () async {
              List<Map<String, dynamic>> attendees = [];
              for (GroupMember member in allMembers) {
                if (member.selected) {
                  attendees.add({'email': member.email});
                }
              }
              invitation.invited = attendees;
              await postGroupDrive(invitation);
            },
            backgroundColor: Colors.blue,
            avatar: const Icon(Icons.send, color: Colors.white),
            label: const Text('Send',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              setState(() {
                for (GroupMember member in filteredGroupMembers) {
                  member.selected = true;
                }
              });
            },
            backgroundColor: Colors.blue,
            avatar: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('Check all',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              setState(() {
                for (GroupMember member in filteredGroupMembers) {
                  member.selected = false;
                }
              });
            },
            backgroundColor: Colors.blue,
            avatar:
                const Icon(Icons.radio_button_unchecked, color: Colors.white),
            label: const Text('Uncheck all',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]));
  }

  void onDelete(int index) {
    return;
  }

  int tripDate() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
    ).then((date) => setState(() {
          _tripDate = date ?? _tripDate;
          invitation.driveDate = _tripDate;
          dateTxt.text = dateFormat.format(_tripDate);
        }));

    return 1;
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
*/
