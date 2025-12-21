import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/screens/dialogs.dart';
import 'dart:convert';

class GroupMemberForm extends StatefulWidget {
  // var setup;
  final GroupMember? groupMember;
  final String? groupName;
  final List<Group>? groups;

  const GroupMemberForm(
      {super.key, this.groupMember, this.groupName, this.groups});

  @override
  State<GroupMemberForm> createState() => _GroupMemberFormState();
}

class _GroupMemberFormState extends State<GroupMemberForm> {
  late FocusNode fn1;
  bool editing = false;
  TextInputAction action = TextInputAction.done;
  int currentPageIndex = 0;
  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    editing = widget.groupMember!.forename.isNotEmpty;
    action = editing ? TextInputAction.done : TextInputAction.next;
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();

    super.dispose();
  }

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
        title: Text(
          widget.groupName!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              widget.groupMember?.forename == '' &&
                      widget.groupMember?.surname == ''
                  ? 'New Member'
                  : '${widget.groupMember?.forename} ${widget.groupMember?.surname}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: portraitView(),
    );
  }

  Column portraitView() {
    return Column(
      children: [
        Expanded(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                onFieldSubmitted: (val) => setState(() {
                  val = val.trim();
                  widget.groupMember?.forename = val;
                }),
                autofocus: !editing,
                textInputAction: action,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter forename',
                  labelText: 'Forename',
                ),
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                textAlign: TextAlign.left,
                initialValue: widget.groupMember?.forename,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) => widget.groupMember?.edited = true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                onFieldSubmitted: (val) => setState(() {
                  val = val.trim();
                  widget.groupMember?.surname = val;
                }),
                textInputAction: action,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter surname',
                  labelText: 'Surname',
                ),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                initialValue: widget.groupMember?.surname,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) => widget.groupMember?.edited = true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                textInputAction: action,
                onFieldSubmitted: (val) => setState(() {
                  val = val.trim();
                  widget.groupMember?.email = val;
                }),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter email address',
                  labelText: 'Email address',
                ),
                textAlign: TextAlign.left,
                initialValue: widget.groupMember?.email,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) => widget.groupMember?.edited = true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                onFieldSubmitted: (val) => setState(() {
                  val = val.trim();
                  widget.groupMember?.phone = val;
                }),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter mobile phone number',
                  labelText: 'Mobile phone number',
                ),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.phone,
                initialValue: widget.groupMember?.phone,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) => widget.groupMember?.edited = true,
              ),
            ),
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
            ]
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

  bool isMember(int id) {
    if (widget.groupMember!.groupIds.isNotEmpty) {
      var groupIds = jsonDecode(widget.groupMember!.groupIds);
      for (int j = 0; j < groupIds.length; j++) {
        if (groupIds[j]['groupId'] == id) {
          return true;
        }
      }
    }
    return false;
  }

  updateGroups(bool value, int index) {
    String result = '';
    if (widget.groupMember!.groupIds.isNotEmpty) {
      var groupIds = jsonDecode(widget.groupMember!.groupIds);
      groupIds.removeWhere(
          (element) => element['groupId'] == widget.groups![index].id);
      for (int i = 0; i < groupIds.length; i++) {
        result = '$result, {"groupId": ${groupIds[i]['groupId']}}';
      }
    }
    if (value == true) {
      result = '$result, {"groupId": ${widget.groups![index].id}}';
    }
    if (result.isNotEmpty) {
      result = '[${result.substring(2)}]';
    }
    widget.groupMember?.groupIds = result;
//    debugPrint(result);
  }

  Future<void> deleteMember(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete member?',
        alertMessage:
            '${widget.groupMember?.forename} ${widget.groupMember?.surname}',
        okValue: 1, //widget.groupMember!.id,
        callback: onConfirmDeleteMember);
  }

  void onConfirmDeleteMember(int value) {
    // debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      // deleteGroupMemberById(value);
      widget.groupMember?.index = -1;
      Navigator.pop(context);
    }
  }
}
