import 'package:flutter/material.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(children: const [
      DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Center(
            child: Row(children: [
              Expanded(
                flex: 2,
                child: Icon(
                  Icons.pin_drop,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              Expanded(
                flex: 6,
                child: Text('MotaTrip v1.0',
                    style: TextStyle(color: Colors.white, fontSize: 30)),
              ),
            ]),
          )),
      ListTile(
        leading: Icon(
          Icons.settings,
          size: 30,
        ),
        title: Text('App Settings',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            )),
        //             onTap: () {
        //
        //             }
      ),
      ListTile(
        leading: Icon(
          Icons.download,
          size: 30,
        ),
        title: Text('Download a trip',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            )),
        //             onTap: () {
        //
        //             }
      ),
      ListTile(
        leading: Icon(
          Icons.share,
          size: 30,
        ),
        title: Text('Share your trip',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            )),
        //             onTap: () {
        //
        //             }
      )
    ]));
  }
}
