import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/services/db_helper.dart';
// import 'package:drives/services/web_helper.dart';

class SetupForm extends StatefulWidget {
  // var setup;
  const SetupForm({super.key, setup});
  @override
  State<SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<SetupForm> {
  //int sound = 0;

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            try {
              insertSetup(Setup());
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),

        /// Removes Shadow
        title: const Text('MotaTrip setup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text('Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ))),
        ),

        /// Shrink height a bit

        actions: const <Widget>[
          /*
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Back to main screen',
            onPressed: () {
              debugPrint('debug print');
              try {
                // insertPort(widget.port);
                // insertGauge(widget.gauge);
              } catch (e) {
                debugPrint('Error saving data : ${e.toString()}');
              }
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data has been updated')));
            },
          )
          */
        ],
      ),

      body: portraitView(),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Column portraitView() {
    return Column(children: [
      SwitchListTile(
        title: Text('Notifications',
            style: Theme.of(context).textTheme.bodyLarge!),
        value: Setup().allowNotifications,
        onChanged: (bool value) {
          setState(() {
            Setup().allowNotifications = value;
          });
        },
        secondary: const Icon(Icons.notifications_on_outlined, size: 30),
      ),
      SwitchListTile(
        title: Text('Auto-rotate map',
            style: Theme.of(context).textTheme.bodyLarge!),
        value: Setup().rotateMap,
        onChanged: (bool value) {
          setState(() {
            Setup().rotateMap = value;
          });
        },
        secondary: const Icon(Icons.on_device_training, size: 30),
      ),
      SwitchListTile(
        title: Text('Dark mode', style: Theme.of(context).textTheme.bodyLarge!),
        value: Setup().dark,
        onChanged: (bool value) {
          setState(() {
            Setup().dark = value;
            //  ThemeSetter().isDark(Setup().dark);
          });
        },
        secondary: const Icon(Icons.dark_mode),
      ),
      Row(
        children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Point of Interest Background',
                    ),
                    value: uiColours.values
                        .elementAt(Setup().pointOfInterestColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .pointOfInterestColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Point of Interest Foreground',
                    ),
                    value: uiColours.values
                        .elementAt(Setup().pointOfInterestColour2),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .pointOfInterestColour2 =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
        ],
      ),
      Row(
        children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Waypoint Background',
                    ),
                    value: uiColours.values.elementAt(Setup().waypointColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .waypointColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Waypoint Foreground',
                    ),
                    value: uiColours.values.elementAt(Setup().waypointColour2),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .waypointColour2 =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
        ],
      ),
      Row(
        children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Route colour',
                    ),
                    value: uiColours.values.elementAt(Setup().routeColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup().routeColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Good route colour',
                    ),
                    value: uiColours.values.elementAt(Setup().goodRouteColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .goodRouteColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                  ))),
        ],
      ),
      Row(
        children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Highlight colour',
                    ),
                    value:
                        uiColours.values.elementAt(Setup().highlightedColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .highlightedColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Selected colour',
                    ),
                    value: uiColours.values.elementAt(Setup().selectedColour),
                    items: colourChoices(context),
                    onChanged: (chosen) => setState(() => Setup()
                            .selectedColour =
                        uiColours.values.toList().indexOf(chosen.toString())),
                  ))),
        ],
      ),
    ]);
  }
}

List<DropdownMenuItem<String>> colourChoices(BuildContext context) {
  return [
    for (MapEntry<Color, String> e in uiColours.entries)
      DropdownMenuItem<String>(
          value: e.value,
          child: Row(children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(shape: BoxShape.circle, color: e.key),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child:
                  Text(e.value, style: Theme.of(context).textTheme.bodyLarge!),
            )
          ]))
  ];
}
