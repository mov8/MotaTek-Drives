import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';

class SignupForm extends StatefulWidget {
  final LoginState loginState;
  const SignupForm({super.key, context, this.loginState = LoginState.register});
  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  //int sound = 0;
  String email = 'james@eggxactly.com';
  String password = 'ohmy10';
  int manufacturer = 0;
  int model = 0;
  bool carData = false;
  bool userExists = false;
  String savedPassword = '';
  bool dataComplete = false;
  late Future<bool> _loadedOk;
  List<String> titles = [
    'Register as new user',
    'Update your details',
    'Reset your password'
  ];
  List<String> descriptions = [
    'You will be emailed a six digit validation code.\n Please check your emails (including spam folder).\n You can then complete your registration.',
    'Please update your details',
    'You will be emailed a six digit validation code.\n Please check your emails (including spam folder).'
  ];
  List<String> captions = ['Register', 'Update', 'Reset'];
  int mode = 0;
  bool hasChanged = false;
  bool complete = false;
  final Key _formKey = GlobalKey<FormState>();
  //final FocusNode _focusNode = FocusNode();

  final ButtonStyle style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      backgroundColor: Colors.blue,
      shadowColor: Colors.grey,
      elevation: 10,
      textStyle: const TextStyle(fontSize: 30, color: Colors.white));

  @override
  void initState() {
    super.initState;
    userExists =
        Setup().user.email.isNotEmpty && Setup().user.surname.isNotEmpty;
    savedPassword = Setup().user.password;
    // Setup().user.password = '';
    mode = (userExists && savedPassword.length > 7) || Setup().jwt.isNotEmpty
        ? 1
        : 0;
    debugPrint('mode: $mode');
    _loadedOk = checkUserData();
    complete = false;
    // WidgetsBinding.instance.addPostFrameCallback(
    //    (_) => FocusScope.of(context).requestFocus(_focusNode));
  }

  @override
  void dispose() {
    // _focusNode.dispose();
    super.dispose();
  }

  Future<bool> checkUserData() async {
    if (Setup().user.email.isNotEmpty && Setup().user.surname.isEmpty) {
      await getUserDetails(email: Setup().user.email);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: ScreensAppBar(
          heading: 'User details',
          prompt: 'Please update your details.',
          updateHeading: 'You have changed your details.',
          updateSubHeading: 'Press Update to confirm the changes or Ignore',
          update: hasChanged && isComplete(),
          updateMethod: () => register(),
        ),
        body: FutureBuilder<bool>(
          future: _loadedOk,
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Snapshot error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              // _building = false;
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
            throw ('Error - FutureBuilder in create_trips.dart');
          },
        ));
  }

  Widget portraitView() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Expanded(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          autofocus: true,
                          // focusNode: _focusNode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your forename',
                            labelText: 'Forename',
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          textAlign: TextAlign.left,
                          initialValue: Setup().user.forename.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (text) {
                            Setup().user.forename = text;
                            hasChanged = true;
                            if (isComplete() != complete) {
                              setState(() => complete = !complete);
                            }
                          },
                          // setState(() => Setup().user.forename = text),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your forename';
                            }
                            return null;
                          }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter surname',
                            labelText: 'Surname',
                          ),
                          textAlign: TextAlign.left,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          initialValue: Setup().user.surname.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (text) {
                            hasChanged = true;
                            Setup().user.surname = text;
                            if (isComplete() != complete) {
                              setState(() => complete = !complete);
                            }
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your surname';
                            }
                            return null;
                          }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextFormField(
                    readOnly:
                        mode != 0, //Only allow emails to be altered if new user
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your email address',
                      labelText: 'Email address',
                    ),
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.left,
                    initialValue: Setup().user.email.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) {
                      hasChanged = true;
                      Setup().user.email = text;
                      if (isComplete() != complete) {
                        setState(() => complete = !complete);
                      }
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your email address';
                      }
                      return null;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your phone number',
                      labelText: 'Phone number',
                    ),
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.left,
                    initialValue: Setup().user.phone.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) {
                      hasChanged = true;
                      Setup().user.phone = text;
                      if (isComplete() != complete) {
                        setState(() => complete = !complete);
                      }
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    }),
              ),
              if (mode == 0) ...[
                //(new User)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter your password',
                                  labelText: 'Password',
                                  //  errorText: 'Minimum of 8 characters',
                                  // error: false,
                                ),
                                textAlign: TextAlign.left,
                                //     minLength: 8,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                initialValue: Setup().user.password.toString(),
                                style: Theme.of(context).textTheme.bodyLarge,
                                validator: (val) =>
                                    Setup().user.newPassword.length < 8 &&
                                            isComplete()
                                        ? 'Minimum password length is 8'
                                        : null,
                                onChanged: (text) {
                                  hasChanged = true;
                                  Setup().user.newPassword = text;
                                  if (isComplete() != complete) {
                                    setState(() => complete = !complete);
                                  }
                                }),
                            SizedBox(height: 3),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                  isComplete()
                                      ? ' '
                                      : 'Minimum 8 caracters required',
                                  style: TextStyle(fontSize: 13),
                                  textAlign: TextAlign.end),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Validation code',
                            labelText: 'Emailed code',
                          ),
                          textAlign: TextAlign.left,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          initialValue: '',
                          style: Theme.of(context).textTheme.bodyLarge,
                          validator: (val) =>
                              Setup().user.password.length < 6 && isComplete()
                                  ? 'Six digits needed'
                                  : null,
                          onChanged: (text) {
                            hasChanged = true;
                            Setup().user.password = text;
                            if (isComplete() != complete) {
                              setState(() => complete = !complete);
                            }
                          },
                        ),
                      ),
                    ],
                    //    SizedBox(height: 15),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ActionChip(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onPressed: isComplete()
                              ? () async {
                                  String status = await register();
                                  if (status == 'Ok' && mounted) {
                                    Navigator.pop(context);
                                  } else {
                                    DialogOkCancel(
                                      id: 1,
                                      title: 'Error',
                                      body: status,
                                      onConfirm: (_) => (),
                                    );
                                  }
                                }
                              : null,
                          backgroundColor: Colors.blue,
                          disabledColor: Colors.grey,
                          avatar: Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                          label: Text('Register now',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: ActionChip(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onPressed: () => postValidateUser(user: Setup().user),
                          backgroundColor: Colors.blue,
                          avatar: Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                          label: Text('Resend code',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ], // mode == 0

              if (mode == 1) ...[
                //(Update user details)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '',
                          labelText: 'Current Password',
                        ),
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        initialValue: Setup().user.password.toString(),
                        onChanged: (text) => Setup().user.newPassword = text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        readOnly: false,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '',
                          labelText: 'New Password',
                        ),
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        initialValue: Setup().user.newPassword.toString(),
                        onChanged: (text) => Setup().user.newPassword = text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ]

                      //    SizedBox(height: 15),
                      ),
                ),
              ],
              if (carData) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Car Manufacturer',
                    ),
                    value: manufacturers[0],
                    items: manufacturers
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item,
                                style: Theme.of(context).textTheme.bodyLarge!),
                          ),
                        )
                        .toList(),
                    onChanged: (item) => setState(() =>
                        manufacturer = manufacturers.indexOf(item.toString())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Car Model',
                    ),
                    value: models[0],
                    items: models
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge!),
                            ))
                        .toList(),
                    onChanged: (item) =>
                        setState(() => model = models.indexOf(item.toString())),
                  ),
                )
              ],
              if (!isComplete())
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 0, 12),
                    child: Text('Please fill in ALL the boxes above:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
                  child: Text(descriptions[mode],
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isComplete() {
    return Setup().user.forename.isNotEmpty &&
        Setup().user.surname.isNotEmpty &&
        Setup().user.email.isNotEmpty &&
        Setup().user.phone.isNotEmpty &&
        ((Setup().user.password.length > 7 && savedPassword.isNotEmpty) ||
            (Setup().user.password.length == 6 && savedPassword.isEmpty));
  }

  Future<String> register() async {
    String response = 'Error';

    Map<String, dynamic> status =
        await postUser(user: Setup().user, register: true);

    switch (status['code']) {
      case 201:
        if (Setup().user.password.isNotEmpty &&
            Setup().user.newPassword.isNotEmpty) {
          Setup().user.password = Setup().user.newPassword;
          Setup().user.newPassword = '';
        }
        saveUser(Setup().user);
        Setup().setupToDb();
        response = 'Ok';
        break;

      case 400:
        response = 'Submitted data error - please check all boxes';
        break;

      case 401: // unauthorised
        response = 'Password is incorrect';
        break;

      case 404: // Not found
        response =
            'Validation code is incorrect - please check for latest email';
        break;

      default:
        response = 'Failed to save user - check Internet connection';
        break;
    }

    // Navigator.pop(context); 406 Notacceptable 409 conflict
    return response;
  }
}
