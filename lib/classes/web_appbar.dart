import 'package:drives/routes/create_trip.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:collection/collection.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:developer' as developer;
// import '/helpers/edit_helpers.dart';
import 'classes.dart';
import '../constants.dart';

/// There is a bit of a design inconsistency between the way the Web app and mobile app does. In the
/// mobile app all six screens are separate routes, so the bottom nav does a simple route load for each.
/// In the Web app Published, Explore, Favourites, Shop and Messages are all the single Explore Route
/// with the Published, Favourites, Shop and Messages being injected into the SideDrawer where they can
/// keep their Mobile aspect ratio.

const List<String> pageHeadings = [
  'Home - MotaTek Drives plan your next adventure.',
  'Published -  load a trip from the Drives community.',
  'Explore - plan a new adventure.',
  "Favourites - your personal store of trips you've enjoyed",
  "Shop - check out the offers that'll make your trips even better",
  "Messages - keep in touch with the Drives community.",
];

const List<String> toolTips = [
  "Drives news - see what new trips have been posted, and what's going on the the Drives community.",
  "Choose a drive to download. You can just enjoy it, or modify it for your own needs.",
  "Create a new trip, edit an existing trip, follow an created trip, or use Drives to track a trip you're exploring.",
  "All the trips that you have created or modified allowing you to follow or edit a trip.",
  "Enjoy the offers our supporters have on offer.",
  "Keep in contact with the Drives community.",
  "You are logged in to your Drives account. You can share trips and have full access to all the Drive's features.",
  "You are not logged in. To be able to share trips, and have access to all Drive's features please click to log in or create an account now.",
  "Access further functionality - app settings, your details, driving groups, organise events, invite new users etc.",
];

enum SampleItem { itemOne, itemTwo, itemThree }

class WebAppBarController {
  _WebAppBarState? _webAppBarState;

  void _addState(_WebAppBarState webAppBarState) {
    _webAppBarState = webAppBarState;
  }

  void showControls() {
    if (_webAppBarState != null) {
      _webAppBarState!.showControls();
    }
  }

  void update() {
    if (_webAppBarState != null) {
      _webAppBarState!.update();
    }
  }

  bool get isAttached => _webAppBarState != null;
  void changeButton(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _webAppBarState?.changeButton(id);
    } catch (e) {
      debugPrint('Error changing button: ${e.toString()}');
    }
  }

  void setActionPrompt(String prompt) {
    if (isAttached) {
      _webAppBarState!.setActionMessage(prompt);
    }
  }

  int get buttonIndex => _webAppBarState!._selected;
}

class WebAppBar extends StatefulWidget implements PreferredSizeWidget {
  // String heading;
  final BuildContext context;
  final LeadingWidgetController? controller;
  final CreateTripController?
      tripController; // <-- Changes the data for CreateTrips
  final WebAppBarController? appBarController;
  final SideDrawerController? sideDrawerController;
  final StatusBarController? statusBarController;
  Function(int)? onMenuTap;
  final Function(int)? onSelect;

  int initialValue;
  int selected;
  int value;

  WebAppBar({
    super.key,
    // required this.heading,
    required this.context,
    this.controller,
    this.appBarController,
    this.tripController,
    this.sideDrawerController,
    this.statusBarController,
    this.initialValue = 0,
    this.selected = 0,
    this.value = 0,
    this.onMenuTap,
    this.onSelect,
  });

  @override
  State<WebAppBar> createState() => _WebAppBarState();

  /// PreferredSize interface must have the following
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 65);
}

class _WebAppBarState extends State<WebAppBar> {
  late int initialValue;
  late int _selected;
  late int value;
  String _heading = '';
  String _actionMessage = '';
  bool _showControls = false;
  bool _menuExists = false;
  final GlobalKey _menuButtonKey = GlobalKey();
  final GlobalKey _menuItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.appBarController != null) {
      widget.appBarController!._addState(this);
    }
    initialValue = widget.initialValue;
    _selected = widget.selected;
  }

  void changeButton(int value) {
    setState(() => _selected = value);
  }

  void setHeading(String heading) {
    setState(() => heading = heading);
  }

  void showControls() {
    setState(() => _showControls = true);
  }

  void update() {
    setState(() {});
  }

  String screenName = '';
  List<String> overflowPrompts = ['one', 'two', 'three'];
  SampleItem selectedItem = SampleItem.itemOne;

  @override
  Widget build(BuildContext context) {
    ModalRoute? currentRoute = ModalRoute.of(context);
    screenName = 'home';
    if (currentRoute != null) {
      screenName = currentRoute.settings.name ?? 'gok';
    }
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      automaticallyImplyLeading: false,
      /* leading: LeadingWidget(
        controller: widget.controller,
        initialValue: 0, //widget.initialValue, //   initialLeadingWidgetValue,
        onMenuTap: widget.onMenuTap,
      ),
      */
      iconTheme: const IconThemeData(color: Colors.white),

      /// Removes Shadow
      toolbarHeight: 40,
      title: FittedBox(
        child: Row(children: [
          Text(
            pageHeadings[_selected].split('-').first,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            pageHeadings[_selected].split('-').last,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
      bottom: !_showControls
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 1, 5, 10),
                //  child: Row(
                //    children: [
                child: Row(
                  children: [
                    Align(
                      alignment: AlignmentGeometry.bottomLeft,
                      child: Expanded(
                        flex: 4,
                        child: SizedBox(
                          width: 200,
                          child: getActionMessage(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 14,
                      child: Align(
                        alignment: AlignmentGeometry.topEnd,
                        child: Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(0, 0, 10, 0),
                          child: Wrap(
                            spacing: 20,
                            children: [
                              for (int i = 0; i < 6; i++) ...[
                                //  MouseRegion could be looked at as a way of showing tool tips on status bar
                                MouseRegion(
                                  onEnter: (_) => updateToolTips(true, i),
                                  onExit: (_) => updateToolTips(false, i),
                                  child: Padding(
                                    padding:
                                        EdgeInsetsGeometry.fromLTRB(0, 5, 5, 0),
                                    child: ActionChip(
                                      // tooltip: toolTips[i],
                                      onPressed: () => navigate(context, i),
                                      chipAnimationStyle: ChipAnimationStyle(
                                        selectAnimation: const AnimationStyle(
                                          duration: Duration(seconds: 3),
                                          reverseDuration: Duration(seconds: 1),
                                        ),
                                      ),
                                      pressElevation: 5,
                                      avatar: Icon(
                                        routeNavIcons[i],
                                        color: _selected == i
                                            ? const Color.fromRGBO(
                                                173, 215, 255, 1)
                                            : Colors.white,
                                      ),
                                      label: Text(
                                        routeNavLabels[i],
                                      ),
                                      labelStyle: TextStyle(
                                          fontSize: 12,
                                          color: _selected == i
                                              ? Color.fromRGBO(173, 215, 255, 1)
                                              : Colors.white),
                                      backgroundColor: Colors.blueGrey,
                                      disabledColor: Colors.blueGrey,
                                      shadowColor: _selected != i
                                          ? Colors.grey.shade900
                                          : null,
                                      elevation: 5,
                                    ),
                                  ),
                                ), // <-- MouseRegion
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 1),
                    Expanded(
                      flex: 2,
                      child: MouseRegion(
                        onEnter: (_) => updateToolTips(true,
                            toolTips.length - (Setup().jwt.isEmpty ? 2 : 3)),
                        onExit: (_) => updateToolTips(false,
                            toolTips.length - (Setup().jwt.isEmpty ? 2 : 3)),
                        child: Row(
                          children:
                              CurrentTripItem().getActions(context: context),
                        ),
                      ),
                    ),
                    SizedBox(width: 1),
                    Expanded(
                      flex: 1,
                      child: MouseRegion(
                        onEnter: (_) => updateToolTips(true,
                            toolTips.length - (Setup().jwt.isEmpty ? 2 : 3)),
                        onExit: (_) => updateToolTips(false,
                            toolTips.length - (Setup().jwt.isEmpty ? 2 : 3)),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Setup().jwt.isEmpty
                                ? Icons.no_accounts_outlined
                                : Icons.account_circle_outlined,
                            size: 30,
                            color: Colors.white,
                          ),
                          iconSize: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 1),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        key: _menuButtonKey,
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () => _showCustomMenu(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showCustomMenu(BuildContext context) async {
    if (!_menuExists) {
      _menuExists = true;
      if (!_menuExists || _menuExists) {
        // 1. Find the position of the button on the screen
        final RenderBox button =
            _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
        final RenderBox overlay = NavigationService()
            .key
            .currentContext!
            .findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            //  button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(
                button.size.bottomRight(Offset.zero), // .zero),
                ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        // 2. Use showMenu with the ROOT navigator's context
        // final String? selected =
        await showMenu<String>(
          constraints: BoxConstraints(minWidth: 250),
          context: NavigationService()
              .key
              .currentContext!, // BREAK OUT: Use the main navigator!
          position: position,
          items: getPopupMenuItems(),
        );
        _menuExists = false;
      }
    }
  }

  List<PopupMenuEntry<String>> getPopupMenuItems() {
    _menuExists = true;
    List<PopupMenuEntry<String>> menuItems = drawerOptions
        .where((map) =>
            (map['iconData'] ?? '') != '') // <- show only ones with Icons
        .map<PopupMenuEntry<String>>(
          (e) => PopupMenuItem(
            onTap: () {
              setSideDrawerContent(content: e['drawer']);
            },
            value: e['key'],
            child: PointerInterceptor(
              child: Row(
                key: Key('pmi${e['key']}'),
                children: [
                  e['iconData'],
                  SizedBox(
                    width: 10,
                  ),
                  Text(e['text']),
                ],
              ),
            ),
          ),
        )
        .toList();

    /// Add the restore option to set Side Drawer content back to original page data.
    if (widget.sideDrawerController!.screenCache.isNotEmpty &&
        widget.sideDrawerController!.content != BottomDrawerItems.cached &&
        widget.sideDrawerController!.offerRestore) {
      menuItems.insert(
        0,
        PopupMenuItem(
          key: _menuItemKey,
          onTap: () => setSideDrawerContent(
            content: BottomDrawerItems.cached,
          ),
          value: 'cache',
          child: Row(
            key: Key('restore'),
            children: [
              Icon(Icons.restore_page_outlined, size: 30),
              SizedBox(
                width: 10,
              ),
              Text('Restore side drawer data'),
            ],
          ),
        ),
      );
    }
    return menuItems;
  }

  Widget getActionMessage(
      {Color colour = Colors.white,
      double pointSize = 22,
      FontWeight fontWeight = FontWeight.normal}) {
    String prompt = '';
    if (widget.sideDrawerController != null) {
      if (widget.sideDrawerController!.isOpen) {
        String contentKey =
            widget.sideDrawerController!.content.toString().split('.').last;
        for (int i = 0; i < drawerOptions.length; i++) {
          if (drawerOptions[i]['key'] == contentKey) {
            if (contentKey == 'messages' && _actionMessage.isNotEmpty) {
              prompt = _actionMessage;
            } else {
              _actionMessage = '';
              prompt = drawerOptions[i]['text'];
            }
            break;
          }
        }
      }
    }

    return Text(
      prompt,
      style: TextStyle(
        color: colour,
        fontSize: pointSize,
        fontWeight: fontWeight,
      ),
    );
  }

/*
  Widget setActionMessage(
      {String prompt = '',
      Color colour = Colors.white,
      double pointSize = 22,
      FontWeight fontWeight = FontWeight.normal}) {
    return Text(
      prompt,
      style: TextStyle(
        color: colour,
        fontSize: pointSize,
        fontWeight: fontWeight,
      ),
    );
  }
*/

  void setActionMessage(prompt) {
    setState(() => _actionMessage = prompt);
  }

  void updateToolTips(bool enter, int i) {
    if (widget.statusBarController != null) {
      try {
        if (enter) {
          widget.statusBarController!.update([toolTips[i]]);
        } else {
          widget.statusBarController!.clear();
        }
      } catch (e) {
        debugPrint('whoops: ${e.toString()}');
      }
    }
  }

  /// navigate changes the pages for the app note:
  ///   The only real page changes are:
  ///     Home
  ///     Explore
  ///     Shop
  ///   all the other pages in the web version are handled by the side drawer
  ///   navigate uses the NavigationService() singleton that holds the whole app's
  ///   context. This is important, because the persistent widgets WebAppBar() and
  ///   SideDrawer() are created before the main navigation is defined.
  void navigate(BuildContext context, int index) {
    _heading = pageHeadings[index];
    _menuExists = false;

    /// <--- If the user taps a button when the menu is showing they'll never see it again
    if (index != 5) {
      // <-- stop messages changing the side drawer type to fixed == false
      MapService()
          .sideDrawerController!
          .setFixed(fixed: [0, 4].contains(index));
    }
    switch (index) {
      case 1:
        {
          /// Fulfil Published - Trips

          try {
            MapService().setPage(page: 1);

            /// <-- Tell the MapService what to do
            if (screenName != 'createTrip') {
              NavigationService().navigateTo(
                routes[2], // <--- Published uses CreateTrip() screen
                TripArguments(
                    appState: AppState.trips,
                    activeChip: 1,
                    changedScreen: true),
              );
            } else {
              widget.tripController?.updateArguements(
                arguments:
                    TripArguments(appState: AppState.trips, activeChip: 1),
              );
            }
          } catch (e) {
            developer.log(
                'Error trying to switch to no:1 error: ${e.toString()}',
                name: 'error');
          }
        }
      case 2:
        {
          /// Fulfil Explore - CreateTrip
          try {
            MapService().setPage(page: 2); // <-- Published setup
            if (screenName != 'createTrip') {
              NavigationService().navigateTo(
                routes[2], // <-- CreateTrips()
                TripArguments(
                    appState: AppState.createTrip,
                    activeChip: 2,
                    changedScreen: true),
              );

              //  arguments: TripArguments(myTripItem, 'db'));
            } else {
              widget.tripController?.updateArguements(
                arguments:
                    TripArguments(appState: AppState.createTrip, activeChip: 2),
              );
            }
          } catch (e) {
            developer.log(
                'Error trying to switch to no:2 error: ${e.toString()}',
                name: 'error');
          }
        }
      case 3:
        {
          MapService().setPage(page: 3);

          /// Fulfil Favourites - MyTrips
          if (screenName != 'createTrip') {
            NavigationService().navigateTo(
              routes[2], // <-- uses CreateTrips() with MyTrips in SideDrawer
              TripArguments(
                appState: AppState.myTrips,
                activeChip: 3,
                changedScreen: true,
              ),
            );
          } else {
            widget.tripController?.updateArguements(
              arguments:
                  TripArguments(appState: AppState.myTrips, activeChip: 3),
            );
          }
        }
      case 5: // <-- Messages
        if (widget.sideDrawerController!.content ==
                BottomDrawerItems.messages &&
            widget.sideDrawerController!.screenCache.isNotEmpty) {
          setSideDrawerContent(content: BottomDrawerItems.cached);
        } else {
          setSideDrawerContent(content: BottomDrawerItems.messages);
        }
      default:
        debugPrint('Current page: $screenName');
        NavigationService().navigateTo(routes[index],
            TripArguments(appState: AppState.myTrips, activeChip: index));
      /*          )
        Navigator.pushNamed(context, routes[index],
            arguments:
                TripArguments(appState: AppState.myTrips, activeChip: index));
      */
    }

    if (widget.onSelect != null) {
      widget.onSelect!(index);
    }

    setState(() => _selected = index == 5 ? _selected : index);
    return;
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

  Future<void> setSideDrawerContent(
      {required BottomDrawerItems content, List<Widget>? drawerData}) async {
    drawerData ??= [];
    _menuExists = false;
    try {
      if (widget.sideDrawerController!.isFixed) {
        widget.sideDrawerController!.setVisible(visible: false);
        await Future.delayed(Duration(milliseconds: 500));
        widget.sideDrawerController!
            .setContent(content: content, drawerItems: drawerData);
        await Future.delayed(Duration(milliseconds: 500));
        widget.sideDrawerController!.setVisible(visible: true);
      } else {
        widget.sideDrawerController!.close();
        await Future.delayed(Duration(milliseconds: 500));
        widget.sideDrawerController!
            .setContent(content: content, drawerItems: drawerData);
        await Future.delayed(Duration(milliseconds: 500));
        widget.sideDrawerController!.open();
      }
    } catch (e) {
      developer.log('Error PopupMenuButton.onSelect(): ${e.toString()}',
          name: 'error');
    }
  }
}
/*
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  Future<void> navigateTo(String routeName, Object? arguments) {
    return key.currentState!.pushNamed(routeName, arguments: arguments);
  }

  void goBack() {
    return key.currentState!.pop();
  }
}
*/
