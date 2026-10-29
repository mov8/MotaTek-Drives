import '/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/screens/screens.dart';
import '/services/services.dart';
import '/models/other_models.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    double width = kIsWeb ? 0.3 : 0.75;
    return Drawer(
      width: MediaQuery.of(context).size.width * width,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Icon(
                      Icons.pin_drop,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Drives ',
                            style:
                                TextStyle(color: Colors.white, fontSize: 30)),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                          child: Text(
                            'v${appVersion['major']}.${appVersion['minor']}.${appVersion['patch']} ${appVersion['suffix']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
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
                MaterialPageRoute(builder: (context) => SetupForm()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined, size: 30),
            title: Text(
              Setup().jwt.isEmpty ? 'Register my details' : 'Change my details',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupForm()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.groups_outlined,
              size: 30,
            ),
            title: const Text(
              'Groups I manage',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupForm()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.group_outlined,
              size: 30,
            ),
            title: const Text(
              "Groups to which I belong",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyGroupsForm()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.person_add_outlined,
              size: 30,
            ),
            title: const Text(
              'Introduce new user',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntroduceForm()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.directions_car_outlined,
              size: 30,
            ),
            title: const Text("Events I've organised",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                )),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupDriveForm()),
              );
            },
          ),
          ListTile(
            leading: Setup().tripCount > 0
                ? Badge(
                    label: Text(Setup()
                        .tripCount
                        .toString()), //widget.group.unreadMessages.toString()),
                    child: Icon(
                      Icons.mail_outline,
                      size: 30,
                    ),
                  )
                : const Icon(
                    Icons.mail_outlined,
                    size: 30,
                  ),
            title: const Text(
              'My invitations to events',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InvitationsScreen()),
              );
            },
          ),
          // the map along a saved trip, for where there's no signal
          if (Setup().jwt.isNotEmpty && OfflineMapsService().supported)
            ListTile(
              leading:
                  const Icon(Icons.download_for_offline_outlined, size: 30),
              title: const Text(
                'Offline maps',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OfflineMapsScreen()),
                );
              },
            ),
          // a problem, an idea or a question, to the Drives team
          ListTile(
            leading: const Icon(Icons.feedback_outlined, size: 30),
            title: const Text(
              'Send feedback',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackForm()),
              );
            },
          ),
        ],
      ),
    );
  }
}
