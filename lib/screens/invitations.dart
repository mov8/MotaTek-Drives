import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/constants.dart';

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
  // bool _expanded = false;
  int _openIndex = -1;
  List<bool> expanded = [];

  List<EventInvitation> invitations = [];
  final List<EventInvitation> _refused = [];
  final List<EventInvitation> _accepted = [];
  final ImageRepository _imageRepository = ImageRepository();
  String introduceName = 'Invitations';
  List<String> overflowPrompts = [];
  List<void Function()> overflowMethods = [];
  List<Icon> overflowIcons = [];
  bool _edited = false;
  int introduceIndex = 0;
  String testString = '';
  TripItem? _tripItem = TripItem(heading: '');
  List<Photo>? _photos = [];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    setOverflows(false);
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    invitations = await getInvitationsByUser(state: 2);
    expanded = List.filled(invitations.length, false);
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
            : "You have accepted ${_accepted.length} invitation${_accepted.length > 1 ? 's' : ''}",
        updateSubHeading: _refused.isNotEmpty && _accepted.isNotEmpty
            ? "You have accepted ${_accepted.length} invitation${_accepted.length > 1 ? 's' : ''}"
            : '',
        update: _edited,
        overflowPrompts: overflowPrompts,
        /* _expanded
            ? ['Join trip now', 'Download trip']
            : [
                'Show all invitations',
                'All excluding declined',
                'Only future invitations'
              ],
              */
        overflowIcons: overflowIcons,
        /* _expanded
            ? [Icon(Icons.directions_car), Icon(Icons.download)]
            : [
                Icon(Icons.checklist_outlined),
                Icon(Icons.remove_done_outlined),
                Icon(Icons.more_time_outlined)
              ], */
        overflowMethods: overflowMethods,
        /*_expanded
            ? [_startDrive, _downloadDrive]
            : [
                getData1,
                getData2,
                getData3,
              ],
              */
        showOverflow: true,
        showAction: _edited,
        updateMethod: (update) => _update(update: update),
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

  _startDrive() {
    startDrive(_openIndex);
  }

  _downloadDrive() {
    saveDrive(_openIndex);
  }

  getData1() async {
    invitations = await getInvitationsByUser(state: 0);
    expanded = List.filled(invitations.length, false);
    setState(() => {});
  }

  getData2() async {
    invitations = await getInvitationsByUser(state: 1);
    expanded = List.filled(invitations.length, false);
    setState(() => {});
  }

  getData3() async {
    invitations = await getInvitationsByUser(state: 2);
    expanded = List.filled(invitations.length, false);
    setState(() => {});
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
                  _edited = true;
                  if (direction == DismissDirection.startToEnd) {
                    setState(() => invitations[index].accepted = 2);
                    _accepted.add(invitations[index]);
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _refused.add(invitations[index]);
                    _edited = true;
                    setState(() => invitations.removeAt(index));
                  } else {
                    _accepted.add(invitations[index]);
                    _edited = true;
                    setState(() => invitations[index].accepted = 1);
                  }
                },
                background: Container(color: Colors.blueGrey),
                child: GroupDriveInvitationTile(
                  imageRepository: _imageRepository,
                  tripItem: _tripItem,
                  photos: _photos,
                  eventInvitation: invitations[index],
                  onSelect: (idx) => startDrive(idx),
                  onDownload: (idx) => saveDrive(idx),
                  onExpansionChange: (index, value) =>
                      expansionChange(index, value),
                  expanded: expanded[index],
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

  void expansionChange(index, value) async {
    expanded[index] = value;
    //  _expanded = value;
    _openIndex = index;
    _tripItem = await getTripItem(index);
    _photos = photosFromJson(
        photoString: _tripItem!.imageUrls, endPoint: '$urlDriveImages/');
    setState(() => setOverflows(value));
  }

  Future<TripItem?> getTripItem(int index) async {
    return getTrip(tripId: invitations[index].driveId);
  }

  setOverflows(bool expanded) {
    overflowPrompts = expanded
        ? ['Join trip now', 'Download trip']
        : [
            'Show all invitations',
            'All excluding declined',
            'Only future invitations'
          ];
    overflowIcons = expanded
        ? [Icon(Icons.directions_car), Icon(Icons.download)]
        : [
            Icon(Icons.checklist_outlined),
            Icon(Icons.remove_done_outlined),
            Icon(Icons.more_time_outlined)
          ];
    overflowMethods = expanded
        ? [_startDrive, _downloadDrive]
        : [
            getData1,
            getData2,
            getData3,
          ];
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

  _update({bool update = false}) async {
    if (update) {
      Map<String, dynamic> inviteResponses = {};
      if (_accepted.isNotEmpty) {
        List<String> oks = [];
        for (int i = 0; i < _accepted.length; i++) {
          oks.add(_accepted[i].id);
        }
        inviteResponses['accepted'] = oks;
      }
      if (_refused.isNotEmpty) {
        List<String> nos = [];
        for (int i = 0; i < _refused.length; i++) {
          nos.add(_refused[i].id);
        }
        inviteResponses['refused'] = nos;
      }
      if (inviteResponses.isNotEmpty) {
        await respondToInvitations(responses: inviteResponses);
      }
    }
    setState(() => _edited = false);
  }
}
