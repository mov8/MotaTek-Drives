import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '/constants.dart';
import '/models/other_models.dart';
import '/services/services.dart' hide getPosition;
import '/helpers/helpers.dart';
import '/classes/page_empty_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '/theme.dart';

class HomeController {
  _HomeState? _homeState;
  void _addState(_HomeState homeState) {
    _homeState = homeState;
  }

  bool get isAttached => _homeState != null;

  int get index => _homeState!._index;

  void update(Map<String, dynamic> data) {
    _homeState?.updateData(data);
  }

  String getMarkdown() => _homeState!.mdData;
  MdStyleSheet getStyle() => _homeState!._styleSheet;

  /// Web: puts the summary tiles back in the SideDrawer on returning to Home
  void fillSideDrawer() => _homeState?.sideBarItems(force: true);

  /// The pages shown changed - logging in or out, or joining or leaving a
  /// club (ClubService)
  void reload() => _homeState?.reload();
}

class Home extends StatefulWidget {
  const Home({super.key, int index = 0});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey _scaffoldKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  late MdStyleSheet _styleSheet;
  List<HomeItem> homeItems = [];

  late Future<bool> _dataLoaded;
  bool _sideDrawerLoaded = false;

  int _index = 0;

  /// _handleExternalScroll executes the scrolling of the page content triggered by
  /// the SideDrawer. The ItemScrollController sits in this, the target object. MapService()
  /// just holds the index as a ValueNotifier. It exposes a method - requestScroll(index) that is
  /// used by the SideDrawer to send the required position to scroll to. Being a ValueNotifier the
  /// value is picked up here as the receiver, and the controller scrolls to the required target.
  /// SideDrawer().scroll() --> MapService().requestScroll() --> HomePage()._handleExternalScroll()

  void _handleExternalScroll() {
    final index = MapService().scrollToSideDrawerIndex.value;
    if (index != null && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    MapService().scrollToSideDrawerIndex.addListener(_handleExternalScroll);
    if (MapService().homeController != null) {
      MapService().homeController!._addState(this);
    }
    _dataLoaded = _getHomeData();
    _styleSheet = MdStyleSheet();
  }

  @override
  void dispose() {
    MapService().scrollToSideDrawerIndex.removeListener(_handleExternalScroll);
    super.dispose();
  }

  Future<bool> _getHomeData() async {
    try {
      List<Map<String, dynamic>> items = await getMarkdownItems(type: 'home');
      for (int i = 0; i < items.length; i++) {
        homeItems.add(HomeItem.fromMap(map: items[i]));
      }
      _backdrop = homeItems.isEmpty ? _placeholderImage : null;
      if (homeItems.isNotEmpty) {
        mdData = homeItems[0].markdown;
        _styleSheet = MdStyleSheet.fromJson(json: homeItems[0].style);
      } else {
        // Nothing published yet: a welcome - to a club's pages, or Drives'.
        // (The clubs load at start-up, alongside this.)
        await ClubService()
            .known
            .timeout(const Duration(seconds: 5), onTimeout: () {});
        bool club = ClubService().inAnyClub &&
            ClubService().showing != ClubService().drives;
        mdData = club ? _clubWelcome : _drivesWelcome;
        homeItems = [
          club
              ? HomeItem(
                  heading: 'Welcome to Drives-AI Club edition',
                  subheading: ClubService().showingName,
                  markdown: mdData,
                  style: _styleSheet.toJson())
              : HomeItem(
                  heading: 'Drives trip planning app',
                  subheading: 'there is always somewhere to go',
                  markdown: mdData,
                  style: _styleSheet.toJson())
        ];
      }
    } catch (e) {
      developer.log('Error Home()._getHomeData() : ${e.toString()}',
          name: 'error');
      mdData = _unreachable;
      _backdrop = _placeholderImage;
      // a tile in the drawer too, as the welcome has
      homeItems = [
        HomeItem(
            heading: "Can't reach Drives",
            subheading: 'just now - check your connection',
            markdown: _unreachable,
            style: _styleSheet.toJson())
      ];
    }
    return true;
  }

  String mdData = '';

  /// The image behind the page while it has nothing published to show - the
  /// welcome, or can't reach Drives
  String? _backdrop;
  static const String _placeholderImage = 'assets/images/aiaston.png';

  /// The server couldn't be reached - so the page says so, rather than
  /// staying blank
  static const String _unreachable = '''

# Can't reach Drives just now

---

Check your connection - or the Drives server may be down for a moment.
This page fills in when Drives can be reached again.
''';

  /// Home with nothing published on Drives' own pages
  static const String _drivesWelcome = '''

# Drives Trip Planning and Sharing App

---

*A memorable drive is not just about reaching a destination, but all about enjoying the journey...*

**How many times on a beautiful day have you not known where to go?**

> Drives makes planning great trips easy

- Based on Open Street Maps data
- Published trips points of interest and good roads to download
- Publish your memorable trips points of interest and great stretches of road
- Create new trips linking published highlights and save them privately or share them
- Track your trip when you've been out exploring
- Powerful controllable routing engine - re-route only when you want to
- Turn-by-turn instructions with AI voice
- Support for groups with email or messaging for news invitations or just chat
- Group chat messaging and real time group tracking makes group trips easy
''';

  /// Home with nothing published yet on a club's pages - until its admin
  /// writes some
  static const String _clubWelcome = '''

# Welcome to Drives-AI Club edition

---

This trip planning app is designed for both individual club users and for group activities.

You can use it just for arranging nice trips out to recommend to your members, but it is invaluable for group trips. It manages the trip invitations and responses, and control of the group as the trip progresses. It tracks the position in real time of each member of the group, and can message them either individually or as a group during the trip.

Drives helps you organise your club communications. It can act as a blog updating users of upcoming events and club news. Its built-in instant messaging helps greatly with communicating with individual users, or groups of users.
''';

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      homeItems = [];
      _dataLoaded = _getHomeData();
    });
    await _dataLoaded;
    sideBarItems(force: true);
  }

  void updateData(Map<String, dynamic> data) {
    try {
      setState(() {
        mdData = data['data'] ?? '';
        _styleSheet = data['style'];
        _index = data['index'] ?? _index;
      });
    } catch (e) {
      developer.log('Home().updateData() error: ${e.toString()}',
          name: 'error');
    }
  }

  Widget _getPortraitBody() {
    double leftPadding =
        MediaQuery.of(context).size.width * (kIsWeb ? 0.38 : 0);
    return _page(leftPadding);
  }

  Widget _page(double leftPadding) {
    Widget page = MarkdownBody(
      data: mdData,

      ///
      /// by defalt = false Markdown expects two spaces for a line break
      softLineBreak: true,

      ///
      /// gitHubFlavored is essential to display tables checklists etc
      extensionSet: md.ExtensionSet.gitHubFlavored,

      ///
      /// inlineSyntaxes: define the match strings to allow MarkdownBody
      /// to recognise the block to be built with the builders
      inlineSyntaxes: [ShortcodeSyntax()], //, LineBreakSyntax()],
      ///
      /// The builders: when they find the inlineSyntaxes pattern will
      /// then convert the syntax to Dart
      builders: {
        'shortcode': SpaceShortcodeBuilder(),
      },

      ///
      /// imageBuilder: looks at the data: mdData and using the standard markdown
      /// syntax ![alt ](uri) executes this builder - the uri must be a valid uri.
      /// the alt is used to hold the caption, align, width and rotation.
      imageBuilder: (Uri uri, String? title, String? alt) =>
          imageBuilder(uri, title, alt),
      styleSheet: _backdrop == null
          ? _styleSheet.markdownStyleSheet
          : onImageStyleSheet(context),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding + 10, 5, 10, 5), //   all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(10.0)),
        child: Container(
          color: DrivesColours.current.panel,
          child: _backdrop == null
              ? Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: SingleChildScrollView(child: page),
                )
              : ImageBackdrop(
                  image: _backdrop!,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20), child: page),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();

    /// Ensure the Side Drawer is populated AFTER this screen is built.

    WidgetsBinding.instance.addPostFrameCallback((_) => sideBarItems());
    return Scaffold(
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      // The main drawer is on the shell Scaffold in main.dart
      //   appBar: kIsWeb
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            developer.log('Snapshot error: ${snapshot.error}', name: 'error');
            return Center(
                child: Text(
                    'Error getting the data from the server - check the Internet'));
          } else if (snapshot.hasData) {
            return _getPortraitBody();
          } else {
            return const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  /// force refills it when returning to Home - otherwise only the first
  /// build fills it, as build() calls this on every rebuild
  void sideBarItems({bool force = false}) async {
    FlutterNativeSplash.remove();
    await _dataLoaded;
    if (homeItems.isNotEmpty &&
        mounted &&
        kIsWeb &&
        (force || !_sideDrawerLoaded)) {
      MapService().sideDrawerController!.open();
      MapService()
          .sideDrawerController!
          .setContent(content: BottomDrawerItems.home, drawerItems: homeItems);
      MapService().sideDrawerController!.setFixed(fixed: true);
      MapService().sideDrawerController!.setVisible(visible: true);
      _sideDrawerLoaded = true;
    }
  }
}
