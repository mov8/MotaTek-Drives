import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';
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
  late Future<bool> _dataLoaded;
  // late Future<bool> _localDataloaded;
  late List<GroupDriveByGroup> _groups;
  late List<GroupDriveByGroup> _trips;
  int _action = 0;

  bool _adding = false;
  int toInvite = 0;

  List<GroupMember> allMembers = [];
  List<MyTripItem> _myTripItems = [];

  @override
  void initState() {
    super.initState();
    _dataLoaded = loadData();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    super.dispose();
  }

  Future<bool> loadData() async {
    _myTripItems = await tripItemFromDb();
    _trips = await getMembersByDrive();
    _groups = await getMembersByGroup();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // _action = 0;
    return Scaffold(
      appBar: ScreensAppBar(
        heading: 'Organise a group drive',
        prompt: 'Invite group members to a group drive.',
        updateHeading: 'You have changed your details.',
        updateSubHeading: 'Press Update to confirm the changes or Ignore',
        //   update: hasChanged && isComplete(),
        //   updateMethod: () => register(),
        overflowPrompts: ["Only Invited", "Include Uninvited"],
        overflowIcons: [
          Icon(Icons.sentiment_satisfied_outlined),
          Icon(Icons.sentiment_dissatisfied_outlined)
        ],
        overflowMethods: [
          () => setState(() => _adding = !_adding),
          () => setState(() => _adding = !_adding)
        ],
      ),

      /*AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives Group Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              "Events I've organised",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            if (--_action >= 0) {
              setState(() {});
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ), */
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitView(); //portraitViews(_action);
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
    return SingleChildScrollView(
      child: Column(
        children: [
          GroupDriveAddTile(
            index: 1,
            myTripItems: _myTripItems,
            groupDrivers: _groups,
            onSelectTrip: (_) => (),
          )
        ],
      ),
    );
  }

  Future<bool> loadMyTrips() async {
    _myTripItems = await tripItemFromDb();
    return true;
  }

  Future<void> loadTrip(val) async {
    return;
  }

  inviteOnSelect(int idx) {
    setState(() {
      // debugPrint('toInvite: $toInvite');
      //   _invitees[idx].selected = !_invitees[idx].selected; //select;
      //   toInvite += _invitees[idx].selected ? 1 : -1;
    });
  }
/*
  Future<void> shareTrip(index) async {
    MyTripItem currentTrip = _myTripItems[index];
    currentTrip.showMethods = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareForm(
          tripItem: currentTrip,
        ),
      ),
    ).then((value) {
      setState(() {});
    });
    return;
  }

  */

  Future<void> deleteTrip(idx) async {
    Utility().showOkCancelDialog(
      context: context,
      alertMessage: _groups[idx].name,
      alertTitle: 'Permanently delete trip?',
      okValue: 1,
      callback: (val) {
        if (val == 1) {
          //   deleteGroupDrive(groupDriveId: _groups[idx].groupDriveId);
          setState(() {
            _groups.removeAt(idx);
          });
        }
      },
    );
    return;
  }

  Future<void> publishTrip(val) async {
    return;
  }

  Widget _handleChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 10,
        children: [
          if (_action == 0) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => _action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.group_add,
                color: Colors.white,
              ),
              label: const Text(
                'New Trip', // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
          if (_action == 1) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () =>
                  setState(() => _adding = !_adding), //_action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.group_add,
                color: Colors.white,
              ),
              label: Text(
                _adding
                    ? "Only Invited"
                    : "Include Uninvited", // - ${_action.toString()}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            if (_adding && toInvite > 0) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => (),
                //  setState(() => (postGroupDriveInvitations(_invitees))),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.group_add,
                  color: Colors.white,
                ),
                label: const Text(
                  'Invite Checked', // - ${_action.toString()}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ]
          ],
          /*
          if (_action == 2 && (_myTripItems.length == 1)) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => shareTrip(0)),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.group_add,
                color: Colors.white,
              ),
              label: const Text(
                'Group Trip', // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
          */
        ],
      ),
    );
  }

  Future<void> deleteMyTrip(int index) async {
    return;
  }

  void onSelect(int index) {
    // _groupIndex = index;
  }
}
