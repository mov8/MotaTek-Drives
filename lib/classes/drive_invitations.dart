import 'dart:io';
import 'package:drives/services/web_helper.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';

class DriveInvitations extends StatefulWidget {
  final int index;
  final MyTripItem myTripItem;
  final List<GroupDriveByGroup> groupDrivers;
  const DriveInvitations(
      {super.key,
      required this.index,
      required this.groupDrivers,
      required this.myTripItem});
  @override
  State<DriveInvitations> createState() => _DriveInvitationsState();
}

class _DriveInvitationsState extends State<DriveInvitations>
    with TickerProviderStateMixin {
  late TabController _tController;

  late List<Photo> photos;
  String _instructions = '';
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _tController = TabController(length: 3, vsync: this);
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _tController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    photos = photosFromJson(widget.myTripItem.images);
    return Column(
      children: [
        TabBar(
          controller: _tController,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: [
            Tab(icon: Icon(Icons.group_outlined), text: 'Invite Drivers'),
            Tab(icon: Icon(Icons.outgoing_mail), text: 'Send Invitations'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Drive Details'),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: TabBarView(
            controller: _tController,
            children: [
              invited(),
              invitation(),
              tripDescription(),
            ],
          ),
        ),
      ],
    );
  }

  Widget invited() {
    return Column(
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: widget.groupDrivers[index].invitees.length,
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
                      ),
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
          onChanged: (value) => setState(() => widget.groupDrivers[groupIndex]
              .invitees[driverIndex]['invite'] = value));
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

  Widget invitation() {
    DateTime tripDate = _date!;
    int toInvite = invitees();
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toInvite == 0) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
                  child: Text(
                    "You haven't invited anyone yet",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            if (toInvite > 0) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                child: InkWell(
                  onTap: () async {
                    _date = await showDatePicker(
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
                        child: Text(
                          'Group drive date: ${dateFormatDoc.format(_date!)}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 0, 5),
                child: Text(
                  "Enter the instructions for trip",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  initialValue: _instructions,
                  onChanged: (text) => _instructions = text,
                ),
              ),
              Center(
                child: ActionChip(
                  onPressed: () => sendInvitations(),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.outgoing_mail,
                    color: Colors.white,
                  ),
                  label: Text(
                      'Send $toInvite invitation${toInvite == 1 ? '' : 's'}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget tripDescription() {
    return Padding(
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
                    Text('${widget.myTripItem.distance} miles long')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.landscape),
                    Text(
                        '${widget.myTripItem.pointsOfInterest.length} highlights')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.social_distance),
                    Text('${widget.myTripItem.closest} miles away')
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
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      textAlign: TextAlign.left),
                ),
              ),
            ),
          ],
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
