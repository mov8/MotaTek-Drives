// import 'package:drives/routes/home.dart';
import 'package:drives/constants.dart';
import 'package:drives/screens/invitations.dart';
import 'package:flutter/material.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/services/services.dart';
import 'package:drives/models/other_models.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
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
                      size: 60,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Drives ',
                            style:
                                TextStyle(color: Colors.white, fontSize: 32)),
                        Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                            child: Text(
                                'v${appVersion['major']}.${appVersion['minor']}.${appVersion['patch']} ${appVersion['suffix']}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))),
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
                MaterialPageRoute(builder: (context) => const SetupForm()),
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
              // getMyGroups();

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
              //   getMessagesByGroup();
              // getInvitationssByUser();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InvitationsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.password_outlined,
              size: 30,
            ),
            title: const Text(
              'Log in',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            onTap: () async {
              //   login(context);
              User user = await getUser();

              // 'test@test.com';
              user.password = '';
              Setup().user = user;
              if (context.mounted) {
                LoginState loginState = await loginDialog(context, user: user);
                if (loginState == LoginState.register) {
                  Setup().user.forename = '';
                  Setup().user.surname = '';
                  Setup().user.phone = '';
                  Setup().user.password = '';
                  Setup().jwt = '';
                  if (user.email.isNotEmpty) {
                    await postValidateUser(user: user);
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              SignupForm(loginState: loginState)),
                    );
                  }
                } else if (loginState == LoginState.login) {
                  await saveUser(Setup().user);
                  Setup().setupToDb();
                }
              }
              setState(() {});
            },
            //  Navigator.push(
            //    context,
            //    MaterialPageRoute(builder: (context) => const GroupForm()),
          ),
          if (true) ...[
            //Setup().user.email == 'james@staintonconsultancy.com') ...[
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                size: 30,
              ),
              trailing: PopupMenuButton(
                  itemBuilder: (context) => adminOptions
                      .map<PopupMenuEntry<String>>(
                        (e) => PopupMenuItem(
                          value: e['value'],
                          onTap: () {
                            debugPrint('Admin Option: ${e['text']}');
                            if (e['value'] == 'shop') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShopForm(),
                                ),
                              );
                            } else if (e['value'] == 'home') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeForm(),
                                ),
                              );
                            } else if (e['value'] == 'remove') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DeleteTripsForm(),
                                ),
                              );
                            } else if (e['value'] == 'user') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DeleteUserForm(),
                                ),
                              );
                            } else if (e['value'] == 'survey') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SurveyForm(),
                                ),
                              );
                            } else if (e['value'] == 'invite') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InviteForm(),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [e['iconData'], Text(e['text'])],
                          ),
                        ),
                      )
                      .toList()),
              title: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                ),
              ),
              onTap: () {
                // tryLogin(user);
              },
              //  Navigator.push(
              //    context,
              //    MaterialPageRoute(builder: (context) => const GroupForm()),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> adminOptions = [
    {
      'text': 'Home Page Content',
      'iconData': const Icon(Icons.home_outlined),
      'value': 'home'
    },
    {
      'text': 'Shop Content',
      'iconData': const Icon(Icons.shopping_bag_outlined),
      'value': 'shop'
    },
    {
      'text': 'Remove Drive',
      'iconData': const Icon(Icons.remove_road_outlined),
      'value': 'remove'
    },
    {
      'text': 'Remove User',
      'iconData': const Icon(Icons.person_off_outlined),
      'value': 'user'
    },
    {
      'text': 'Survey',
      'iconData': const Icon(Icons.sick_outlined),
      'value': 'survey'
    },
    {
      'text': 'Invite user',
      'iconData': const Icon(Icons.person_add_outlined),
      'value': 'invite'
    },
  ];
}
