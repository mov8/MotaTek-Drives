import 'dart:developer' as developer;
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/web_helper.dart';

class InvitationsScreen extends StatefulWidget {
  // var setup;

  const InvitationsScreen({super.key, setup});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  int introduce = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<EventInvitation> invitations = [];
  final List<EventInvitation> _refused = [];
  final List<EventInvitation> _accepted = [];
  final ImageRepository _imageRepository = ImageRepository();
  String introduceName = 'Invitations';
  bool _edited = false;
  int introduceIndex = 0;
  String testString = '';

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    invitations = await getInvitationsByUser();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // introduces = [];
    return Scaffold(
      appBar: ScreensAppBar(
        heading: 'Group drive invitations',
        prompt: 'Swipe right to accept, left to decline.',
        updateHeading: _refused.isNotEmpty
            ? "You have declined ${_refused.length} invitation${_refused.length > 1 ? 's' : ''}"
            : '',
        updateSubHeading: _accepted.isNotEmpty
            ? "You have accepted ${_accepted.length} invitation${_accepted.length > 1 ? 's' : ''}"
            : '',
        update: _edited,
        overflowPrompts: [
          'Show all invitations',
          'Include declined invitations',
          'Only future invitations'
        ],
        overflowIcons: [
          Icon(Icons.checklist_outlined),
          Icon(Icons.remove_done_outlined),
          Icon(Icons.more_time_outlined)
        ],
        overflowMethods: [
          getData1,
          getData2,
          getData3,
        ],
        showOverflow: true,
        showAction: _edited,
        updateMethod: update,
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
          throw ('Error - FutureBuilder introduce.dart');
        },
      ),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  void getData({int mode = 0}) {
    debugPrint('mode: $mode');
  }

  getData1() async {
    invitations = await getInvitationsByUser(state: 0);
  }

  getData2() async {
    invitations = await getInvitationsByUser(state: 1);
  }

  getData3({int mode = 0}) async {
    invitations = await getInvitationsByUser(state: 2);
  }

  Widget portraitView() {
    return Column(children: [
      if (invitations.isNotEmpty)
        Expanded(
          child: SizedBox(
            height: (MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight -
                20 * 0.93), // 200,
            child: ListView.builder(
              itemCount: invitations.length,
              itemBuilder: (context, index) => Dismissible(
                key: UniqueKey(),
                //    direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  developer.log(
                      'confirmDismiss ${(direction == DismissDirection.startToEnd).toString()}',
                      name: '_dismiss');
                  _edited = true;
                  if (direction == DismissDirection.startToEnd) {
                    setState(() => invitations[index].accepted = 2);
                    _accepted.add(invitations[index]);
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) {
                  developer.log(
                      'onDismiss ${(direction == DismissDirection.startToEnd).toString()}',
                      name: '_dismiss');
                  if (direction == DismissDirection.endToStart) {
                    _refused.add(invitations[index]);
                    _edited = true;
                    setState(() => invitations.removeAt(index));
                  } else {
                    setState(() => invitations[index].accepted = 1);
                  }
                },
                background: Container(color: Colors.blueGrey),
                child: GroupDriveInvitationTile(
                  imageRepository: _imageRepository,
                  eventInvitation: invitations[index],
                  onSelect: (idx) => startDrive(idx),
                  onDownload: (idx) => saveDrive(idx),
                  onRespond: (idx, val) {
                    if (val == 2) {
                      _accepted.add(invitations[idx]);
                    } else if (val == 1) {
                      _refused.add(invitations[idx]);
                    }
                    setState(() => invitations[idx].accepted = val);
                  },
                  index: index,
                ),
              ),
            ),
          ),
        ),
      if (invitations.isEmpty)
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - 200,
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(
                  0, (MediaQuery.of(context).size.height - 350) / 2, 0, 30),
              child: Column(
                children: [
                  Text(
                    "You haven't got any upcoming invitations.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Why not organise a trip yourself?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.bottomCenter,
        child: null, // _handleChips(),
      )
    ]);
  }

  startDrive(int index) async {
    MyTripItem gotTrip = await getMyTrip(invitations[index].driveId);
    if (mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(gotTrip, '',
              groupDriveId: invitations[index].groupDriveId));
    }
  }

  saveDrive(int index) async {
    MyTripItem gotTrip = await getMyTrip(invitations[index].driveId);
    await gotTrip.saveLocal();
  }

/* 
        MyTripItem gotTrip = await getMyTrip(uri);
        if (options.myTrip) {
          await gotTrip.saveLocal();
        } else if (mounted) {
          Navigator.pushNamed(context, 'createTrip',
              arguments: TripArguments(gotTrip, '')); //'web'));
        }
*/

  update() async {
    Map<String, dynamic> inviteResponses = {};
    if (_accepted.isNotEmpty) {
      List<String> oks = [];
      for (int i = 0; i < _accepted.length; i++) {
        oks.add(_accepted[i].driveId);
      }
      inviteResponses['accepted'] = oks;
    }
    if (_refused.isNotEmpty) {
      List<String> nos = [];
      for (int i = 0; i < _refused.length; i++) {
        nos.add(_refused[i].driveId);
      }
      inviteResponses['refused'] = nos;
    }
    if (inviteResponses.isNotEmpty) {
      await respondToInvitations(responses: inviteResponses);
    }
    setState(() => _edited = false);
  }
}
