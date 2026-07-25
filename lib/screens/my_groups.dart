import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '/constants.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';

class MyGroupsForm extends StatefulWidget {
  // var setup;

  const MyGroupsForm({super.key, setup});

  @override
  State<MyGroupsForm> createState() => _MyGroupsFormState();
}

class _MyGroupsFormState extends State<MyGroupsForm> {
  int group = 0;
  late Future<bool> dataloaded;
  List<Group> groups = [];
  final List<Group> _dismissed = [];

  String groupName = 'Driving Group';

  bool _changed = false;

  @override
  void initState() {
    super.initState();
    // dataloaded = dataFromDatabase();
    dataloaded = dataFromWeb();
  }

  Future<bool> dataFromWeb() async {
    groups = await getMyGroups();
    return true;
  }

  String prompt = 'Swipe left to remove yourself from group.';

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ScreensAppBarBottom(
        prompt: prompt,
        textColor: Color.fromRGBO(1, 29, 51, 1),
        content: FutureBuilder<bool>(
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
            return Center(
              child: Text(
                'Error building My Groups content',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            );
          },
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.blue,
        appBar: ScreensAppBar(
          heading: 'Drives groups to which I belong',
          prompt: prompt,
          updateHeading: 'You have changed group details.',
          updateSubHeading: 'Press Save to confirm the changes or Ignore',
          update: _changed,
          showAction: _changed,
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
            return Center(
              child: Text(
                'Error building My Groups content',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            );
            //  throw ('Error - FutureBuilder group.dart');
          },
        ),
      );
    }
  }

  void _update({bool update = false}) {
    if (update) {
      updateGroups(groups: _dismissed, action: GroupAction.leave);
    }
    setState(() => _changed = false);
  }

  Widget portraitView() {
    Widget widget;
    if (groups.isEmpty && !_changed) {
      widget = Center(
        child: SizedBox(
            height: 120,
            child: Column(
              children: [
                Text(
                  "You haven't been added to any groups yet.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Why not start your own Drives group?",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            )),
        //    ),
      );
    } else {
      widget = Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // children[//]
        //Expanded(
        //child: ListView.builder(
        //itemCount: groups.length,
        //itemBuilder: (context, index) =>
        //
        for (int idx = 0; idx < groups.length; idx++) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(color: Colors.blueGrey),
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _dismissed.add(Group(id: groups[idx].id, name: ''));
                  _changed = true;
                  setState(() => groups.removeAt(idx));
                }
              },
              child: Card(
                elevation: 5,
                child: ListTile(
                  title: Text(
                    groups[idx].name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(children: [
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Organiser: ${groups[idx].ownerForename} ${groups[idx].ownerSurname}',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: Text('email: ${groups[idx].ownerEmail}'),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: Text('tel: ${groups[idx].ownerPhone}'),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Members: ${groups[idx].memberCount}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ])
                  ]),
                ),
              ),
            ),
          ),
        ]
        // ),
        // ),
      ]);
    }

    return widget;
  }

  void onDelete(int index) {
    return;
  }
}
