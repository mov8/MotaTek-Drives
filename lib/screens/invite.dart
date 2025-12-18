import 'dart:convert';
import '/classes/autocomplete_widget.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/services/db_helper.dart';
import '/services/web_helper.dart';

class InviteForm extends StatefulWidget {
  const InviteForm({super.key});

  @override
  State<InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<InviteForm> {
  late AutoCompleteAsyncController _controller;
  bool editing = false;
  TextInputAction action = TextInputAction.done;
  int selected = 0;
  final List<String> dropdownOptions = [];
  Map<String, dynamic> options = {
    "email": "",
    "greeting": false,
    "version": false,
    "notes": false,
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
          'Invite user ',
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
              'Invite user to test Drives',
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
      body: portraitView(),
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
                optionsMaxHeight: 100,
                optionsMinHeight: 50,
                textInputAction: TextInputAction.next,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter greeting',
                  labelText: 'User greeting',
                ),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                initialValue: '',
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  options["greeting"] = text;
                  text;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'APK Version',
                  labelText: 'Version',
                ),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                initialValue: '',
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  options["version"] = text;
                  text;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any instructions',
                  labelText: 'User instructions',
                ),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                initialValue: '',
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  options["instructions"] = text;
                  text;
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ActionChip(
                  onPressed: () => inviteUser(options: options),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  label: Text('Invite user',
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
    dropdownOptions.addAll(await getApiContacts(value: query));
    // debugPrint(
    //     'For query query $query dropdownOptions.length = ${dropdownOptions.length}');
    setState(() {});
  }

  inviteUser({required Map<String, dynamic> options}) async {
    int code = await inviteWebUser(body: jsonEncode(options));
    debugPrint('InviteWebUser return code: $code');
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
