import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart';
import '/helpers/hive_helpers.dart';

class ShareForm extends StatefulWidget {
  final MyTripItem tripItem;
  const ShareForm({super.key, required this.tripItem});

  @override
  State<ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends State<ShareForm> {
  late List<GroupDriveByGroup> _groups;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives share a trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              widget.tripItem.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            try {
              saveSetupLocally();
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text('Invite other drives to enjoy your drive',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          DriveInvitations(
            index: 1,
            groupDrivers: _groups,
            myTripItem: widget.tripItem,
          )
        ]),
      ),
    );
  }
}
