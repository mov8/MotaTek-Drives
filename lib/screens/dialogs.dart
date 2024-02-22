import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// import 'package:flutter/widgets.dart';

///
/// https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter
///
/// buildFlexDialog negates the need of a lot of boilerplate. The buttons are passed as List<String> and they determine the
/// number of buttons and onPressed actions. The callbacks is an otional List. Without a callback the choice can be
/// found through showDialog(... ).then((var){do something with var});
/// eg.
///   showDialog(
///         context: context,
///         builder: (BuildContext context) {
///                     return buildFlexDialog(context: context, title:'Darkness', content: 'Change the apps brightness',
///                     buttonTexts: ['OK', 'CANCEL'], callbacks: [(){toggleBrightness();}]);
///                  }
///            ).then((selected){
///                      debugPrint('Selected ${selected.toString()}');
///            }) ;
///
///
/// buttonTexts: ['OK', 'CANCEL']
/// List functions = [(){toggleBrightness();}];
///

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

class LoadingIndicatorDialog {
  static final LoadingIndicatorDialog _singleton =
      LoadingIndicatorDialog._internal();
  late BuildContext _context;
  bool isDisplayed = false;

  factory LoadingIndicatorDialog() {
    return _singleton;
  }

  LoadingIndicatorDialog._internal();

  show(BuildContext context, {String text = 'Loading...'}) {
    if (isDisplayed) {
      return;
    }
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          _context = context;
          isDisplayed = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: SimpleDialog(
              backgroundColor: Colors.white,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(text),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  dismiss() {
    if (isDisplayed) {
      Navigator.of(_context).pop();
      isDisplayed = false;
    }
  }
}

class Utility {
  Utility._privateConstructor();
  static final _instance = Utility._privateConstructor();
  factory Utility() {
    return _instance;
  }

  showAlertDialog(
      BuildContext context, String alertTitle, String alertMessage) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Ok"),
      onPressed: () {
        Navigator.pop(context);
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
        return alert;
      },
    );
  }
}

AlertDialog buildColumnDialog(
    {required BuildContext context,
    required String title,
    required Column content,
    required List<String> buttonTexts,
    List callbacks = const []}) {
  const textStyle = TextStyle(color: Colors.black);
  return AlertDialog(
      title: Text(title, style: textStyle),
      elevation: 5,
      content: content,
      actions: actionButtons(context, callbacks, buttonTexts));
}

Future<List<LatLng>> routeDialog(
    BuildContext context, int points, Function callback) async {
  List<TextEditingController> controllers = [];
  List<LatLng> routePoints = [LatLng(52.05884, -1.345583)];
  List<String> waypoints = [];
  for (int i = 0; i < points; i++) {
    controllers.add(TextEditingController());
    waypoints.add('Waypoint ${i + 1}');
  }

  // User user = User(forename: '', surname: '', email: '', password: '');

  await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return buildColumnDialog(
            context: context,
            title: 'Trip Details',
            content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Enter trip waypoints:'),
                  for (int i = 0; i < points; i++) ...[
                    Row(
                      children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                              child: TextField(
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  controller: controllers[i],
                                  decoration:
                                      InputDecoration(hintText: waypoints[i])),
                                  
                            )),
                      ],
                    )
                  ]
                ]),
            buttonTexts: [
              'OK',
              'CANCEL'
            ],
            callbacks: [
              () async {
                //  setState() async {
                await callback(controllers).then((result) {
                  if (result != null) {
                    routePoints = result;
                    debugPrint('routePoints.length = ${routePoints.length}');
                    //     if (context.mounted) {
                    //       Navigator.pop(context, routePoints);
                    //     } else {
                    //       debugPrint('Context not mounted');
                    //     }
                  }
                });
                // Navigator.of(context).pop();
                //    }
              },
            ]);
      }).then((result) => {
        if (result != null && result != "OK" && result != "CANCEL")
          {
            routePoints = result,
          }
      });

  return routePoints;
}
//  [LatLng(52.05884, -1.345583)]