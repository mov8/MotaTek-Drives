// import 'package:universal_io/universal_io.dart';
import 'package:universal_io/universal_io.dart';
import '/services/web_helper.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/helpers/helpers.dart';
import '/constants.dart';

class DriveInvitations extends StatefulWidget {
  final int index;
  final void Function(List<Map<String, dynamic>>)? onSelect;
  final MyTripItem myTripItem;
  final List<GroupDriveByGroup> groupDrivers;
  const DriveInvitations(
      {super.key,
      required this.index,
      required this.groupDrivers,
      required this.myTripItem,
      this.onSelect});
  @override
  State<DriveInvitations> createState() => _DriveInvitationsState();
}

class _DriveInvitationsState extends State<DriveInvitations>
    with TickerProviderStateMixin {
  late TabController _tController;

  late List<Photo> photos;
  String _instructions = '';
  DateTime? _date;
  List<Map<String, dynamic>> _changes = [];

  @override
  void initState() {
    super.initState();
    _tController = TabController(length: 2, vsync: this);
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _tController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    photos = photosFromJson(photoString: widget.myTripItem.images);
    return SingleChildScrollView(
      child: Column(
        children: [
          TabBar(
            controller: _tController,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: [
              Tab(
                  icon: Icon(Icons.group_outlined),
                  text: 'Invite Group Members'),
              // Tab(icon: Icon(Icons.outgoing_mail), text: 'Send Invitations'),
              Tab(icon: Icon(Icons.map_outlined), text: 'Drive Details'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - 450,
            child: TabBarView(
              controller: _tController,
              children: [
                invited(),
                //   invitation(),
                tripDescription(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget invited() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: widget.groupDrivers.length,
              itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                child: ExpansionTile(
                  title: Text(
                    widget.groupDrivers[index].name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${widget.groupDrivers[index].count} member${widget.groupDrivers[index].count == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                          ' invited: ${widget.groupDrivers[index].invited} accepted: ${widget.groupDrivers[index].accepted}'),
                    ),
                  ]),
                  children: [
                    if (widget.groupDrivers[index].invitees.isNotEmpty)
                      //  Expanded(
                      //    flex: 1,
                      //   child: SingleChildScrollView(
                      // child:
                      ListView.builder(
                        itemCount: widget.groupDrivers[index].invitees.length,

                        /// Shrinkwrap calculates the space needed so NOT for very long lists
                        shrinkWrap: true,
                        // 2. This disables scrolling within this inner list, so the
                        //    user scrolls the main page instead.
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) => Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 5.0),
                          child: ListTile(
                            leading:
                                getLeading(groupIndex: index, driverIndex: idx),
                            title: Text(
                              '${widget.groupDrivers[index].invitees[idx]['forename'] ?? ''} ${widget.groupDrivers[index].invitees[idx]['surname'] ?? ''}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              widget.groupDrivers[index].invitees[idx]
                                      ['email'] ??
                                  '',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        //     ),
                        //   ),
                      ),
                    if (widget.groupDrivers[index].invitees.isEmpty)
                      SizedBox(
                        height: 400,
                        child: Column(
                          children: [
                            Text(
                              '${widget.groupDrivers[index].name} has no members',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Use "Groups I Manage" to add members',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getLeading({int groupIndex = 0, int driverIndex = 0}) {
    int state = int.parse(
        widget.groupDrivers[groupIndex].invitees[driverIndex]['state']);
    if (state == 3) {
      bool value = widget.groupDrivers[groupIndex].invitees[driverIndex]
              ['invite'] ??
          false;
      return Checkbox(
        value: value,
        onChanged: (value) => setState(() {
          widget.groupDrivers[groupIndex].selected = true;
          widget.myTripItem.selected = true;
          widget.groupDrivers[groupIndex].invitees[driverIndex]['invite'] =
              value;
          int tripIndex = -1;
          int inviteeIndex = -1;
          for (int i = 0; i < _changes.length; i++) {
            if (_changes[i]['myTripId'] == widget.myTripItem.id) {
              tripIndex = i;
              for (int j = 0; j < _changes[i]['invitees'].length; j++) {
                if (_changes[i]['invitees'][j]['email'] ==
                    widget.groupDrivers[groupIndex].invitees[driverIndex]
                        ['email']) {
                  inviteeIndex = j;
                  break;
                }
              }
              break;
            }
          }
          if (value == false && inviteeIndex > -1) {
            _changes[tripIndex]['invitees'].removeAt(inviteeIndex);
          } else if (value == true && inviteeIndex == -1) {
            if (tripIndex == -1) {
              _changes.add({'myTripId': widget.myTripItem.id});
              tripIndex = _changes.length - 1;
              _changes[tripIndex]['invitees'] = [];
            }
            _changes[tripIndex]['invitees']
                .add(widget.groupDrivers[groupIndex].invitees[driverIndex]);
          }
          if (value == false) {
            for (int i = _changes.length - 1; i >= 0; i--) {
              if (_changes[i]['invitees'].isEmpty) {
                _changes.removeAt(i);
              }
            }
          }

          widget.onSelect!(_changes);
          debugPrint('widget.onSelect: ${_changes.toString()}');
        }),
      );
    } else {
      return Icon(inviteIcons[state]);
    }
  }

  int invitees() {
    int count = 0;
    for (int i = 0; i < widget.groupDrivers.length; i++) {
      for (int j = 0; j < widget.groupDrivers[i].invitees.length; j++) {
        if (widget.groupDrivers[i].invitees[j]['invite'] ?? false) {
          count++;
        }
      }
    }
    return count;
  }

  Widget tripDescription() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                child: Row(children: [
                  Expanded(
                    flex: 1,
                    child: Column(children: [
                      const Icon(Icons.route),
                      Text(
                        '${widget.myTripItem.distance.toStringAsFixed(1)} miles long',
                        style: labelStyle(
                          context: context,
                          size: 3,
                          color: Colors.black,
                        ),
                      )
                    ]),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(children: [
                      const Icon(Icons.landscape),
                      Text(
                        '${widget.myTripItem.pointsOfInterest.length} highlights',
                        style: labelStyle(
                          context: context,
                          size: 3,
                          color: Colors.black,
                        ),
                      )
                    ]),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(children: [
                      const Icon(Icons.social_distance),
                      Text(
                        '${(widget.myTripItem.distanceAway * metersToMiles).toStringAsFixed(1)} miles away',
                        style: labelStyle(
                          context: context,
                          size: 3,
                          color: Colors.black,
                        ),
                      )
                    ]),
                  ),
                ]),
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      widget.myTripItem.subHeading,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (widget.myTripItem.images.isNotEmpty)
                Row(children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (int i = 0; i < photos.length; i++)
                            Row(
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: Image.file(
                                    File(photos[i].url),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                ]),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(widget.myTripItem.body,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20),
                        textAlign: TextAlign.left),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  sendInvitations() async {
    if (widget.myTripItem.driveUri.isEmpty) {
      await widget.myTripItem.publish();
      widget.myTripItem.saveLocal();
    }

    Map<String, dynamic> toEmail = {
      'drive_id': widget.myTripItem.driveUri,
      'drive_date': dateFormatSQL.format(_date!),
      'title': widget.myTripItem.heading,
      'message': _instructions
    };
    List<Map<String, dynamic>> invited = [];
    for (int i = 0; i < widget.groupDrivers.length; i++) {
      for (int j = 0; j < widget.groupDrivers[i].invitees.length; j++) {
        if (widget.groupDrivers[i].invitees[j]['invite'] ?? false) {
          invited.add({'email': widget.groupDrivers[i].invitees[j]['email']});
        }
      }
    }
    if (invited.isNotEmpty) {
      toEmail['invited'] = invited;
      postGroupDrive(invitations: toEmail);
    }
  }
}
