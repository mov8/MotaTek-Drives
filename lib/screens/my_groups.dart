import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class MyGroupsForm extends StatefulWidget {
  // var setup;

  const MyGroupsForm({super.key, setup});

  @override
  State<MyGroupsForm> createState() => _MyGroupsFormState();
}

class _MyGroupsFormState extends State<MyGroupsForm> {
  int group = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  late GroupMember newMember;
  late Group newGroup;
  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  // final _formKey = GlobalKey<FormState>();
  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  // double _emailSizedBoxHeight = 70;
  // bool _validate = false;
  // String _validateMessage = '';
  String testString = '';
  bool addingMember = false;
  bool addingGroup = false;
  bool editingGroup = false;
  int _changed = 0;

  List<GroupMember> allMembers = [];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    // dataloaded = dataFromDatabase();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    groups = await loadGroups();
    groupMembers = await loadGroupMembers();
    if (groups.isEmpty) {
      groups.add(Group(id: '', name: '', edited: true));
      groupIndex = 0;
      edited = true;
    }
    return true;
  }

  Future<bool> dataFromWeb() async {
    groups = await getMyGroups();
    return true;
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
        title: const Text('MotaTek groups',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text("Groups of which I'm a member:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ))),
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

          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView() {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Card(
              elevation: 5,
              child: CheckboxListTile(
                title: Text(
                  groups[index].name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(children: [
                  Row(children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                          'Organiser: ${groups[index].ownerForename} ${groups[index].ownerSurname}'),
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
                      child: Text('Members: ${groups[index].memberCount}'),
                    ),
                  ])
                ]),
                value: groups[index].selected,
                onChanged: (value) => setState(() {
                  groups[index].selected = !groups[index].selected;
                  _changed += groups[index].selected ? index + 1 : -(index + 1);
                  debugPrint('_changed = $_changed');
                }),
              ),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: _changed == 0 ? null : _handleChips(),
      )
    ]);
  }

  Widget _handleChips() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(spacing: 10, children: [
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () async {
              for (Group group in groups) {
                if (group.edited) {
                  // await putGroup(groups[groupIndex]);
                }
              }
            },
            backgroundColor: Colors.blue,
            avatar: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save Changes',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]));
  }

  void onDelete(int index) {
    return;
  }

  void onSelect(int index) {
    int idx = groups[groupIndex].groupMembers().indexOf(allMembers[index]);
    if (allMembers[index].selected) {
      if (idx >= 0) {
        groups[groupIndex].removeMember(idx);
        groups[groupIndex].edited = true;
      }
    } else if (idx < 0) {
      groups[groupIndex].addMember(allMembers[index]);
      groups[groupIndex].edited = true;
    }
    return;
  }
}
