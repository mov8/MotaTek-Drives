import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/services/db_helper.dart';
import 'dart:convert';
// import 'package:drives/services/web_helper.dart';

class GroupMemberForm extends StatefulWidget {
  // var setup;
  final GroupMember? groupMember;
  final String? groupName;
  final List<Group>? groups;

  GroupMemberForm({super.key, this.groupMember, this.groupName, this.groups});

  @override
  State<GroupMemberForm> createState() => _groupMemberFormState();
}

class _groupMemberFormState extends State<GroupMemberForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: Text(widget.groupName!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
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
                  ))),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            try {
              insertSetup(Setup());
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),
      ),
      body: portraitView(),
    );
  }

  Column portraitView() {
    // setup =  Settings().setup;
    return Column(children: <Widget>[
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your forename',
              labelText: 'Forename',
            ),
            textCapitalization: TextCapitalization.words,
            keyboardType: TextInputType.name,
            textAlign: TextAlign.left,
            initialValue: widget.groupMember?.forename,
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (text) {
              widget.groupMember?.edited = true;
              setState(() => widget.groupMember?.forename = text);
            },
          )),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextFormField(
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
          onChanged: (text) {
            widget.groupMember?.edited = true;
            setState(() => widget.groupMember?.surname = text);
          },
        ),
      ),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter email address',
              labelText: 'Email address',
            ),
            textAlign: TextAlign.left,
            initialValue: widget.groupMember?.email,
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (text) {
              widget.groupMember?.edited = true;
              setState(() => widget.groupMember?.email = text);
            },
          )),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter mobile phone number',
              labelText: 'Mobile phone number',
            ),
            textAlign: TextAlign.left,
            keyboardType: TextInputType.phone,
            initialValue: widget.groupMember?.phone,
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (text) {
              widget.groupMember?.edited = true;
              setState(() => widget.groupMember?.phone = text);
            },
          )),
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
                              value: isMember(widget.groups![index].id),
                              onChanged: (value) {
                                widget.groupMember?.edited = true;
                                setState(() {
                                  updateGroups(value!, index);
                                });
                              })
                          // ToDo: calculate how far away
                          )))))
    ]);
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
    debugPrint(result);
  }
}
