import 'package:flutter/material.dart';
import 'package:drives/screens/sign_up.dart';
import 'package:drives/screens/setup.dart';
import 'package:drives/screens/group.dart';
import 'package:drives/screens/introduce.dart';
import 'package:drives/screens/my_groups.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/models.dart';

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
      ListTile(
          leading: const Icon(
            Icons.settings,
            size: 30,
          ),
          title: const Text('App Settings',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SetupForm()),
            );
          }),
      if (Setup().jwt.isEmpty) ...[
        ListTile(
            leading: const Icon(Icons.how_to_reg, size: 30),
            title: const Text('Register Your Details',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                )),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupForm()),
              );
            }),
      ],
      ListTile(
          leading: const Icon(
            Icons.groups,
            size: 30,
          ),
          title: const Text('Groups I manage',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupForm()),
            );
          }),
      ListTile(
          leading: const Icon(
            Icons.group,
            size: 30,
          ),
          title: const Text("Groups I'm a member of",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            // getMyGroups();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyGroupsForm()),
            );
          }),
      ListTile(
          leading: const Icon(
            Icons.person_add,
            size: 30,
          ),
          title: const Text('Introduce new user',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IntroduceForm()),
            );
          }),
      ListTile(
          leading: const Icon(
            Icons.rsvp,
            size: 30,
          ),
          title: const Text('Invitations',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupForm()),
            );
          }),
      ListTile(
          leading: const Icon(
            Icons.directions_car,
            size: 30,
          ),
          title: const Text('Events',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              )),
          onTap: () {
            login(context);
          }
          //  Navigator.push(
          //    context,
          //    MaterialPageRoute(builder: (context) => const GroupForm()),
          ),
    ]));
  }
}
