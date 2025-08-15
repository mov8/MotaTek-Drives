import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:drives/classes/classes.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreensAppBar(
        heading: 'Drives groups to which I belong',
        prompt: 'Swipe left to remove yourself from group.',
        updateHeading: 'You have changed group details.',
        updateSubHeading: 'Press Update to confirm the changes or Ignore',
        update: _changed,
        showAction: _changed,
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

          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  void update() {
    updateGroups(groups: _dismissed, action: GroupAction.leave);
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
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
                background: Container(color: Colors.blueGrey),
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _dismissed.add(Group(id: groups[index].id, name: ''));
                    _changed = true;
                    setState(() => groups.removeAt(index));
                  }
                },
                child: Card(
                  elevation: 5,
                  child: ListTile(
                    title: Text(
                      groups[index].name,
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
                            'Organiser: ${groups[index].ownerForename} ${groups[index].ownerSurname}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Text('email: ${groups[index].ownerEmail}'),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Text('tel: ${groups[index].ownerPhone}'),
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Members: ${groups[index].memberCount}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ])
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    return widget;
  }

  void onDelete(int index) {
    return;
  }
}
