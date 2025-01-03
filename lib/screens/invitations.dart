import 'dart:convert';
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
// import 'package:drives/screens/dialogs.dart';

import 'package:drives/services/web_helper.dart';

class InvitationsScreen extends StatefulWidget {
  // var setup;

  const InvitationsScreen({super.key, setup});

  @override
  State<InvitationsScreen> createState() => _invitationsScreenState();
}

class _invitationsScreenState extends State<InvitationsScreen> {
  int introduce = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<EventInvitation> invitations = [];
  final ImageRepository _imageRepository = ImageRepository();
  String introduceName = 'Invitations';
  bool edited = false;
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
    invitations = await getInvitationssByUser();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // introduces = [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'MotaTek invitations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              'My invitations to upcoming events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

  Widget portraitView() {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: (MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              kBottomNavigationBarHeight -
              20 * 0.93), // 200,
          child: ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) => GroupDriveInvitationTile(
              imageRepository: _imageRepository,
              eventInvitation: invitations[index],
              index: index,
              onDownload: onDownload,
              onEdit: onEdit,
              onSelect: onSelect,
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  Widget _handleChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 10,
        children: [
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => {}, // putIntroduced(introduceMembers),
            backgroundColor: Colors.blue,
            avatar: const Icon(
              Icons.outgoing_mail,
              color: Colors.white,
            ),
            label: const Text('Show past invitations',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void onDe(int index) {
    // introduceMembers.removeAt(index);
    return;
  }

  void onDownload(int index) async {
    getMyTrip(invitations[index].driveId).then((webTrip) {
      webTrip.setId(-1);
      webTrip.setDriveUri(invitations[index].driveId);
      webTrip.saveLocal();
    });
  }

  void onSelect(int index) async {
    MyTripItem webTrip = await getMyTrip(invitations[index].driveId);
    webTrip.setId(-1);
    webTrip.setDriveUri(invitations[index].driveId);
    webTrip.setGroupTrip(true);
    if (context.mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(webTrip, 'web'));
    }
  }

  void onEdit(int index) async {
    return;
  }

  updateintroduceMembers(GroupMember member, int oldValue, int newValue) {
    String result = '';
    if (member.groupIds.isNotEmpty) {
      var introduceIds = jsonDecode(member.groupIds);
      introduceIds.removeWhere((element) => element['introduceId'] == oldValue);
      for (int i = 0; i < introduceIds.length; i++) {
        result = '$result, {"introduceId": ${introduceIds[i]['introduceId']}}';
      }
    }
    result = '$result, {"introduceId": $newValue}';
    result = '[${result.substring(2)}]';
    member.groupIds = result;
    debugPrint(result);
  }

  void onEdit2(int index) async {
    return;
  }
}

int test() {
  return 1;
}
