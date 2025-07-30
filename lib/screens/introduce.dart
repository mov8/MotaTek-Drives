import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/constants.dart';

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

  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  TextEditingController controller3 = TextEditingController();
  TextEditingController controller4 = TextEditingController();
  bool edited = false;
  bool showChip = false;
  bool sentOk = false;
  int introduceIndex = 0;
  String testString = '';
  List<bool> fieldStates = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    fn1.dispose();
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
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
    showChip = dataComplete() ? showChip : false;
    return Column(
      children: [
        Expanded(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                autofocus: true,
                focusNode: fn1,
                textInputAction: TextInputAction.next,
                controller: controller1,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter forename',
                  labelText: 'Forename',
                  suffixIcon: Icon(fieldStates[0]
                      ? Icons.check_circle_outline
                      : Icons.star_outline),
                ),
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                textAlign: TextAlign.left,
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
                controller: controller2,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter surname',
                    labelText: 'Surname',
                    suffixIcon: Icon(fieldStates[1]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
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
                controller: controller3,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter email address',
                    labelText: 'Email address',
                    suffixIcon: Icon(fieldStates[2]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  invited['email'] = text;
                  if (!showChip && dataComplete()) {
                    setState(() => showChip = true);
                  }
                },
                validator: (value) =>
                    value != null && !emailRegex.hasMatch(value)
                        ? 'Enter a valid email address'
                        : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.done,
                controller: controller4,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter mobile phone number',
                    labelText: 'Mobile phone number',
                    suffixIcon: Icon(fieldStates[3]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.phone,
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
                ? Wrap(spacing: 10, children: [
                    ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () async {
                        invited['new_user'] = true;
                        sentOk =
                            await inviteWebUser(body: jsonEncode(invited)) ==
                                200;
                        setState(() => sentOk);
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
                    ),
                    if (sentOk) ...[
                      ActionChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => setState(() => clearData()),
                        backgroundColor: Colors.blue,
                        avatar: const Icon(
                          Icons.clear_all_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Clear data',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      )
                    ]
                  ])
                : null,
          ),
        ),
      ],
    );
  }

  bool dataComplete() {
    bool update = false;
    if (fieldStates[0] != (invited['forename'] ?? '').length > 2) {
      fieldStates[0] = (invited['forename'] ?? '').length > 2;
      update = true;
    }
    if (fieldStates[1] != (invited['surname'] ?? '').length > 2) {
      fieldStates[1] = (invited['surname'] ?? '').length > 2;
      update = true;
    }
    if (fieldStates[2] != emailRegex.hasMatch(invited['email'] ?? '')) {
      fieldStates[2] = emailRegex.hasMatch(invited['email'] ?? '');
      update = true;
    }
    if (fieldStates[3] != (invited['phone'] ?? '').length > 9) {
      fieldStates[3] = (invited['phone'] ?? '').length > 9;
      update = true;
    }
    if (update) {
      setState(() => ());
    }
    return fieldStates[0] && fieldStates[1] && fieldStates[2] && fieldStates[3];
  }

  clearData() {
    fieldStates = [false, false, false, false];
    invited = {};
    controller1.clear();
    controller2.clear();
    controller3.clear();
    controller4.clear();
    fn1.requestFocus();
  }
}
