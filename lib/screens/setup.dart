import 'package:flutter/material.dart';
import 'package:material_symbols_icons/get.dart';
// import 'package:material_symbols_icons/material_symbols_icons.dart';
// import 'package:material_symbols_icons/get.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/db_helper.dart';

class SetupForm extends StatefulWidget {
  // var setup;
  const SetupForm({super.key, setup});
  @override
  State<SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<SetupForm> {
  //int sound = 0;
  final iconFlyover = SymbolsGet.get('flyover', SymbolStyle.sharp);
  final iconRoad = SymbolsGet.get('road', SymbolStyle.sharp);

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
        title: const Text('Drives setup',
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
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

  Widget portraitView() {
    return SingleChildScrollView(
      child: Column(children: [
        SwitchListTile(
          title: Text('Notifications',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().allowNotifications,
          onChanged: (bool value) {
            setState(
              () {
                Setup().allowNotifications = value;
              },
            );
          },
          secondary: const Icon(Icons.notifications_on_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Auto-rotate map',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().rotateMap,
          onChanged: (bool value) {
            setState(
              () {
                Setup().rotateMap = value;
              },
            );
          },
          secondary: const Icon(Icons.on_device_training, size: 30),
        ),
        SwitchListTile(
          title: Text('Avoid motorways',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().avoidMotorways,
          onChanged: (bool value) {
            setState(
              () {
                Setup().avoidMotorways = value;
              },
            );
          },
          secondary: Icon(iconFlyover, size: 30),
        ),
        SwitchListTile(
          title: Text('Avoid toll roads',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().avoidTollRoads,
          onChanged: (bool value) {
            setState(
              () {
                Setup().avoidTollRoads = value;
              },
            );
          },
          secondary: const Icon(Icons.toll, size: 30),
        ),
        SwitchListTile(
          title: Text('Avoid ferries',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().avoidFerries,
          onChanged: (bool value) {
            setState(() {
              Setup().avoidFerries = value;
            });
          },
          secondary: const Icon(Icons.directions_boat_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show un-reviewed pubs and bars',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmPubs,
          onChanged: (bool value) {
            setState(() {
              Setup().osmPubs = value;
            });
          },
          secondary: const Icon(Icons.sports_bar_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show un-reviewed cafes and restaurants',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmRestaurants,
          onChanged: (bool value) {
            setState(() {
              Setup().osmRestaurants = value;
            });
          },
          secondary: Icon(Icons.restaurant_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show fuel and charging stations',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmFuel,
          onChanged: (bool value) {
            setState(() {
              Setup().osmFuel = value;
            });
          },
          secondary: Icon(Icons.local_gas_station_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show toilets',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmToilets,
          onChanged: (bool value) {
            setState(() {
              Setup().osmToilets = value;
            });
          },
          secondary: Icon(Icons.wc_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show un-reviewed historic sites',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmHistorical,
          onChanged: (bool value) {
            setState(() {
              Setup().osmHistorical = value;
            });
          },
          secondary: Icon(Icons.castle_outlined, size: 30),
        ),
        SwitchListTile(
          title: Text('Show cashpoints',
              style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().osmAtms,
          onChanged: (bool value) {
            setState(() {
              Setup().osmAtms = value;
            });
          },
          secondary: Icon(Icons.local_atm_outlined, size: 30),
        ),
        SwitchListTile(
          title:
              Text('Dark mode', style: Theme.of(context).textTheme.bodyLarge!),
          value: Setup().dark,
          onChanged: (bool value) {
            setState(
              () {
                Setup().dark = value;
                //  ThemeSetter().isDark(Setup().dark);
              },
            );
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
                  value:
                      uiColours.values.elementAt(Setup().pointOfInterestColour),
                  items: colourChoices(context),
                  onChanged: (chosen) => setState(() =>
                      Setup().pointOfInterestColour =
                          uiColours.values.toList().indexOf(chosen.toString())),
                  //  uiColours.keys.toList().toString().indexOf(item.toString())),
                ),
              ),
            ),
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
                  onChanged: (chosen) => setState(() =>
                      Setup().pointOfInterestColour2 =
                          uiColours.values.toList().indexOf(chosen.toString())),
                  //  uiColours.keys.toList().toString().indexOf(item.toString())),
                ),
              ),
            ),
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
                  onChanged: (chosen) => setState(() =>
                      Setup().waypointColour2 =
                          uiColours.values.toList().indexOf(chosen.toString())),
                  //  uiColours.keys.toList().toString().indexOf(item.toString())),
                ),
              ),
            ),
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
                ),
              ),
            ),
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
                  onChanged: (chosen) => setState(() =>
                      Setup().goodRouteColour =
                          uiColours.values.toList().indexOf(chosen.toString())),
                ),
              ),
            ),
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
                    labelText: 'Published trip colour',
                  ),
                  value:
                      uiColours.values.elementAt(Setup().publishedTripColour),
                  items: colourChoices(context),
                  onChanged: (chosen) => setState(() =>
                      Setup().publishedTripColour =
                          uiColours.values.toList().indexOf(chosen.toString())),
                  //  uiColours.keys.toList().toString().indexOf(item.toString())),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Highlight colour',
                  ),
                  value: uiColours.values.elementAt(Setup().highlightedColour),
                  items: colourChoices(context),
                  onChanged: (chosen) => setState(() =>
                      Setup().highlightedColour =
                          uiColours.values.toList().indexOf(chosen.toString())),
                  //  uiColours.keys.toList().toString().indexOf(item.toString())),
                ),
              ),
            ),
          ],
        ),
        Row(children: [
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
                onChanged: (chosen) => setState(() => Setup().selectedColour =
                    uiColours.values.toList().indexOf(chosen.toString())),
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
        ]),
      ]),
    );
  }
}

List<DropdownMenuItem<String>> colourChoices(BuildContext context) {
  return [
    for (MapEntry<Color, String> e in uiColours.entries)
      DropdownMenuItem<String>(
        value: e.value,
        child: Row(
          children: [
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
          ],
        ),
      )
  ];
}
