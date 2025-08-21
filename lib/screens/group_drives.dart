import 'package:drives/constants.dart';
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

class _GroupDriveFormState extends State<GroupDriveForm>
    with TickerProviderStateMixin {
  late Future<bool> _dataLoaded;
  // late Future<bool> _localDataloaded;
  late List<GroupDriveByGroup> _groups;
  late List<GroupEvent> _trips;
  late TabController _tController;
  bool _showingDialog = false;

  bool _adding = false;
  bool _changed = false;
  List<Map<String, dynamic>> _changes = [];
  int toInvite = 0;

  List<GroupMember> allMembers = [];
  List<MyTripItem> _myTripItems = [];

  @override
  void initState() {
    super.initState();
    _tController = TabController(length: 2, vsync: this);
    _dataLoaded = loadData();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _tController.dispose();
    super.dispose();
  }

  Future<bool> loadData() async {
    DateTime today = DateTime.now();
    _myTripItems = await tripItemFromDb();
    _trips = await getMembersByDrive(
        startDate: DateTime(today.year, today.month, today.day - 2));
    _groups = await getMembersByGroup();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // _action = 0;
    return Scaffold(
      resizeToAvoidBottomInset: false, // stop keyboard overflows
      appBar: ScreensAppBar(
        heading: 'Organise a group drive',
        prompt: 'Invite group members to a group drive.',
        //   updateHeading: 'You have changed your details.',
        //   updateSubHeading: 'Press Update to confirm the changes or Ignore',
        //   update: hasChanged && isComplete(),
        //   updateMethod: () => register(),
        overflowPrompts: [
          "Only Invited",
          "Include Uninvited",
          "Only Future Events"
        ],
        overflowIcons: [
          Icon(Icons.sentiment_satisfied_outlined),
          Icon(Icons.sentiment_dissatisfied_outlined),
          Icon(Icons.next_plan_outlined)
        ],
        overflowMethods: [
          () => setState(() => _adding = !_adding),
          () => setState(() => _adding = !_adding),
          () => setState(() => _adding = !_adding)
        ],
        showOverflow: true,
        update: _changed == true,
        showAction: _changed == true,
        updateMethod: checkInvitations,
      ),
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
    return Column(
      children: [
        if (!_showingDialog)
          TabBar(
            controller: _tController,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: [
              Tab(
                  icon: Icon(Icons.event_available_outlined),
                  text: 'Organised Events'),
              Tab(
                  icon: Icon(Icons.edit_calendar_outlined),
                  text: 'Organise New Event'),
            ],
          ),
        SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: TabBarView(
            controller: _tController,
            children: [
              organised(),
              GroupDriveAddTile(
                index: 1,
                myTripItems: _myTripItems,
                groupDrivers: _groups,
                onSelectTrip: (value) {
                  debugPrint('Value: ${value.toString()}');
                  _changes = value;
                  setState(() => _changed = value.isNotEmpty);
                  // _changed = value.isNotEmpty;
                },
              ),
            ],
          ),
        ),

        //    GroupDriveAddTile(
        //      index: 1,
        //      myTripItems: _myTripItems,
        //      groupDrivers: _groups,
        //      onSelectTrip: (_) => (),
        //    ),
      ],
    );
  }

  Widget organised() {
    return Expanded(
      child: _trips.isNotEmpty
          ? ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                child: ExpansionTile(
                  //    onExpansionChanged: (_) =>
                  //        _trips[index].selected = !_trips[index].selected,
                  //    leading: _trips[index].selected
                  //        ? IconButton(onPressed: () => (), icon: Icon(Icons.add))
                  //        : null,
                  title: Text(
                    _trips[index].eventName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Event date  ${dateFormatDoc.format(DateTime.parse(_trips[index].eventDate))}',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: [
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      // This tells the ListView to calculate its full height based on its children.
                      // WARNING: This is bad for performance on very long lists!
                      shrinkWrap: true,
                      itemCount: _trips[index].invitees.length,
                      itemBuilder: (context, mIndex) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 5.0),
                        child: ListTile(
                            leading: Icon(inviteIcons[int.parse(
                                _trips[index].invitees[mIndex]['state'])]),
                            title: Text(
                                '${_trips[index].invitees[mIndex]['forename']} ${_trips[index].invitees[mIndex]['surname']}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${_trips[index].invitees[mIndex]['email']}    ${_trips[index].invitees[mIndex]['phone']}')),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("You haven't organised any group drives.",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(children: [
                        Text("1. created and saved a drive.",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        if (_myTripItems.isNotEmpty)
                          Icon(
                            Icons.check,
                          ),
                      ]),
                      SizedBox(height: 5),
                      Row(children: [
                        Text("2. create a group of your friends.",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        if (_groups.isNotEmpty) Icon(Icons.check),
                      ]),
                      SizedBox(height: 5),
                      Text("3. share the drive with your group.",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ]),
              ),
            ),
    );
  }

  Widget newTrip() {
    return Text('NewTrip');
  }

  Future<bool> loadMyTrips() async {
    _myTripItems = await tripItemFromDb();
    return true;
  }

/*
  Future<void> loadTrip(val) async {
    return;
  }
*/
/*
  inviteOnSelect(int idx) {
    setState(() {
      // debugPrint('toInvite: $toInvite');
      //   _invitees[idx].selected = !_invitees[idx].selected; //select;
      //   toInvite += _invitees[idx].selected ? 1 : -1;
    });
  }
  */
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
/*
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
*/
/*
  Future<void> publishTrip(val) async {
    return;
  }
  */
/*
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
          ],
        ],
      ),
    );
  }
*/
/*
  Future<void> deleteMyTrip(int index) async {
    return;
  }

  void onSelect(int index) {
    // _groupIndex = index;
  }
*/
  checkInvitations() async {
    MyTripItem tripItem = MyTripItem();
    for (int i = 0; i < _changes.length; i++) {
      for (int i = 0; i < _myTripItems.length; i++) {
        if (_myTripItems[i].id == _changes[i]['myTripId']) {
          tripItem = _myTripItems[i];
        }
      }
      if (tripItem.heading.isNotEmpty) {
        _showingDialog = true;
        await updateDialog(
            context: context, eventDetails: _changes[i], tripItem: tripItem);
      }
    }
  }

  Future updateDialog(
      {required BuildContext context,
      required Map<String, dynamic> eventDetails,
      required MyTripItem tripItem}) {
    DateTime tripDate = DateTime.now();
    String instructions = '';
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            tripItem.heading,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                  child: InkWell(
                    onTap: () async {
                      tripDate = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 2,
                                DateTime.now().month, DateTime.now().day),
                          ) ??
                          tripDate;
                      setState(() => {});
                    },
                    child: Row(
                      children: [
                        Expanded(
                            flex: 4,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Group drive date:',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    dateFormatDoc.format(tripDate),
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ])),
                        Expanded(
                          flex: 1,
                          child: Icon(Icons.calendar_month_outlined, size: 50),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                  child: Text(
                    "Enter any instructions for trip",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                  child: TextFormField(
                    //  key: Key('${widget.contact.standId}${widget.index}_7'),
                    readOnly: false,
                    autofocus: false,
                    minLines: 2,
                    maxLines: null, // these 2 lines allow multiline wrapping
                    keyboardType: TextInputType.multiline,
                    textAlign: TextAlign.start,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding:
                          const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                      focusColor: Colors.blueGrey,
                      hintText: 'Enter any instruction for trip',
                      labelText: 'Instructions',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    initialValue: instructions,
                    onChanged: (text) => instructions = text,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                sendInvitations(
                    eventDetails: eventDetails,
                    driveDate: tripDate,
                    myTripItem: tripItem,
                    instructions: instructions);
                _showingDialog = false;
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _showingDialog = false;
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Quit',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  sendInvitations(
      {required Map<String, dynamic> eventDetails,
      required DateTime driveDate,
      required MyTripItem myTripItem,
      instructions = ''}) async {
    int tripIndex = -1;
    for (int i = 0; i < _myTripItems.length; i++) {
      if (myTripItem.driveUri.isEmpty) {
        tripIndex = i;
        await myTripItem.publish();
        myTripItem.saveLocal();
      }
    }

    Map<String, dynamic> toEmail = {
      'drive_id': _myTripItems[tripIndex].driveUri,
      'drive_date': dateFormatSQL.format(driveDate),
      'title': _myTripItems[tripIndex].heading,
      'message': instructions
    };
    List<Map<String, dynamic>> invited = [];
    for (int i = 0; i < eventDetails['invitees'].length; i++) {
      if (eventDetails['invitees'][i]['invite'] ?? false) {
        invited.add({'email': eventDetails['invitees'][i]['email']});
      }
    }
    if (invited.isNotEmpty) {
      toEmail['invited'] = invited;
      postGroupDrive(invitations: toEmail);
    }
  }
}
