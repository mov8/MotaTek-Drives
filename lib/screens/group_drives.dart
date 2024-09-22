import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/models/models.dart';

import 'package:drives/services/services.dart';

class GroupDriveForm extends StatefulWidget {
  // var setup;

  const GroupDriveForm({super.key, setup});

  @override
  State<GroupDriveForm> createState() => _GroupDriveFormState();
}

class _GroupDriveFormState extends State<GroupDriveForm> {
  int group = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  late GroupMember newMember;
  late Group newGroup;
  List<GroupMember> groupMembers = [];
  List<GroupDrive> groups = [];
  RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  //final _formKey = GlobalKey<FormState>();
  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  //double _emailSizedBoxHeight = 70;
  //bool _validate = false;
  //String _validateMessage = '';
  String testString = '';
  bool addingMember = false;
  bool addingTrip = false;

  List<GroupMember> allMembers = [];
  List<MyTripItem> _myTripItems = [];

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
    return true;
  }

  Future<bool> dataFromWeb() async {
    groups = await getGroupDrives();
    return true;
  }

  membersOfGroup(Group group) {
    for (GroupMember member in allMembers) {
      member.selected = group.groupMembers().contains(member);
    }
  }

  addMembersToGroup(Group group) {
    List<GroupMember> members = [
      for (GroupMember member in allMembers)
        if (member.selected) member
    ];
    group.setGroupMembers(members);
  }

  @override
  Widget build(BuildContext context) {
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
                  addingTrip
                      ? "Trips I've saved to share"
                      : "Group trips I've organised",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ))),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            if (addingTrip) {
              setState(() => addingTrip = false);
            } else {
              Navigator.pop(context);
            }
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
                child: CircularProgressIndicator(),
              ),
            );
          }

          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView() {
    return Column(children: [
      Expanded(
        child: Column(
          children: [
            if (addingMember) ...[
              // handleNewMember(),
            ],
            if (addingTrip) ...[
              handleNewTrip(),
            ],
            if (groups.isNotEmpty && !addingTrip) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5.0),
                    child: GroupDriveTile(
                      groupDrive: groups[index],
                      index: index,
                      onSelect: onSelect,
                    ),
                  ),
                ),
              )
            ],
            Align(
              alignment: Alignment.bottomLeft,
              child: _handleChips(),
            )
          ],
        ),
      )
    ]);
  }

  Future<bool> loadMyTrips() async {
    _myTripItems = await tripItemFromDb();
    return true;
  }

  Widget handleNewTrip() {
    return FutureBuilder<bool>(
      future: loadMyTrips(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Snapshot error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return _getNewTripPortraitBody();
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
        throw ('Error - FutureBuilder in main.dart');
      },
    );
  }

  Widget _getNewTripPortraitBody() {
    return Column(children: [
      Expanded(
        child: Column(
          children: [
            for (int i = 0; i < _myTripItems.length; i++) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: MyTripSelectTile(
                  index: i,
                  myTripItem: _myTripItems[i],
                  onLoadTrip: loadTrip,
                  onShareTrip: shareTrip,
                  onDeleteTrip: deleteTrip,
                  onPublishTrip: publishTrip,
                ),
              )
            ],
            const SizedBox(
              height: 40,
            ),
          ],
        ),
      )
    ]);
  }

  Future<void> loadTrip(val) async {
    return;
  }

  Future<void> shareTrip(index) async {
    MyTripItem currentTrip = _myTripItems[index];
    currentTrip.showMethods = false;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ShareForm(
                tripItem: currentTrip,
              )),
    ).then((value) {
      setState(() {});
    });
    return;
  }

  Future<void> deleteTrip(val) async {
    return;
  }

  Future<void> publishTrip(val) async {
    return;
  }

  Widget _handleChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(spacing: 10, children: [
        if (!addingTrip) ...[
          ActionChip(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => setState(
              () {
                addingTrip = !addingTrip;
              },
            ),
            backgroundColor: Colors.blue,
            avatar: const Icon(
              Icons.group_add,
              color: Colors.white,
            ),
            label: const Text(
              'New Trip',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ]),
    );
  }

  void onDelete(int index) {
    return;
  }

  void onSelect(int index) {}
}
