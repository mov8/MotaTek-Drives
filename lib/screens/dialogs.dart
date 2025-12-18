import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '/constants.dart';
import '/services/services.dart';
import '/helpers/edit_helpers.dart';
import '/models/models.dart';
import '/classes/classes.dart';
import '/tiles/tiles.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
//import '/screens/screens.dart';

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
            //  backgroundColor: const Color.fromARGB(255, 204, 224, 241),
            textStyle: labelStyle(
                context: context,
                color: Colors.deepPurple,
                size: 3) //const TextStyle(fontSize: 30),
            ),
        child: Text(buttonTexts[i],
            style: titleStyle(
                context: context, color: Colors.deepPurple, size: 2)),
        onPressed: () {
          if (callbacks.isNotEmpty && callbacks.length > i) {
            callbacks[i]();
          }
          Navigator.pop(context, buttonTexts[i]);
        }));
  }
  return textButtons;
}

pointOfInterestDialog(
    BuildContext context,
    String name,
    String description,
    String images,
    String url,
    List<String> imageUrls,
    double score,
    int scored,
    int type) async {
  Widget okButton = TextButton(
    child: const Text("Ok"),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(
      name.isEmpty ? 'Waypoint' : name,
      style: headlineStyle(context: context, size: 2, color: Colors.black),
      textAlign: TextAlign.center,
    ),
    elevation: 5,
    content: MarkerTile(
      index: -1,
      name: name,
      description: description,
      images: images,
      url: url,
      imageUrls: imageUrls,
      type: type,
      score: score,
      scored: scored,
      onRated: () => {},
      canEdit: false,
      expanded: false,
    ),
    actions: [
      okButton,
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

osmDataDialog(
    BuildContext context,
    String name,
    String amenity,
    String postcode,
    int iconCodepoint,
    String osmId,
    ImageRepository imageRepository,
    List<dynamic> reviews) async {
  Map<String, dynamic> reviewData = {};
  AlertDialog alert = AlertDialog(
    title: Text(
      name,
      style: textStyle(context: context, color: Colors.black, size: 2),
      textAlign: TextAlign.center,
    ),
    scrollable: true,
    elevation: 5,
    content: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return SizedBox(
          height: 600,
          child: OsmReviewTile(
              index: 1,
              imageRepository: imageRepository,
              name: name,
              amenity: amenity,
              postcode: postcode,
              iconCodepoint: iconCodepoint,
              reviewData: reviewData,
              reviews: reviews),
        );
      },
    ),
    actions: [
      TextButton(
        child: const Text(
          "Ok",
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () {
          postWithPhotos(
            url: '$urlOsmReview/add',
            fields: {
              'amenity': amenity,
              'osm_data_id': osmId,
              'comment': reviewData['comment'] ?? '',
              'images': reviewData['imageUrls'] ?? '',
              'rated': dateFormatSQL.format(DateTime.now()),
              'rating': reviewData['rating'] ?? 5.0
            },
            photos: photosFromJson(photoString: reviewData['imageUrls'] ?? ''),
          );
          Navigator.pop(context, true);
        },
      ),
      TextButton(
        child: const Text(
          "Cancel",
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () => Navigator.pop(context, false),
      ),
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

AlertDialog followerDialog({
  required BuildContext context,
  required sio.Socket socket,
  String forename = '',
  String surname = '',
  String phoneNumber = '',
  String manufacturer = '',
  String model = '',
  String colour = '',
  String registration = '',
}) {
  // set up the AlertDialog
  return AlertDialog(
    title: Text(
      '$forename $surname',
      style: headlineStyle(context: context, color: Colors.black, size: 2),
      textAlign: TextAlign.center,
    ),
    elevation: 5,
    content: FollowerMarkerTile(
        index: -1,
        context: context,
        manufacturer: manufacturer,
        model: model,
        colour: colour,
        registration: registration),
    actions: [
      TextButton(
        child: const Text("Contact", style: TextStyle(fontSize: 22)),
        onPressed: () {
          Navigator.pop(context, true);
        },
      ),
      TextButton(
        child: const Text("Dismiss", style: TextStyle(fontSize: 22)),
        onPressed: () {
          Navigator.pop(context, false);
        },
      )
    ],
  );
}

AlertDialog contactDiolog({
  required BuildContext context,
  //  Follower? follower,
  Map<String, String>? follower,
  required sio.Socket socket,
}) {
  String message = contactChoices[0];
  return AlertDialog(
    title: follower != null
        ? Text('Message ${follower["forename"]} ${follower["surname"]}',
            style:
                headlineStyle(context: context, color: Colors.black, size: 1))
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Broadcast Message',
              style:
                  headlineStyle(context: context, color: Colors.black, size: 2),
            ),
          ),
    content: SizedBox(
      width: 200,
      height: 150,
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    style: textStyle(
                        context: context, color: Colors.black, size: 2),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Saved Messages',
                    ),
                    initialValue: contactChoices[0],
                    items: contactChoices
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: textStyle(
                                  context: context,
                                  size: 2,
                                  color: Colors.black),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (item) => message = item!),
              ),
            ),
          ]),
          if (follower != null) ...[
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await FlutterPhoneDirectCaller.callNumber(
                        follower["phoneNumber"] ?? '');
                  },
                  child: Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone),
                          const SizedBox(width: 8),
                          Text(
                            'Call ${follower["phoneNumber"] ?? ""}',
                            style: textStyle(
                                context: context, color: Colors.black, size: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.all(10),
                //  child: SingleChildScrollView(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        autofocus: true,
                        minLines: 1,
                        maxLines: 2,
                        style: textStyle(
                            context: context, color: Colors.black, size: 2),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter group message',
                          hintStyle: hintStyle(context: context),
                        ),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) => message = value,
                      ),
                    ),
                  ],
                ),
                //    ),
              ),
            ),
          ]
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        child: const Text('Chat', style: TextStyle(fontSize: 22)),
        onPressed: () {
          socket.emit('trip_message', {'message': message});
          Navigator.pop(context, message);
        },
      ),
      TextButton(
        child: const Text('Send', style: TextStyle(fontSize: 22)),
        onPressed: () {
          socket.emit('trip_message', {'message': message});
          Navigator.pop(context, message);
        },
      ),
      TextButton(
        child: const Text('Close', style: TextStyle(fontSize: 22)),
        onPressed: () {
          Navigator.pop(context, '');
        },
      ),
    ],
  );
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
              style: textStyle(context: context, size: 2, color: Colors.black),
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
        style: headlineStyle(context: context, size: 1, color: Colors.black),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              alertMessage,
              style: textStyle(context: context, size: 2, color: Colors.black),
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

Future<LoginState> loginDialog(BuildContext context,
    {required User user}) async {
  // String status = '';
  List<String> registered = [];
//  LoginError loginError = LoginError.noData;
//  bool isRegistered = false;
  final FocusNode focusNode = FocusNode();
  TextEditingController controller = TextEditingController();
  user.password = '';
  List<dynamic> statusPrompts = [
    {'hint': '', 'button': '', 'error': false}, // noData
    {'hint': 'email missing', 'button': '', 'error': true}, // noEmail
    {'hint': 'email invalid', 'button': '', 'error': false}, // emailInvalid
    {
      'hint': 'email not registered',
      'button': 'Register',
      'error': false
    }, // emailUnknown
    {
      'hint': 'leave empty to reset password',
      'button': 'Reset',
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
      'button': '',
      'error': false
    }, // passwordTooShort
  ];

  LoginStatus loginStatus = LoginStatus.noData;

  LoginState? loginState = await showDialog<LoginState>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (context, StateSetter setState) => AlertDialog(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.key,
            size: 30,
          ),
          const SizedBox(
            width: 10,
          ),
          Text('Login',
              style: textStyle(context: context, color: Colors.black, size: 1)),
        ]),
        content: SizedBox(
          height: 160,
          width: 350,
          child: Column(children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    inputFormatters: [
                      LowerCaseTextFormatter(),
                    ],
                    decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: hintStyle(context: context)),
                    style: textStyle(
                        context: context, color: Colors.black, size: 3),
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
                            found =
                                found ? found : email.startsWith(user.email);
                          }
                          if (!found) {
                            registered.clear();
                          }
                        }
                      }
                      if (emailRegex.hasMatch(user.email) && found) {
                        setState(() => loginStatus = LoginStatus.emailKnown);
                        focusNode.requestFocus();
                      }
                    },
                    onSubmitted: (text) async {
                      text = text.toLowerCase();
                      controller.text = text.toLowerCase();
                      debugPrint('Submitted $text');
                      if (loginStatus == LoginStatus.emailKnown) {
                        loginStatus = LoginStatus.noPassword;
                        setState(() => focusNode.requestFocus());
                      } else if (emailRegex.hasMatch(user.email)) {
                        setState(() => loginStatus = LoginStatus.emailUnknown);
                      } else {
                        setState(() => loginStatus = LoginStatus.emailInvalid);
                      }
                    },
                  ),
                )
              ],
            ),

            /// Password only entered if email is known
            if ([
              LoginStatus.emailKnown,
              LoginStatus.passwordUnknown,
              LoginStatus.passwordValid,
              LoginStatus.passwordTooShort
            ].contains(loginStatus))
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        decoration: InputDecoration(
                          hintText: 'enter password - at least 8 characters',
                          hintStyle: hintStyle(context: context),
                        ),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        focusNode: focusNode,
                        style: textStyle(context: context, color: Colors.black),
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
                              focusNode.dispose();
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

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusPrompts[loginStatus.index]['hint'],
                    style: textStyle(
                      context: context,
                      size: 3,
                      color: statusPrompts[loginStatus.index]['error']
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                )
              ],
            ),
            // if (joiningOffset == 0)
          ]),
        ),
        actions: [
          if (statusPrompts[loginStatus.index]['button'].isNotEmpty)
            TextButton(
              onPressed: () async {
                if (loginStatus == LoginStatus.emailUnknown) {
                  Setup().user = user;
                  Navigator.pop(context, LoginState.register);
                } else if ((user.password.isEmpty ||
                    loginStatus == LoginStatus.passwordUnknown)) {
                  Setup().user = user;
                  focusNode.dispose();
                  Navigator.pop(context, LoginState.resetPassword);
                } else {
                  Map<String, dynamic> response =
                      await tryLogin(user: Setup().user);
                  String status = response['msg'] ?? '';
                  if (context.mounted && status == 'OK') {
                    Setup().user = user;
                    focusNode.dispose();
                    Navigator.pop(context, LoginState.login);
                  }
                  if ([204, 401].contains(response["response_status_code"])) {
                    loginStatus = LoginStatus.passwordUnknown;
                    setState(() => loginStatus == LoginStatus.passwordUnknown);
                  }
                }
              },
              child: Text(
                statusPrompts[loginStatus.index]['button'],
                style: TextStyle(fontSize: 20),
              ),
            ),
          TextButton(
            onPressed: () {
              focusNode.dispose();
              Navigator.pop(context, LoginState.cancel);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    ),
  );
  return loginState ?? LoginState.cancel;
}

class DriverDetails {
  BuildContext context;
  LatLng position;
  sio.Socket socket;
  String groupDriveId;
  DriverDetails(
      {required this.context,
      required this.groupDriveId,
      required this.position,
      required this.socket});
  Future<String> getDetails(Follower driver) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        //  Map<String, dynamic> carData = {};
        return AlertDialog(
          title: Text('Drive - ${driver.driveName}'),
          titlePadding: EdgeInsets.fromLTRB(30, 30, 0, 0),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            initialValue: driver.manufacturer,
                            decoration: InputDecoration(
                              label: Text('Vehicle manufacturer'),
                              labelStyle: labelStyle(
                                  context: context, color: Colors.deepPurple),
                              border: OutlineInputBorder(),
                              hintText: 'Manufacturer',
                              hintStyle: hintStyle(context: context),
                            ),
                            style: textStyle(
                                context: context, color: Colors.black),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.manufacturer = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: driver.model,
                            decoration: InputDecoration(
                              label: Text('Vehicle model'),
                              labelStyle: labelStyle(context: context),
                              border: OutlineInputBorder(),
                              hintText: 'Model',
                              hintStyle: hintStyle(context: context),
                            ),
                            style: textStyle(
                                context: context, color: Colors.black),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.model = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.carColour,
                            decoration: InputDecoration(
                              label: Text('Colour'),
                              labelStyle: labelStyle(context: context),
                              border: OutlineInputBorder(),
                              hintText: 'Colour',
                              hintStyle: hintStyle(context: context),
                            ),
                            style: textStyle(
                                context: context, color: Colors.black),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.carColour = value,
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.registration,
                            decoration: InputDecoration(
                                label: Text('Registration'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Reg No',
                                hintStyle: hintStyle(context: context)),
                            style: textStyle(
                                context: context, color: Colors.black),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.registration = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: driver.phoneNumber,
                            decoration: InputDecoration(
                                label: Text('Mobile'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Mobile phone number',
                                hintStyle: hintStyle(context: context)),
                            style: textStyle(
                                context: context, color: Colors.black),
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => driver.phoneNumber = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok', style: TextStyle(fontSize: 22)),
              onPressed: () async {
                driver.position = position;
                await sendDriverDetails(driver);
                if (!socket.connected) {
                  socket.connect();
                }
                if (socket.connected) {
                  socket.emit('trip_join', {
                    'token': Setup().jwt,
                    'trip': groupDriveId,
                    'message': '',
                    'make': driver.manufacturer,
                    'model': driver.model,
                    'colour': driver.carColour,
                    'reg': driver.registration,
                    'phone': driver.phoneNumber,
                    'lat': position.latitude,
                    'lng': position.longitude,
                  });
                } else {
                  debugPrint('Socket not connected');
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(fontSize: 22)),
              onPressed: () {
                Navigator.pop(context, '');
              },
            ),
          ],
        );
      },
    );
    return '';
  }
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
                                        decoration: InputDecoration(
                                          hintText: 'Waypoint',
                                          hintStyle:
                                              hintStyle(context: context),
                                        ),
                                        style: textStyle(
                                            context: context,
                                            color: Colors.black),
                                      );
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
                                          onEditingComplete: onEditingComplete,
                                          decoration: InputDecoration(
                                            hintText: 'Waypoint ${i + 1}',
                                            helperStyle:
                                                hintStyle(context: context),
                                          ),
                                          style: textStyle(
                                              context: context,
                                              color: Colors.black),
                                        );
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
