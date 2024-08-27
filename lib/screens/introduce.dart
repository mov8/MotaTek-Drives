import 'dart:convert';
import 'package:drives/tiles/group_member_tile.dart';
import 'package:drives/screens/group_member.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/screens/dialogs.dart';

import 'package:drives/services/web_helper.dart';

class IntroduceForm extends StatefulWidget {
  // var setup;

  const IntroduceForm({super.key, setup});

  @override
  State<IntroduceForm> createState() => _introduceFormState();
}

class _introduceFormState extends State<IntroduceForm> {
  int introduce = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<GroupMember> introduceMembers = [];

  String introduceName = 'Driving introduce';
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
    introduceMembers = await getIntroduced();
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
        title: const Text('MotaTek introduction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text('Introduce new user',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
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
                    child: CircularProgressIndicator()));
          }

          throw ('Error - FutureBuilder introduce.dart');
        },
      ),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Widget portraitView() {
    // setup =  Settings().setup;

    return /* KeyboardVisibilityListener(
      listener: _listener,
      child: */
        Column(children: [
      Expanded(
          child: SizedBox(
              height: (MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  kBottomNavigationBarHeight -
                  20 * 0.93), // 200,
              child: ListView.builder(
                  itemCount: introduceMembers.length,
                  itemBuilder: (context, index) => Card(
                      elevation: 5,
                      child: GroupMemberTile(
                        groupMember: introduceMembers[index],
                        index: index,
                        onDelete: onDelete,
                        onEdit: onEdit,
                        onSelect: onSelect,
                        // ToDo: calculate how far away
                      ))))),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  void _listener(bool value) {
    if (value) {
      debugPrint('Listener called true');
    } else {
      debugPrint('Listener called false');
      setState(() => choosing = true);
    }
    return;
  }

  Widget _handleChips() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(spacing: 10, children: [
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => newMember(),
            backgroundColor: Colors.blue,
            avatar: const Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            label: const Text('Introduce new user',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          ActionChip(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => putIntroduced(introduceMembers),
            backgroundColor: Colors.blue,
            avatar: const Icon(
              Icons.outgoing_mail,
              color: Colors.white,
            ),
            label: const Text('Send introductions',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]));
  }

  void onDelete(int index) {
    introduceMembers.removeAt(index);
    return;
  }

  void newMember() {
    introduceMembers.add(GroupMember(forename: '', surname: ''));
    onEdit(introduceMembers.length - 1);
  }

  void onSelect(int index) {
    setState(() {
      //   introduceMembers[index].selected = !introduceMembers[index].selected;
    });
    return;
  }

  void onEdit(int index) async {
    // edited = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupMemberForm(
          groupMember: introduceMembers[index],
          groupName: 'Un-grouped', // groupName,
          groups: const [])),
    );
    setState(() {
      if (introduceMembers[index].forename.isEmpty ||
          introduceMembers[index].surname.isEmpty ||
          introduceMembers[index].email.isEmpty) {
        Utility().showConfirmDialog(context, "Missing information",
            "Records without a forename, surname or email can't be saved");
        introduceMembers.removeAt(index);
      }
    });
    return;
  }

  Future<bool> saveintroduce() async {
    int currentId = 1;
    //introduceMembers[introduceIndex].id;
    /* saveintroduceLocal(introduces[introduceIndex]).then((id) {
      if (currentId < 0) {
        for (int i = 0; i < filteredintroduceMembers.length; i++) {
          updateintroduceMembers(filteredintroduceMembers[i], currentId, id);
        }
      }
      introduces[introduceIndex].id = id;
      for (int i = 0; i < filteredintroduceMembers.length; i++) {
        saveintroduceMemberLocal(filteredintroduceMembers[i]).then((id) {
          introduceMembers[filteredintroduceMembers[i].index].id = id;
          introduceMembers[filteredintroduceMembers[i].index].edited = false;
          setState(() {});
        });
      }
    });
    setState(() {
      introduces[introduceIndex].edited = false;
      introduceName = introduces[introduceIndex].name;
      filterintroduce();
    });
    */
    return true;
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
    // edited = true;
    /*
    int parentIndex = filteredintroduceMembers[index].index;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => introduceMemberForm(
                introduceMember: filteredintroduceMembers[index],
                introduceName: introduceIndex >= 0
                    ? introduces[introduceIndex].name
                    : 'Un-introduceed', // introduceName,
                introduces: introduces,
              )),
    ).then((value) {
      setState(() {
        /// if deleted in introduceMemberForm filteredintroduceMembers[index].index is set to -1
        if (filteredintroduceMembers[index].index == -1) {
          introduceMembers.removeAt(parentIndex);
        } else if (filteredintroduceMembers[index].forename.isEmpty &&
            filteredintroduceMembers[index].surname.isEmpty) {
          Utility().showConfirmDialog(context, "Missing information",
              "Records without a forename and surname can't be saved");
          introduceMembers.removeAt(filteredintroduceMembers[index].index);
        } else {
          edited = filteredintroduceMembers[index].edited ? true : edited;
          if (introduceIndex >= 0) {
            introduces[introduceIndex].edited =
                filteredintroduceMembers[index].edited
                    ? true
                    : introduces[introduceIndex].edited;
          }
        }
        filterintroduce();
      });
    });
    */
    return;
  }
}

int test() {
  return 1;
}
