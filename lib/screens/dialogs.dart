import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:drives/constants.dart';
import 'package:drives/services/services.dart';
import 'package:drives/models/models.dart';
import 'package:drives/screens/screens.dart';

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

List<String> autoCompleteData = ['Dotty', 'James', 'Billy', 'Katie'];

AlertDialog buildFlexDialog(
    {required BuildContext context,
    required String title,
    required String content,
    required List<String> buttonTexts,
    List callbacks = const []}) {
  const textStyle = TextStyle(color: Colors.black);

  return AlertDialog(
    title: Text(title, style: textStyle),
    content: Text(content, style: textStyle),
    actions: actionButtons(context, callbacks, buttonTexts),
  );
}

List<TextButton> actionButtons(
    BuildContext context, List callbacks, List<String> buttonTexts) {
  List<TextButton> textButtons = [];
  for (int i = 0; i < buttonTexts.length; i++) {
    textButtons.add(TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16.0),
          backgroundColor: const Color.fromARGB(255, 204, 224, 241),
          textStyle: const TextStyle(fontSize: 30),
        ),
        child:
            Text(buttonTexts[i], style: Theme.of(context).textTheme.bodyLarge!),
        onPressed: () {
          if (callbacks.isNotEmpty && callbacks.length > i) {
            callbacks[i]();
          }
          Navigator.pop(context, buttonTexts[i]);
        }));
  }
  return textButtons;
}

class Utility {
  Utility._privateConstructor();
  static final _instance = Utility._privateConstructor();
  factory Utility() {
    return _instance;
  }

  showAlertDialog(
      BuildContext context, String alertTitle, String alertMessage) async {
    // bool result = false;
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Ok"),
      onPressed: () {
        Navigator.pop(context, true);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(alertTitle),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[Text(alertMessage)],
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // result = alert;

        return alert;
      },
    );
  }

  okCancelAlert({
    required BuildContext context,
    String title = 'Title',
    String message = 'Message',
  }) async {
    // Function(bool)? response}) async {
    AlertDialog alert = AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            "Ok",
            style: TextStyle(fontSize: 24),
          ),
          onPressed: () {
            // response!(true);
            Navigator.pop(context, true);
          },
        ),
        TextButton(
          child: const Text(
            "Cancel",
            style: TextStyle(fontSize: 24),
          ),
          onPressed: () {
            // response!(false);
            Navigator.pop(context, false);
          },
        )
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    ); //.then((_) => debugPrint('Response $response'));
  }

  showConfirmDialog(
      BuildContext context, String alertTitle, String alertMessage) {
    // set up the buttons
    Widget confirmButton = TextButton(
      child: const Text(
        "Ok",
        style: TextStyle(fontSize: 24),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        alertTitle,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              alertMessage,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
      actions: [
        confirmButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showOkCancelDialog(
      {required BuildContext context,
      required String alertTitle,
      required String alertMessage,
      required int okValue,
      required Function callback}) {
    // set up the buttons
    Widget okButton = TextButton(
      child: const Text(
        "Ok",
        style: TextStyle(fontSize: 24),
      ),
      onPressed: () {
        callback(okValue);
        Navigator.pop(context);
      },
    );
    Widget cancelButton = TextButton(
      child: const Text(
        "Cancel",
        style: TextStyle(fontSize: 24),
      ),
      onPressed: () {
        callback(-1);
        Navigator.pop(context);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        alertTitle,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              alertMessage,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
      actions: [
        okButton,
        cancelButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

AlertDialog buildColumnDialog(
    {required BuildContext context,
    required String title,
    required SizedBox content,
    required List<String> buttonTexts,
    List callbacks = const []}) {
  const textStyle = TextStyle(color: Colors.black);
  return AlertDialog(
      title: Text(title, style: textStyle),
      elevation: 5,
      content: content,
      actions: actionButtons(context, callbacks, buttonTexts));
}

/// LoginDialog(context, user) builds the login dialog:
///
///   The app silently logs in if it has stored the user name and password
///   using the user/login API endpoint
///   it will retrive a new JWT that it stores in Setup()
///
///   If the silent login fails then the dialog will be shown
///
///   A) If the app has neither email nor password then the dialog
///   will be shown because either -
///     1 It's a new user so they have to register as such
///       i)   They enter just their email (stored locally).
///       ii)  The API then emails them a 6 digit code.
///       iii) The dialog changes to waiting for code
///
///     2 It's an existing user on a new device
///
///   If the password is left empty is (new user or forgotten pw) the
///   user/register endpoint will email the user with a 6 digit code
///
///   B) If the app knows the email but the password is empty it allows
///   the user to enter the 6 digit emailed digit code which it stores locally
///
///   C) If the user has forgotten their password then the password is
///   removed locally triggering the sending of an email with the register code
///
///   D) If the correct 6 digit code is entered it is stored and the
///   local password and the SignUpForm class will be invoked to complete
///   the reistration.
///

Future<void> loginDialog(BuildContext context, {required User user}) async {
  String status = '';
  int joiningOffset = user.password.isEmpty && user.email.isNotEmpty ? 2 : 0;

  // debugPrint('joiningOffset is $joiningOffset');

  user.password = '';
  int selectedRadio = 0;
  List<String> rltTitles = [
    'Login ',
    'Register as new user',
    'Enter code now',
    'Resend email'
  ];
  List<String> titles = [
    'Login ',
    'Register',
    'Validate registration',
    'Resend code email'
  ];

  List<IconData> dialogIcons = [
    Icons.key,
    Icons.person_add,
    Icons.how_to_reg,
    Icons.send
  ];

  switch (await showDialog<LoginState>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, StateSetter setState) => AlertDialog(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            dialogIcons[selectedRadio + joiningOffset],
            //    joinId.isEmpty ? selectedRadio == 0 ? Icons.key : Icons.person_add : ,
            size: 30,
          ),
          const SizedBox(
            width: 10,
          ),
          Text(titles[selectedRadio + joiningOffset]),
        ]),
        content: SizedBox(
          height: selectedRadio == 0 ? 210 : 160,
          width: 350,
          child: Column(children: [
            if (joiningOffset == 0 || (selectedRadio == 1)) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          hintText: 'Enter your email address'),
                      onChanged: (value) => user.email = value,
                    ),
                  )
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('')),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'emailed code',
                          hintStyle: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.normal)),
                      onChanged: (value) => user.password = value,
                    ),
                  ),
                  const Expanded(flex: 3, child: Text('')),
                ],
              ),
            ],
            if (selectedRadio + joiningOffset == 0) ...[
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Password - leave empty if fogotten',
                    ),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) => user.password = value,
                    onSubmitted: (_) async {
                      LoginState liState = LoginState.cancel;
                      if (user.email.isNotEmpty) {
                        try {
                          liState = user.password.isEmpty
                              ? LoginState.register
                              : LoginState.login;
                          if (context.mounted) {
                            Navigator.pop(context, liState);
                          }
                        } catch (e) {
                          String err = e.toString();
                          debugPrint('Error: $err');
                        }
                      }
                    },
                  ))
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.normal),
                  ),
                )
              ],
            ),
            // if (joiningOffset == 0)
            Row(
              children: List.generate(
                2,
                (index) => Expanded(
                  flex: index, // == 2 ? 6 : 4,
                  child: Row(
                    children: [
                      Text(rltTitles[joiningOffset + index]),
                      if (index < 3)
                        Radio(
                          value: index,
                          groupValue: selectedRadio,
                          onChanged: (val) => //selectedRadio = val!,
                              setState(() => selectedRadio = val!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              LoginState liState = LoginState.cancel;
              if (user.email.isNotEmpty) {
                try {
                  liState = user.password.isEmpty
                      ? LoginState.register
                      : LoginState.login;
                  if (context.mounted) {
                    Navigator.pop(context, liState);
                  }
                } catch (e) {
                  String err = e.toString();
                  debugPrint('Error: $err');
                }
              }
            },
            child: const Text(
              'Ok',
              style: TextStyle(fontSize: 20),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, LoginState.cancel),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    ),
  )) {
    case LoginState.register:
      if (user.surname.isEmpty || user.forename.isEmpty) {
        await getUserDetails(email: user.email);
      }
      postValidateUser(user: Setup().user);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignupForm()),
      );
      break;
    case LoginState.login:
      if (user.surname.isEmpty || user.forename.isEmpty) {
        await getUserDetails(email: user.email);
      }
      Setup().user.password = user.password;
      tryLogin(user: user);
      saveUser(Setup().user);
      debugPrint('Logged in');
      break;
    default:
      debugPrint('Cancel');
      break;
  }

  // return result;
}

class DialogOkCancel extends StatefulWidget {
  @override
  State<DialogOkCancel> createState() => _DialogOkCancelState();

  final Function(int value) onConfirm;
  final int id;
  final String title;
  final String body;

  const DialogOkCancel({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    required this.onConfirm,
  });
}

class _DialogOkCancelState extends State<DialogOkCancel> {
  int value = -1;
  TextStyle textStyle = const TextStyle(color: Colors.black);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //  context: context,
      //  barrierDismissible: false,
      title: Column(children: [
        Row(children: [
          Text(widget.title,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Row(children: [
            Text(widget.body,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                )),
          ]),
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: SizedBox(
                  height: 20,
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(widget.id);
                      Navigator.pop(context);
                    },
                    child: const Text('OK')),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(-1);
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
              )
            ],
          )
        ]),
      ]),
    );
  }
}

Future<LatLng> locationDialog(BuildContext context, Function callback) async {
  String waypoint = '';
  LatLng location = const LatLng(0.00, 0.00);
  await showDialog(
      context: context,
      // builder: (context) => StatefulBuilder(
      barrierDismissible: false,
      builder: (context) =>
          StatefulBuilder(builder: (BuildContext context, setState) {
            return buildColumnDialog(
                context: context,
                title: 'Location Search',
                content: SizedBox(
                    height: 100,
                    width: 300,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                          const Text('Enter location name:'),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Autocomplete(
                                    optionsBuilder: (TextEditingValue
                                        textEditingValue) async {
                                      autoCompleteData = await getSuggestions(
                                          textEditingValue.text);
                                      setState(() {
                                        waypoint = textEditingValue.text;
                                      });
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<String>.empty();
                                      } else {
                                        return autoCompleteData.where((word) =>
                                            word.toLowerCase().contains(
                                                textEditingValue.text
                                                    .toLowerCase()));
                                      }
                                    },
                                    fieldViewBuilder: (context, controller,
                                        focusNode, onEditingComplete) {
                                      return TextFormField(
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          controller: controller,
                                          focusNode: focusNode,
                                          onEditingComplete: onEditingComplete,
                                          decoration: const InputDecoration(
                                              hintText: 'Waypoint'));
                                    },
                                    onSelected: (String selection) {
                                      // waypoints[i] = selection;
                                      debugPrint(
                                          'You just selected $selection');
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          )
                        ]))),
                buttonTexts: [
                  'OK',
                  'CANCEL',
                ],
                callbacks: [
                  () async {
                    await callback(waypoint).then((result) {
                      if (result != null) {
                        location = result;
                        return location;
                      }
                    });
                  },
                ]);
          })).then((result) {
    //  debugPrint('Result from dialog: ${result.toString()}');
    if (result != null && result != "OK" && result != "CANCEL") {
      location = result;
//      debugPrint('Location after callback: ${location.toString()}');
    }
  });
  return location;
}

Future<List<Polyline>> routeDialog(
    BuildContext context, int points, Function callback) async {
  List<TextEditingController> controllers = [];
  List<String> waypoints = [];
  // List<LatLng> routePoints = [LatLng(52.05884, -1.345583)];
  List<Polyline> polylines = [
    Polyline(
        points: const [LatLng(52.05884, -1.345583)], // routePoints,
        color: const Color.fromARGB(255, 28, 97, 5),
        strokeWidth: 5)
  ];

  for (int i = 0; i < points; i++) {
    controllers.add(TextEditingController());
    waypoints.add('');
  }

  // User user = User(forename: '', surname: '', email: '', password: '');

  await showDialog(
      context: context,
      // builder: (context) => StatefulBuilder(
      barrierDismissible: false,
      builder: (context) =>
          StatefulBuilder(builder: (BuildContext context, setState) {
            return buildColumnDialog(
                context: context,
                title: 'Trip Details',
                content: SizedBox(
                    height: 200,
                    width: 300,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                          const Text('Enter trip waypoints:'),
                          for (int i = 0; i < waypoints.length; i++) ...[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    child: Autocomplete(
                                      optionsBuilder: (TextEditingValue
                                          textEditingValue) async {
                                        autoCompleteData = await getSuggestions(
                                            textEditingValue.text);
                                        setState(() {
                                          waypoints[i] = textEditingValue.text;
                                        });
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<String>.empty();
                                        } else {
                                          return autoCompleteData.where(
                                              (word) => word
                                                  .toLowerCase()
                                                  .contains(textEditingValue
                                                      .text
                                                      .toLowerCase()));
                                        }
                                      },
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onEditingComplete) {
                                        return TextFormField(
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            controller: controller,
                                            focusNode: focusNode,
                                            onEditingComplete:
                                                onEditingComplete,
                                            decoration: InputDecoration(
                                                hintText: 'Waypoint ${i + 1}'));
                                      },
                                      onSelected: (String selection) {
                                        waypoints[i] = selection;
                                        debugPrint(
                                            'You just selected $selection');
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _addRemoveWaypoint(
                                    context, setState, i, waypoints),
                              ],
                            )
                          ]
                        ]))),
                buttonTexts: [
                  'OK',
                  'CANCEL',
                ],
                callbacks: [
                  () async {
                    await callback(waypoints).then((result) {
                      if (result != null) {
                        polylines = result;
                        //     debugPrint('polylines.length = ${polylines.length}');
                      }
                    });
                  },
                ]);
          })).then((result) => {
        if (result != null && result != "OK" && result != "CANCEL")
          {
            polylines = result,
          }
      });

  return polylines;
}

Widget _addRemoveWaypoint(
    BuildContext context, setState, index, var waypoints) {
  // Using var allows parameter to be accessed by reference
  return InkWell(
      onTap: () {
        if (index == waypoints.length - 1) {
          waypoints.add('');
        } else {
          waypoints.removeAt(index);
        }
        setState(() {});
      },
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: index == waypoints.length - 1 ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            index == waypoints.length - 1 ? Icons.add : Icons.remove,
            color: Colors.white,
          )));
}

class _AsyncAutocomplete extends StatefulWidget {
  const _AsyncAutocomplete();

  @override
  State<_AsyncAutocomplete> createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<_AsyncAutocomplete> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<String> _lastOptions = <String>[];

  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    final Iterable<String> options = await _FakeAPI.search(_currentQuery!);

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<String>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}

class OkCancelAlert extends StatefulWidget {
  final String title;
  final String message;
  const OkCancelAlert({
    super.key,
    this.title = '',
    this.message = '',
  });
  @override
  State<OkCancelAlert> createState() => _OkCancelAtertState();
}

class _OkCancelAtertState extends State<OkCancelAlert> {
  double value = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              widget.message,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            "Ok",
            style: TextStyle(fontSize: 24),
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        TextButton(
          child: const Text(
            "Cancel",
            style: TextStyle(fontSize: 24),
          ),
          onPressed: () {
            Navigator.pop(context, false);
          },
        )
      ],
    );
  }
}

// Mimics a remote API.
class _FakeAPI {
  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  // Searches the options, but injects a fake "network" delay.
  static Future<Iterable<String>> search(String query) async {
    await Future<void>.delayed(fakeAPIDuration); // Fake 1 second delay.
    if (query == '') {
      return const Iterable<String>.empty();
    }
    return _kOptions.where((String option) {
      return option.contains(query.toLowerCase());
    });
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

//  [LatLng(52.05884, -1.345583)]
