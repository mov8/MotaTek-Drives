import 'package:drives/routes/create_trip.dart';
import 'package:drives/routes/home.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'dart:developer' as developer;
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
  final BuildContext context;
  final LeadingWidgetController? controller;
  final CreateTripController?
      tripController; // <-- Changes the data for CreateTrips
  final WebAppBarController? appBarController;
  final SideDrawerController? sideDrawerController;
  final StatusBarController? statusBarController;
  final HomeController? homeController;
  Function(int)? onMenuTap;
  final Function(int)? onSelect;

  int initialValue;
  int selected;
  int value;

  WebAppBar({
    super.key,
    required this.context,
    this.controller,
    this.appBarController,
    this.tripController,
    this.sideDrawerController,
    this.statusBarController,
    this.homeController,
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
                          // The phone's login screen, in the SideDrawer like the other forms
                          onPressed: () {
                            if (Setup().jwt.isEmpty) {
                              setSideDrawerContent(
                                  content: BottomDrawerItems.login);
                            }
                          },
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

  /// Gets the menu to overcome the Navigator issue when using a Static Stack architecture
  /// The Navigator belongs to the lowest Static layer, so pop-ups have problems finding a
  /// canvas to paint on. This represents the first fix.
  /// todo follow the new solution of adding a Global key for the upper overlaid UI elements
  /// as implemented for the side drawer.
  /// getPopupMenuItems() creates the list of PopupMenuItems from the data.

  void _showCustomMenu(BuildContext context) async {
    if (!_menuExists) {
      _menuExists = true;
      if (!_menuExists || _menuExists) {
        // 1. Find the position of the button on the screen
        final RenderBox button =
            _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
        // The WebAppBar is inside the router's navigator now, so its own
        // context finds the overlay - the old uiKey belonged to the old shell
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(
                button.size.bottomRight(Offset.zero), // .zero),
                ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        // 2. Use showMenu with the ROOT navigator's context
        await showMenu<String>(
          constraints: BoxConstraints(minWidth: 250),
          context: context,
          position: position,
          items: getPopupMenuItems(),
        );
        _menuExists = false;
      }
    }
  }

  /// For the popup menu only want to include those drawerOptions that have an icon
  /// Also want to only allow the Home option if the _selected == 0 and the user canEdit
  /// and want to only allow Shop option is _selected == 4 and the user canEdit
  List<PopupMenuEntry<String>> getPopupMenuItems() {
    _menuExists = true;
    List<PopupMenuEntry<String>> menuItems =
        drawerOptions // <-- Links enum BottomDrawerItems with menuItems
            .where((map) =>
                (map['iconData'] ?? '') != '' &&
                    //   !['home', 'shop'].contains(map['key']) ||
                    !['markdownHome', 'markdownShop'].contains(map['key']) ||
                Setup().user.type >= 3 &&
                    ((map['key'] == 'markdownHome' && _selected == 0 ||
                        map['key'] == 'markdownShop' &&
                            _selected == 4))) // <- show only ones with Icons
            .map<PopupMenuEntry<String>>(
              (e) => PopupMenuItem(
                onTap: () {
                  setSideDrawerContent(content: e['drawer']);
                },
                value: e['key'],
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
  ///   - Home
  ///   - Explore
  ///   - Shop
  ///   all the other pages in the web version are handled by the side drawer
  ///   navigate uses the NavigationService() singleton that holds the whole app's
  ///   context. This is important, because the persistent widgets WebAppBar() and
  ///   SideDrawer() are created before the main navigation is defined.
  void navigate(BuildContext context, int index) {
    _menuExists = false;

    // The SideDrawer collapses on the map pages, where the map matters;
    // elsewhere it holds the page's summaries and stays open
    MapService().sideDrawerController!.setFixed(fixed: ![1, 2].contains(index));
    switch (index) {
      /// Published (1), Explore (2) and Favourites (3) - the shell switches to
      /// the map page and sets up the map and SideDrawer once it is built
      /// (BaseShellScreen._webSelect() via onSelect below)
      case 1 || 2 || 3:
        break;

      /// The other cases will be rendered as screen contents and so are just pushed
      /// by the NavigationService() singleton. The map is totally hidden in the stack.
      /// The side drawer is fixed, and contains the data to navigate the main screen area.
      default:
        debugPrint('Current page: $screenName');
    }

    if (widget.onSelect != null) {
      widget.onSelect!(index);
    }

    setState(() => _selected = index);
    return;
  }

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
