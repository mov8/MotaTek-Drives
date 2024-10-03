import 'dart:convert';
import 'package:drives/tiles/group_member_tile.dart';
import 'package:drives/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
// import 'package:drives/screens/dialogs.dart';

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
    // if (introduceMembers.isEmpty) {
    //   newMember();
    // }
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();

    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    introduceMembers = await getIntroduced();
    // introduceMembers.add(GroupMember(forename: '', surname: ''));
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
            return introduceMembers.isEmpty
                ? portraitViewNew()
                : portraitView();
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
            itemBuilder: (context, index) => GroupMemberTile(
              groupMember: introduceMembers[index],
              index: index,
              onDelete: onDelete,
              onEdit: onEdit,
              onSelect: onSelect,
              // ToDo: calculate how far away
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  Column portraitViewNew() {
    introduceMembers.add(GroupMember(forename: '', surname: ''));
    return Column(
      children: [
        Expanded(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                  //        onFieldSubmitted: (val) => setState(() {
                  //          val = val.trim();
                  //          introduceMembers[introduceMembers.length - 1].forename = val;
                  //        }),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter forename',
                    labelText: 'Forename',
                  ),
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  textAlign: TextAlign.left,
                  initialValue:
                      introduceMembers[introduceMembers.length - 1].forename,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) {
                    introduceMembers[introduceMembers.length - 1].edited = true;
                    introduceMembers[introduceMembers.length - 1].forename =
                        text;
                  }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                  //       onFieldSubmitted: (val) => setState(() {
                  //         val = val.trim();
                  //         introduceMembers[introduceMembers.length - 1].surname = val;
                  //       }),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter surname',
                    labelText: 'Surname',
                  ),
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  initialValue:
                      introduceMembers[introduceMembers.length - 1].surname,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) {
                    introduceMembers[introduceMembers.length - 1].selected =
                        true;
                    introduceMembers[introduceMembers.length - 1].edited = true;
                    introduceMembers[introduceMembers.length - 1].surname =
                        text;
                  }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                  textInputAction: TextInputAction.next,
                  //         onFieldSubmitted: (val) => setState(() {
                  //           val = val.trim();
                  //           introduceMembers[introduceMembers.length - 1].email = val;
                  //         }),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter email address',
                    labelText: 'Email address',
                  ),
                  textAlign: TextAlign.left,
                  initialValue:
                      introduceMembers[introduceMembers.length - 1].email,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) {
                    introduceMembers[introduceMembers.length - 1].selected =
                        true;
                    introduceMembers[introduceMembers.length - 1].edited = true;
                    introduceMembers[introduceMembers.length - 1].email =
                        text.toLowerCase();
                  }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                  //onFieldSubmitted: (val) => setState(() {
                  //      val = val.trim();
                  //      introduceMembers[introduceMembers.length - 1].phone = val;
                  //    }),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter mobile phone number',
                    labelText: 'Mobile phone number',
                  ),
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.phone,
                  initialValue:
                      introduceMembers[introduceMembers.length - 1].phone,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) {
                    introduceMembers[introduceMembers.length - 1].selected =
                        true;
                    introduceMembers[introduceMembers.length - 1].edited = true;
                    introduceMembers[introduceMembers.length - 1].phone = text;
                  }),
            ),
            /*
            Expanded(
              child: SizedBox(
                height: (MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    20 * 0.93), // 200,
                child: ListView.builder(
                  itemCount: widget.groups?.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5.0),
                    child: Card(
                      child: CheckboxListTile(
                        title: Text(widget.groups![index].name),
                        value: true, //isMember(widget.groups![index].id),
                        onChanged: (value) {
                          widget.groupMember?.edited = true;
                          setState(
                            () {
                              updateGroups(value!, index);
                            },
                          );
                        },
                      ),
                      // ToDo: calculate how far away
                    ),
                  ),
                ),
              ),
            ),
            if (widget.groupMember!.id != '') ...[
              //]>= 0) ...[
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ActionChip(
                    onPressed: () =>
                        (), // deleteMember(widget.groupMember!.id),
                    backgroundColor: Colors.blue,
                    avatar: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    label: const Text('Delete Member',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ),
            ] */
          ]),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => ()),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              label: const Text(
                'Back',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
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
      ]),
    );
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
          groupName: 'Introduce new user', // groupName,
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
    //int currentId = 1;
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
