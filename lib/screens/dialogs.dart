import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

Future<List<Polyline>> routeDialog(
    BuildContext context, int points, Function callback) async {
  List<TextEditingController> controllers = [];
  // List<LatLng> routePoints = [LatLng(52.05884, -1.345583)];
  List<Polyline> polylines = [
    Polyline(
        points: [LatLng(52.05884, -1.345583)], // routePoints,
        color: const Color.fromARGB(255, 28, 97, 5),
        strokeWidth: 5)
  ];

  for (int i = 0; i < points; i++) {
    controllers.add(TextEditingController());
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
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Enter trip waypoints:'),
                      for (int i = 0; i < controllers.length; i++) ...[
                        Row(
                          children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: TextField(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: controllers[i],
                                      decoration: InputDecoration(
                                          hintText: 'Waypoint ${i + 1}')),
                                )),
                            const SizedBox(width: 16),
                            _addRemoveWaypoint(
                                context, setState, i, controllers),
                          ],
                        )
                      ]
                    ]),
                buttonTexts: [
                  'OK',
                  'CANCEL',
                ],
                callbacks: [
                  () async {
                    await callback(controllers).then((result) {
                      if (result != null) {
                        polylines = result;
                        debugPrint('polylines.length = ${polylines.length}');
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
    BuildContext context, setState, index, var controllers) {
  return InkWell(
      onTap: () {
        if (index == controllers.length - 1) {
          controllers.add(TextEditingController());
        } else {
          controllers.removeAt(index);
        }
        setState(() {});
      },
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: index == controllers.length - 1 ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            index == controllers.length - 1 ? Icons.add : Icons.remove,
            color: Colors.white,
          )));
}



//  [LatLng(52.05884, -1.345583)]