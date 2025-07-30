// import 'package:drives/classes/classes.dart';
import 'package:drives/classes/autocomplete_widget.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/db_helper.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/constants.dart';

/*
 app sends a dict {"email": "", "user": bool, "trips": bool, "pois": bool,
 "roads": bool, "ratings": bool, "groups": bool}
 
 email identifies the user to process
 user:
    true: the user gets deleted
    false: doesn't get deleted
trips ... groups:
    true: the item get deleted
    false: the item get handed to a user called "anonymous user"
    
if the drive is deleted and not the points of interest etc then they
are handed to the anonymous user for a drive called unnamed drive

Table dependencies

table								      user_id		drive_id	group_id	group_drive_id	points_of_interest_id
downloads							    yes			  yes			  no			  no				      no
drive_ratings						  yes			  yes			  no			  no				      no
drives								    yes			  id			  no			  no				      no
good_roads							  no			  yes			  no			  no				      yes
group_drive_invitations	  yes			  no			  no			  yes				      no
group_drives						  yes			  yes			  no			  id				      no
group_members						  yes			  no			  yes			  no				      no
groups								    yes			  no			  no			  no				      no		
introduced							  yes			  no			  no			  no				      no
maneuvers							    no			  yes			  no			  no				      no
messages							    1*			  no			  2*			  no				      no
point_of_interest_ratings	yes			  no			  no			  no				      yes		
points_of_interest				no			  no			  no			  no				      id
polylines							    no			  yes			  no			  no				      no

delete drive: polylines, maneuvers, group_drives, drive_ratings, downloads, m/d good_roads, drives 
delete pois: points_of_interest_ratings, images, m/d good_roads 
delete good_roads: good_roads
delete ratings: point_of_interest_ratings, drive_ratings
user groups: user_id to removed user 

move drive: drive_ratings, drives, group_drive_invitations, group_drives, group_   

1* user_id + user_target_id
2* group_target_id

 */

class DeleteUserForm extends StatefulWidget {
  const DeleteUserForm({super.key});

  @override
  State<DeleteUserForm> createState() => _DeleteTripsFormState();
}

class _DeleteTripsFormState extends State<DeleteUserForm> {
  final List<TripSummary> _drives = [];
  late AutoCompleteAsyncController _controller;
  bool editing = false;
  TextInputAction action = TextInputAction.done;
  int selected = 0;
  final List<String> dropdownOptions = [];
  Map<String, dynamic> options = {
    "email": "",
    "user": false,
    "trips": false,
    "pois": false,
    "roads": false,
    "ratings": false,
    "groups": false
  };

  @override
  void initState() {
    super.initState();
    _controller = AutoCompleteAsyncController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<TripSummary>> _loadTrips(
      {required List<TripSummary> tripSummaries}) async {
    if (tripSummaries.isEmpty) {
      try {
        //  debugPrint('_loadTrips called');
        tripSummaries.addAll(await getTripSummaries(
            northEast: ukNorthEast, southWest: ukSouthWest));
      } catch (e) {
        debugPrint('Error downloading trip summaries = ${e.toString()}');
      }
    }
    return tripSummaries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Delete user ',
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
              'Delete user from the server',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<TripSummary>>(
        future: _loadTrips(tripSummaries: _drives),
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
          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView() {
    // List<String> dropdownOptions = [];
    return SingleChildScrollView(
      child: SizedBox(
        height: (MediaQuery.of(context).size.height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: AutocompleteAsync(
                controller: _controller,
                options: dropdownOptions,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter users email address',
                  labelText: 'Email address',
                ),
                keyboardType: TextInputType.emailAddress,
                onSelect: (chosen) => options["email"] = chosen,
                onChange: (text) => options["email"] = text,
                onUpdateOptionsRequest: (query) => getDropdownItems(query),
              ),
            ),
            SwitchListTile(
              title: Text('Remove User',
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["user"],
              onChanged: (bool value) =>
                  setState(() => options["user"] = value),
              secondary: const Icon(Icons.person_off_outlined, size: 30),
            ),
            SwitchListTile(
              title: Text("Remove user's trips",
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["trips"],
              onChanged: (bool value) =>
                  setState(() => options["trips"] = value),
              secondary: const Icon(Icons.directions_car_outlined, size: 30),
            ),
            SwitchListTile(
              title: Text("Remove user's points of interest",
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["pois"],
              onChanged: (bool value) =>
                  setState(() => options["pois"] = value),
              secondary: const Icon(Icons.castle_outlined, size: 30),
            ),
            SwitchListTile(
              title: Text("Remove user's good roads",
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["roads"],
              onChanged: (bool value) =>
                  setState(() => options["roads"] = value),
              secondary: const Icon(Icons.remove_road_outlined, size: 30),
            ),
            SwitchListTile(
              title: Text("Remove user's ratings",
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["ratings"],
              onChanged: (bool value) =>
                  setState(() => options["ratings"] = value),
              secondary: const Icon(Icons.star_outline_outlined, size: 30),
            ),
            SwitchListTile(
              title: Text("Remove user's groups",
                  style: Theme.of(context).textTheme.bodyLarge!),
              value: options["groups"],
              onChanged: (bool value) =>
                  setState(() => options["groups"] = value),
              secondary: const Icon(Icons.group_remove_outlined, size: 30),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ActionChip(
                  onPressed: () => deleteUser(options: options),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  label: Text('Remove user',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getDropdownItems(String query) async {
    dropdownOptions.clear();
    dropdownOptions.addAll(await getApiOptions(value: query));
    setState(() {});
  }

  deleteUser({required Map<String, dynamic> options}) async {
    if (options["user"] ||
        options["trips"] ||
        options["pois"] ||
        options["roads"] ||
        options["ratings"] ||
        options["groups"]) {
      await deleteWebUser(uriMap: options);
      setState(() => dropdownOptions.clear());
    }
  }

  void onConfirmDeleteMember(int value) {
    // debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      deleteGroupMemberById(value);
      //  widget.groupMember?.index = -1;
      Navigator.pop(context);
    }
  }
}
