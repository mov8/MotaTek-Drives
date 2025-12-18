import 'package:drives/helpers/edit_helpers.dart';
import '/constants.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/models/models.dart';
import '/services/services.dart';

class GroupDriveForm extends StatefulWidget {
  const GroupDriveForm({super.key, setup});
  @override
  State<GroupDriveForm> createState() => _GroupDriveFormState();
}

class _GroupDriveFormState extends State<GroupDriveForm>
    with TickerProviderStateMixin {
  late Future<bool> _dataLoaded;
  late List<GroupDriveByGroup> _groups;
  late List<GroupEvent> _trips;
  late TabController _tController;
  bool _showingDialog = false;

  bool _changed = false;
  List<Map<String, dynamic>> _changes = [];
  int toInvite = 0;

  List<GroupMember> allMembers = [];
  List<MyTripItem> _myTripItems = [];

  List<String> _overflowPrompts = [];
  List<VoidCallback> _overflowMethods = [];
  List<Icon> _overflowIcons = [];

  @override
  void initState() {
    super.initState();
    _tController = TabController(length: 2, vsync: this);
    _overflowPrompts = ['Show all drives', 'Only future drives'];
    _overflowMethods = [() => _setAdding(true), () => _setAdding(false)];
    _overflowIcons = [
      Icon(Icons.checklist_outlined),
      Icon(Icons.more_time_outlined)
    ];
    _dataLoaded = loadData();
  }

  @override
  void dispose() {
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

  void _setAdding(bool adding) async {
    DateTime today = DateTime.now();
    _trips = await getMembersByDrive(
        startDate: adding
            ? DateTime(2000, 01, 01)
            : DateTime(today.year, today.month, today.day - 2));
    setState(() => ());
  }

  @override
  Widget build(BuildContext context) {
    // _action = 0;
    return Scaffold(
      backgroundColor: Colors.blue,
      resizeToAvoidBottomInset: false, // stop keyboard overflows
      appBar: ScreensAppBar(
        heading: 'Organise a group event',
        prompt: 'Invite group members to a group event.',
        overflowPrompts: _overflowPrompts,
        overflowIcons: _overflowIcons,
        overflowMethods: _overflowMethods,
        showOverflow: true,
        update: _changed == true,
        // updateHeading: 'Save your group drive?',
        // updateSubHeading: 'You have made changes.',
        showAction: _changed == true,
        updateMethod: (update) => checkInvitations(update),
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
            labelStyle: labelStyle(context: context),
            unselectedLabelStyle: labelStyle(context: context),
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.deepPurple,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(
                  icon: Icon(
                    Icons.event_available_outlined,
                    color: Colors.white,
                    size: 35,
                  ),
                  text: 'Organised Events'),
              Tab(
                  icon: Icon(Icons.edit_calendar_outlined,
                      color: Colors.white, size: 35),
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget organised() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 250, //SingleChildScrollView(
      child: _trips.isNotEmpty
          ? ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: ExpansionTile(
                      backgroundColor: Colors.white,
                      title: SizedBox(
                        height: 60,
                        child: InkWell(
                          onLongPress: () => startDrive(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //      IconButton(
                              //          onPressed: () => startDrive(index),
                              //          icon: Icon(Icons.directions_car_outlined, size: 30)),
                              Text(
                                _trips[index].eventName,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'On ${dateFormatDoc.format(DateTime.parse(_trips[index].eventDate))}  (long-press to join trip now)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onExpansionChanged: (value) =>
                          _expansionChange(index, value),

                      //     subtitle: Text(
                      //       'Event date  ${dateFormatDoc.format(DateTime.parse(_trips[index].eventDate))} - press button to join',
                      //       style: TextStyle(fontSize: 14),
                      //     ),
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
                            child: Padding(
                              padding: EdgeInsetsGeometry.fromLTRB(5, 0, 5, 0),
                              child: ListTile(
                                //   shape: ShapeBorder()
                                leading: Icon(inviteIcons[int.parse(
                                    _trips[index].invitees[mIndex]['state'])]),
                                title: Text(
                                    '${_trips[index].invitees[mIndex]['forename']} ${_trips[index].invitees[mIndex]['surname']}',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${_trips[index].invitees[mIndex]['email']}    ${_trips[index].invitees[mIndex]['phone']}'),
                                tileColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No future group events.",
                      style: headlineStyle(context: context, size: 1),
                    ),
                    SizedBox(height: 10),
                    Row(children: [
                      Text(
                        "1. Create and saved a trip.",
                        style: headlineStyle(
                          context: context,
                          size: 2,
                        ),
                      ),
                      if (_myTripItems.isNotEmpty)
                        Icon(Icons.check, color: Colors.white, size: 30),
                    ]),
                    SizedBox(height: 5),
                    Row(children: [
                      Text("2. Create a group of participants.",
                          style: headlineStyle(
                            context: context,
                            size: 2,
                          )),
                      if (_groups.isNotEmpty)
                        Icon(Icons.check, color: Colors.white, size: 30),
                    ]),
                    SizedBox(height: 5),
                    Text(
                      "3. Invite group members.",
                      style: headlineStyle(
                        context: context,
                        size: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _expansionChange(int index, bool value) {
    setState(() {
      if (value) {
        _overflowPrompts = ['Join drive now'];
        _overflowMethods = [() => startDrive(index)];
        _overflowIcons = [Icon(Icons.directions_car_outlined)];
      } else {
        _overflowPrompts = ['Show all drives', 'Only future drives'];
        _overflowMethods = [() => _setAdding(true), () => _setAdding(false)];
        _overflowIcons = [
          Icon(Icons.checklist_outlined),
          Icon(Icons.more_time_outlined)
        ];
      }
    });
  }

  startDrive(int index) async {
    MyTripItem gotTrip = await getMyTrip(_trips[index].driveId);
    if (mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments:
              TripArguments(gotTrip, '', groupDriveId: _trips[index].eventId));
    }
  }

  Widget newTrip() {
    return Text('NewTrip');
  }

  Future<bool> loadMyTrips() async {
    _myTripItems = await tripItemFromDb();
    return true;
  }

  checkInvitations(bool update) async {
    MyTripItem tripItem = MyTripItem();
    for (int i = 0; i < _changes.length; i++) {
      for (int j = 0; j < _myTripItems.length; j++) {
        if (_myTripItems[j].id == _changes[i]['myTripId']) {
          tripItem = _myTripItems[j];
        }
      }
      try {
        if (tripItem.heading.isNotEmpty) {
          _showingDialog = true;
          bool sent = await updateDialog(
              context: context, eventDetails: _changes[i], tripItem: tripItem);

          if (sent) {
            _changes.clear();
            setState(() => _changed = false);
          }
        }
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
    setState(() => _changed = false);
  }

  Future<bool> updateDialog(
      {required BuildContext context,
      required Map<String, dynamic> eventDetails,
      required MyTripItem tripItem,
      dynamic tripDate,
      String instructions = ''}) async {
    DateTime tripDate = DateTime.now();
    String instructions = '';
    bool? update = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(tripItem.heading,
                  style: headlineStyle(
                      context: context, color: Colors.black, size: 2)),
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
                              DateTime.now();
                          setState(() => {});
                        },
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Group drive date:',
                                      style: headlineStyle(
                                          context: context,
                                          color: Colors.black,
                                          size: 2)),
                                  Text(dateFormatDoc.format(tripDate),
                                      style: headlineStyle(
                                          context: context,
                                          color: Colors.black,
                                          size: 2)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child:
                                  Icon(Icons.calendar_month_outlined, size: 50),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                      child: Text(
                        "Enter any instructions for trip",
                        style: headlineStyle(
                            context: context, color: Colors.black, size: 2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                      child: TextFormField(
                        //  key: Key('${widget.contact.standId}${widget.index}_7'),
                        readOnly: false,
                        autofocus: false,
                        minLines: 2,
                        maxLines:
                            null, // these 2 lines allow multiline wrapping
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
                          labelStyle: labelStyle(
                              context: context, color: Colors.black, size: 3),
                          hintStyle: hintStyle(
                            context: context,
                          ),
                        ),
                        style: textStyle(
                            context: context, color: Colors.black, size: 2),
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
        ) ??
        false;
    return update;
  }

  sendInvitations(
      {required Map<String, dynamic> eventDetails,
      required DateTime driveDate,
      required MyTripItem myTripItem,
      instructions = ''}) async {
    if (myTripItem.driveUri.isEmpty) {
      await myTripItem.publish();
    }
    try {
      Map<String, dynamic> toEmail = {
        'drive_id': myTripItem.driveUri,
        'drive_date': dateFormatSQL.format(driveDate),
        'title': myTripItem.heading,
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
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }
}
