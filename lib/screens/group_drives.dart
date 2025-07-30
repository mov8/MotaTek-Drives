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
  int _groupIndex = 0;
  late Future<bool> _dataloaded;
  List<GroupDrive> _groups = [];
  List<EventInvitation> _invitees = [];
  int _action = 0;
  int _index = 0;
  bool _adding = false;
  bool _expanded = false;
  int toInvite = 0;

  String _alterDriveId = '';

  final List<String> _titles = [
    "Events I've organised",
    "Invited to",
    "Trips I've saved to share",
  ];

  List<GroupMember> allMembers = [];
  List<MyTripItem> _myTripItems = [];

  @override
  void initState() {
    super.initState();
    // _dataloaded = dataFromDatabase();
    _dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    _groups = await getGroupDrives();
    return true;
  }

  Future<bool> loadInviteesToAlter(
      String eventId, String currentEventId) async {
    if (eventId != currentEventId) {
      _invitees = await getInvitationsToAlter(eventId: eventId);
      toInvite = 0;
    }
    return true;
  }

  Widget portraitViewGroup() {
    return Column(children: [
      Expanded(
        child: Column(
          children: [
            if (_groups.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5.0),
                    child: GroupDriveTile(
                      groupDrive: _groups[index],
                      index: index,
                      onSelect: (idx) {
                        setState(() {
                          _groupIndex = idx;
                          _action = 1;
                        });
                      },
                      onDelete: (idx) => deleteTrip(idx),
                    ),
                  ),
                ),
              )
            ],
            Align(
              alignment: Alignment.bottomCenter,
              child: _handleChips(),
            )
          ],
        ),
      )
    ]);
  }

  Widget portraitViewNew() {
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

  Widget portraitViewMembers() {
    return FutureBuilder<bool>(
      future:
          loadInviteesToAlter(_groups[_groupIndex].groupDriveId, _alterDriveId),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Snapshot error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          _alterDriveId = _groups[_groupIndex].groupDriveId;
          return _getEnviteesPortraitBody();
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

  Widget portraitViews(int view) {
    switch (view) {
      case 0:
        return portraitViewGroup();
      case 1:
        return portraitViewMembers();
      default:
        return portraitViewNew();
    }
  }

  @override
  Widget build(BuildContext context) {
    // _action = 0;
    return Scaffold(
      appBar: AppBar(
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
              '${_titles[_action]}${_action == 1 ? ' ${_groups[_groupIndex].name}' : ''}',
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
      ),
      body: FutureBuilder<bool>(
        future: _dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitViews(_action);
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

  Future<bool> loadMyTrips() async {
    _myTripItems = await tripItemFromDb();
    return true;
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
                  onDeleteTrip: deleteMyTrip,
                  onPublishTrip: publishTrip,
                  onExpandChange: (index, expanded) => setState(() {
                    _index = index;
                    _expanded = expanded;
                  }),
                ),
              )
            ],
            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  Widget _getEnviteesPortraitBody() {
    return Column(children: [
      Expanded(
        child: Column(
          children: [
            for (int i = 0; i < _invitees.length; i++)
              if (_invitees[i].accepted < 3 || _adding) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  child: GroupDriveEnviteeTile(
                    index: i,
                    invitation: _invitees[i],
                    onSelect: (i) => inviteOnSelect(i),
                  ),
                ),
              ],
            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
      // _handleChips
    ]);
  }

  Future<void> loadTrip(val) async {
    return;
  }

  inviteOnSelect(int idx) {
    setState(() {
      // debugPrint('toInvite: $toInvite');
      _invitees[idx].selected = !_invitees[idx].selected; //select;
      toInvite += _invitees[idx].selected ? 1 : -1;
    });
  }

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

  Future<void> deleteTrip(idx) async {
    Utility().showOkCancelDialog(
      context: context,
      alertMessage: _groups[idx].name,
      alertTitle: 'Permanently delete trip?',
      okValue: 1,
      callback: (val) {
        if (val == 1) {
          deleteGroupDrive(groupDriveId: _groups[idx].groupDriveId);
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
                onPressed: () =>
                    setState(() => (postGroupDriveInvitations(_invitees))),
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
          if (_action == 2 && (_expanded || _myTripItems.length == 1)) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => shareTrip(_index)),
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
        ],
      ),
    );
  }

  Future<void> deleteMyTrip(int index) async {
    return;
  }

  void onSelect(int index) {
    _groupIndex = index;
  }
}
