import 'dart:convert';
import 'dart:developer' as developer;
import '/classes/autocomplete_widget.dart';
import '/models/models.dart';
import 'package:flutter/material.dart';
import '/services/services.dart';
import '/services/web_helper.dart';
import '/models/models.dart';
import '/constants.dart';
import '/helpers/helpers.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen();
  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  List<String> registered = [];
//  LoginError loginError = LoginError.noData;
//  bool isRegistered = false;
  final FocusNode emFocusNode = FocusNode();
  final FocusNode pwFocusNode = FocusNode();
  final FocusNode fnFocusNode = FocusNode();
  final FocusNode snFocusNode = FocusNode();
  TextEditingController controllerEm = TextEditingController();
  TextEditingController controllerPw = TextEditingController();
  TextEditingController controllerFn = TextEditingController();
  TextEditingController controllerSn = TextEditingController();
  LoginStatus loginStatus = LoginStatus.noData;
  bool _seePassword = false;

  @override
  void initState() {
    super.initState();
    emFocusNode.requestFocus();
  }

  List<dynamic> statusPrompts = [
    {'hint': '', 'button': 'Cancel', 'error': false}, // noData
    {'hint': 'email missing', 'button': 'Cancel', 'error': true}, // noEmail
    {
      'hint': 'email invalid',
      'button': 'Cancel',
      'error': false
    }, // emailInvalid
    {
      'hint': 'email not registered',
      'button': 'Register',
      'error': false
    }, // emailUnknown
    {
      'hint': 'leave empty to reset password',
      'button': 'Reset Password',
      'error': false,
    }, // emailKnown
    {'hint': 'enter password', 'button': '', 'error': false}, // noPassword
    {'hint': '', 'button': 'Login', 'error': false}, // validPassword
    {
      'hint': 'incorrect password',
      'button': 'Reset Password',
      'error': true
    }, // passwordUnknown
    {
      'hint': 'must be longer than 7 characters',
      'button': 'Cancel',
      'error': false
    }, // passwordTooShort
  ];
  User user = Setup().user;

  @override
  Widget build(BuildContext context) {
    controllerEm.text = user.email;
    controllerPw.text = user.password;
    controllerFn.text = user.forename;
    controllerSn.text = user.surname;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Cheddar_Gorge.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4), // // Light shadow top
                    Colors.black.withValues(alpha: 0.6), // Dark contrast bottom
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 20, 10, 50),
                  child: Center(
                    child: Text('Login to Drives',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            overflow: TextOverflow.ellipsis),
                        maxLength: 100,
                        controller: controllerEm,
                        focusNode: emFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textCapitalization: TextCapitalization.none,
                        inputFormatters: [
                          LowerCaseTextFormatter(),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          label: Text.rich(
                            TextSpan(
                              text: '* ',
                              style: TextStyle(fontSize: 32, color: Colors.red),
                              children: [
                                TextSpan(
                                  text: 'email address',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          //  hintText: 'Enter your email address',
                          hintStyle:
                              TextStyle(fontSize: 18, color: Colors.blue),
                        ),
                        onChanged: (value) async {
                          user.email = value.toLowerCase();

                          /// Clear error message if correcting email
                          if (loginStatus != LoginStatus.noData) {
                            setState(() => loginStatus = LoginStatus.noData);
                          }

                          /// If a possible email then get a list of all emails matching the
                          /// data entered so far
                          bool found = false;
                          if (user.email.contains('.') &&
                              user.email.contains('@')) {
                            if (registered.isEmpty) {
                              registered = await getApiOptions(
                                  value: user.email, secure: false);
                              found = registered.length == 1;
                            } else {
                              found = false;
                              for (String email in registered) {
                                found = found
                                    ? found
                                    : email.startsWith(user.email);
                              }
                              if (!found) {
                                registered.clear();
                              }
                            }
                          }
                          if (emailRegex.hasMatch(user.email) && found) {
                            controllerEm.text = registered.first;
                            user.email = registered.first;
                            user.password = '';
                            controllerPw.clear();
                            loginStatus = LoginStatus.emailKnown;
                            setState(() => pwFocusNode.requestFocus());
                          }
                        },
                        onSubmitted: (text) async {
                          text = text.toLowerCase();
                          controllerEm.text = text.toLowerCase();
                          if (loginStatus == LoginStatus.emailKnown) {
                            loginStatus = LoginStatus.noPassword;
                            setState(() => pwFocusNode.requestFocus());
                          } else if (emailRegex.hasMatch(user.email)) {
                            setState(
                                () => loginStatus = LoginStatus.emailUnknown);
                          } else {
                            setState(
                                () => loginStatus = LoginStatus.emailInvalid);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          obscureText: !_seePassword,
                          obscuringCharacter: '\u25CF', // <- bold bullet
                          cursorHeight: 20,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            floatingLabelAlignment:
                                FloatingLabelAlignment.start,
                            label: Padding(
                              padding: EdgeInsetsGeometry.fromLTRB(2, 5, 0, 0),
                              child: Text.rich(
                                TextSpan(
                                  text: '* ',
                                  style: TextStyle(
                                      fontSize: 32, color: Colors.red),
                                  children: [
                                    TextSpan(
                                      text: 'password - 8 characters or more',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(), // Removes 48x48 min touch target
                              icon: Icon(
                                _seePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20, // Standard readable icon size
                              ),
                              onPressed: () {
                                setState(() {
                                  _seePassword = !_seePassword;
                                });
                              },
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.visiblePassword,
                          autofillHints: const [AutofillHints.password],
                          focusNode: pwFocusNode,
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.black,
                              letterSpacing: _seePassword ? 2 : 0),
                          onChanged: (value) => setState(() {
                                if (value.length < 8) {
                                  loginStatus = LoginStatus.passwordTooShort;
                                } else {
                                  loginStatus = LoginStatus.passwordValid;
                                }
                                user.password = value;
                              }),
                          onSubmitted: (_) async {
                            if (user.password.length < 8) {
                              setState(() =>
                                  loginStatus = LoginStatus.passwordTooShort);
                            } else {
                              Map<String, dynamic> response =
                                  await tryLogin(user: Setup().user);
                              String status = response['msg'] ?? '';
                              if (context.mounted && status == 'OK') {
                                Setup().user = user;
                                setState(() => fnFocusNode.requestFocus());

                                /// If the user has logged in correctly then the api will contain the
                                /// user's details.
                                /// The Mobile version will store the user details in SQLite
                                /// The Web version will only save the JWT but will have to retrieve the
                                /// setup Json Object from the api that contains full user details and colours etc
                                Setup().saveUser();
                                Navigator.pop(context, LoginState.login);
                              } else {
                                setState(() =>
                                    loginStatus = LoginStatus.passwordUnknown);
                              }
                            }
                          }),
                    )
                  ],
                ),

                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusPrompts[loginStatus.index]['hint'],
                        style: textStyle(
                          context: context,
                          size: 2,
                          color: statusPrompts[loginStatus.index]['error']
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
                //   SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 15, 5, 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            label: Text('forename',
                                style: TextStyle(
                                    fontSize: 22, color: Colors.blue)),
                            //   hintStyle: hintStyle(context: context),
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          keyboardType: TextInputType.name,
                          focusNode: fnFocusNode,
                          style: textStyle(
                              context: context, color: Colors.black, size: 3),
                          onChanged: (value) => setState(() {
                            user.forename = value;
                          }),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 8,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            label: Text('surname',
                                style: TextStyle(
                                    fontSize: 22, color: Colors.blue)),
                          ),
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          keyboardType: TextInputType.name,
                          focusNode: snFocusNode,
                          style: textStyle(
                              context: context, color: Colors.black, size: 3),
                          onChanged: (value) => setState(
                            () {
                              user.surname = value;
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(0, 5, 0, 0),
                  child: Center(
                    child: ActionChip(
                      onPressed: () async {
                        if (statusPrompts[loginStatus.index]['button'] ==
                            'Cancel') {
                          context.pop();
                        }
                        if (loginStatus == LoginStatus.emailUnknown) {
                          Setup().user = user;
                          context.pop();
                        } else if ((user.password.isEmpty ||
                            loginStatus == LoginStatus.passwordUnknown)) {
                          Setup().user = user;
                          context.pop();
                        } else {
                          Map<String, dynamic> response =
                              await tryLogin(user: Setup().user);
                          String status = response['msg'] ?? '';
                          if (context.mounted && status == 'OK') {
                            Setup().user = user;
                            Setup().saveUser();
                            Navigator.pop(context, LoginState.login);
                          }
                          if ([204, 401]
                              .contains(response["response_status_code"])) {
                            loginStatus = LoginStatus.passwordUnknown;
                            setState(() =>
                                loginStatus == LoginStatus.passwordUnknown);
                          }
                        }
                      },
                      backgroundColor: Colors.blue,
                      label: Text(
                        statusPrompts[loginStatus.index]['button'],
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ),
                  ),
                )
                // if (joiningOffset == 0)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
