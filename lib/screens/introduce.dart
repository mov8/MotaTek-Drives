import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart';

class IntroduceForm extends StatefulWidget {
  // var setup;

  const IntroduceForm({super.key, setup});

  @override
  State<IntroduceForm> createState() => _IntroduceFormState();
}

class _IntroduceFormState extends State<IntroduceForm> {
  int introduce = 0;
  bool choosing = true;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  List<GroupMember> introduceMembers = [];

  String introduceName = 'Driving introduce';
  bool edited = false;
  bool showChip = false;
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
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
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
        title: const Text('Drives introduction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              'Introduce new user',
              style: TextStyle(
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

          throw ('Error - FutureBuilder introduce.dart');
        },
      ),
    );
  }

  Map<String, dynamic> invited = {};

  Column portraitView() {
    introduceMembers.add(GroupMember(forename: '', surname: ''));

    showChip = dataComplete() ? showChip : false;
    return Column(
      children: [
        Expanded(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
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
                  invited['forename'] = text;
                  if (!showChip && dataComplete()) {
                    setState(() => showChip = true);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
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
                  invited['surname'] = text;
                  text;
                  if (!showChip && dataComplete()) {
                    setState(() => showChip = true);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.next,
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
                  invited['email'] = text;
                  if (!showChip && dataComplete()) {
                    setState(() => showChip = true);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
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
                  invited['phone'] = text;
                  if (!showChip && dataComplete()) {
                    setState(() => showChip = true);
                  }
                },
              ),
            ),
          ]),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
            child: showChip
                ? ActionChip(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () {
                      invited['new_user'] = true;
                      inviteWebUser(body: jsonEncode(invited));
                      setState(() => ());
                    },
                    backgroundColor: Colors.blue,
                    avatar: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Send invitation',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  bool dataComplete() {
    return (invited['email'] ?? '').isNotEmpty &&
        (invited['forename'] ?? '').isNotEmpty &&
        (invited['surname'] ?? '').isNotEmpty &&
        (invited['phone'] ?? '').isNotEmpty;
  }
}
