import 'package:flutter/material.dart';
import 'package:drives/screens/sign_up.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(children: [
      const DrawerHeader(
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
      const ListTile(
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
          leading: const Icon(Icons.how_to_reg, size: 30),
          title: const Text('Your Details',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupForm()),
            );
          }),
      const ListTile(
        leading: Icon(
          Icons.groups,
          size: 30,
        ),
        title: Text('Organise Groups',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            )),
        //             onTap: () {
        //
        //             }
      ),
      const ListTile(
        leading: Icon(
          Icons.no_crash,
          size: 30,
        ),
        title: Text('Organise Group Trip',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
            )),
        //             onTap: () {
        //
        //             }
      ),
      const ListTile(
        leading: Icon(
          Icons.share,
          size: 30,
        ),
        title: Text('Organise Followers',
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
