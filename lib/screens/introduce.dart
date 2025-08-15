import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/classes.dart';

class IntroduceForm extends StatefulWidget {
  const IntroduceForm({super.key, setup});

  @override
  State<IntroduceForm> createState() => _IntroduceFormState();
}

class _IntroduceFormState extends State<IntroduceForm> {
  late FocusNode _fn1;
  late TextEditingController _controller1;
  late TextEditingController _controller2;
  late TextEditingController _controller3;
  late TextEditingController _controller4;

  bool _isComplete = false;
  List<bool> _fieldStates = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _fn1 = FocusNode();
    _controller1 = TextEditingController();
    _controller2 = TextEditingController();
    _controller3 = TextEditingController();
    _controller4 = TextEditingController();
  }

  @override
  void dispose() {
    _fn1.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreensAppBar(
        heading: 'Introduce a new user to Drives',
        prompt: 'Please enter all the details below.',
        updateHeading: 'You have added user details.',
        updateSubHeading: 'Press Update to confirm the changes or Ignore',
        update: _isComplete,
        updateMethod: invite,
        showAction: _isComplete,
      ),
      body: portraitView(),
    );
  }

  Map<String, dynamic> invited = {};

  Column portraitView() {
    _isComplete = dataComplete() ? _isComplete : false;
    return Column(
      children: [
        Expanded(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                autofocus: true,
                focusNode: _fn1,
                textInputAction: TextInputAction.next,
                controller: _controller1,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter forename',
                  labelText: 'Forename',
                  suffixIcon: Icon(_fieldStates[0]
                      ? Icons.check_circle_outline
                      : Icons.star_outline),
                ),
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  invited['forename'] = text;
                  if (!_isComplete && dataComplete()) {
                    setState(() => _isComplete = true);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.next,
                controller: _controller2,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter surname',
                    labelText: 'Surname',
                    suffixIcon: Icon(_fieldStates[1]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  invited['surname'] = text;
                  text;
                  if (!_isComplete && dataComplete()) {
                    setState(() => _isComplete = true);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                textInputAction: TextInputAction.next,
                controller: _controller3,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter email address',
                    labelText: 'Email address',
                    suffixIcon: Icon(_fieldStates[2]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  invited['email'] = text;
                  if (!_isComplete && dataComplete()) {
                    setState(() => _isComplete = true);
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
                controller: _controller4,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter mobile phone number',
                    labelText: 'Mobile phone number',
                    suffixIcon: Icon(_fieldStates[3]
                        ? Icons.check_circle_outline
                        : Icons.star_outline)),
                textAlign: TextAlign.left,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (text) {
                  invited['phone'] = text;
                  if (!_isComplete && dataComplete()) {
                    setState(() => _isComplete = true);
                  }
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }

  void invite() async {
    invited['new_user'] = true;
    await inviteWebUser(body: jsonEncode(invited)) == 200;
    setState(() => clearData());

    return;
  }

  bool dataComplete() {
    bool update = false;
    if (_fieldStates[0] != (invited['forename'] ?? '').length > 2) {
      _fieldStates[0] = (invited['forename'] ?? '').length > 2;
      update = true;
    }
    if (_fieldStates[1] != (invited['surname'] ?? '').length > 2) {
      _fieldStates[1] = (invited['surname'] ?? '').length > 2;
      update = true;
    }
    if (_fieldStates[2] != emailRegex.hasMatch(invited['email'] ?? '')) {
      _fieldStates[2] = emailRegex.hasMatch(invited['email'] ?? '');
      update = true;
    }
    if (_fieldStates[3] != (invited['phone'] ?? '').length > 9) {
      _fieldStates[3] = (invited['phone'] ?? '').length > 9;
      update = true;
    }
    if (update) {
      setState(() => _isComplete = _fieldStates[0] &&
          _fieldStates[1] &&
          _fieldStates[2] &&
          _fieldStates[3]);
    }
    return _fieldStates[0] &&
        _fieldStates[1] &&
        _fieldStates[2] &&
        _fieldStates[3];
  }

  clearData() {
    _fieldStates = [false, false, false, false];
    invited = {};
    _controller1.clear();
    _controller2.clear();
    _controller3.clear();
    _controller4.clear();
    _fn1.requestFocus();
    _isComplete = false;
  }
}
