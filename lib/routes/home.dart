import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '/constants.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/services/services.dart' hide getPosition;
import '/screens/screens.dart';
import '/helpers/helpers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
}

class Home extends StatefulWidget {
  const Home({super.key, int index = 0});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  late MdStyleSheet _styleSheet;
  List<HomeItem> homeItems = [];
  //final List<Widget> _sideBarContents = [];

  late Future<bool> _dataLoaded;
  bool _sideDrawerLoaded = false;
  int _index = 0;

  // List<Map<String, dynamic>> _images = [];

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
    _bottomNavController = RoutesBottomNavController();
    _leadingWidgetController = LeadingWidgetController();
    if (MapService().homeController != null) {
      MapService().homeController!._addState(this);
    }
    _dataLoaded = _getHomeData();
    _styleSheet = MdStyleSheet();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  @override
  void dispose() {
    // _sideBarContents.clear();
    MapService().scrollToSideDrawerIndex.removeListener(_handleExternalScroll);
    super.dispose();
  }

  Future<bool> _getHomeData() async {
    try {
      List<Map<String, dynamic>> items = await getMarkdownItems(type: 'home');
      for (int i = 0; i < items.length; i++) {
        homeItems.add(HomeItem.fromMap(map: items[i]));
      }
      if (homeItems.isNotEmpty) {
        mdData = homeItems[0].markdown;
        _styleSheet = MdStyleSheet.fromJson(json: homeItems[0].style);
      } else {
        homeItems = [
          HomeItem(
              heading: 'Drives trip planning app',
              subheading: 'there is always somewhere to go',
              markdown: mdData,
              style: _styleSheet.toJson())
        ];
      }
    } catch (e) {
      developer.log('Error Shop()_getShopData() : ${e.toString()}',
          name: 'error');
    }
    return true;
  }

  String markdown = '''

# Drives Trip Planning and Sharing App  

---

*A memorable drive is not just about reaching a destination, but all about enjoying the journey...*

**How many times on a beautiful day have you not known where to go?**

> Drives makes planning great trips easy

- Based on Open Street Maps data
- Published trips points of interest and good roads to download
- Publish your memorable trips points of interest and great stretches of road
- Create new trips linking published highlights and save them privately or share them
- Track your trip whn you've been when out exploring
- Powerful controllable routing engine - re-route only when you want to
- Turn-by-turn instructions with AI voice
- Support for groups with email or messaging for news invitations or just chat
- Group chat messaging and real time group tracking makes group trips easy
''';

  String mdData = '''

# Drives Free Trip Planning App
--- 

Name  | Favorite Color
------------- | -------------
Rooney  | Red
Fred  | Blue
Lisa  | Yellow
Kyle  | Maroon
Sammy  | Blue
  
> blockquote  


>[!INFO]  
>Callout  


  ---

# My New Blog Post

### What I did today!
#### *December 25, 2020*
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

---

# My Second post about new code!
**Check out this code snippet**

``` dart 
main() {
  var poemLines = lines(poem);
  print(yell(poemLines.first));

  // functions are first-class
  var whisper = (String str) => str.toLowerCase();
  print(poemLines.map(whisper).last);
}
```
''';

  String mdData2 = '''

# Drives Free Trip Planning App
--- 

Name  | Favorite Color
------------- | -------------
Rooney  | Red
Fred  | Blue
Lisa  | Yellow
Kyle  | Maroon
Sammy  | Blue
  
> blockquote  


>[!INFO]  
>Callout  


  ---

# My New Blog Post

### What I did today!
#### *December 25, 2020*
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

---

# My Second post about new code!
**Check out this code snippet**

``` dart 
main() {
  var poemLines = lines(poem);
  print(yell(poemLines.first));

  // functions are first-class
  var whisper = (String str) => str.toLowerCase();
  print(poemLines.map(whisper).last);
}
```
''';

// homeItems.clear();

  void updateData(Map<String, dynamic> data) {
    try {
      setState(() {
        mdData = data['data'] ?? '';
        _styleSheet = data['style'];
        //  MdStyleSheet.fromJson(json: data['style']);
        _index = data['index'] ?? _index;
      });
    } catch (e) {
      developer.log('Home().updateData() error: ${e.toString()}',
          name: 'error');
    }
  }

  // BuildContext pageContext = NavigationService().pageKey.currentContext!;
  Widget _getPortraitBody() {
    double leftPadding =
        MediaQuery.of(context).size.width * (kIsWeb ? 0.38 : 0);
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding + 10, 5, 10, 5), //   all(8.0),
      child: // Card(
          ClipRRect(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(10.0)),
        child: Container(
          color: const Color.fromRGBO(54, 143, 244, 0.411),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: SingleChildScrollView(
              child: MarkdownBody(
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
                styleSheet: _styleSheet.markdownStyleSheet,
              ),
            ),
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
      drawer: const MainDrawer(),
      appBar: kIsWeb
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: LeadingWidget(
                  controller: _leadingWidgetController,
                  onMenuTap: (index) =>
                      _leadingWidget(_scaffoldKey.currentState)), // IconButton(
              title: const Text(
                'Drives trip planning and sharing app',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.blue,
              actions: [
                IconButton(
                  onPressed: () => {},
                  icon: Icon(
                    Icons.help_outline_outlined,
                  ),
                )
              ],
            ),
      body: FutureBuilder<bool>(
        //  initialData: false,
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
      bottomNavigationBar: kIsWeb
          ? null
          : RoutesBottomNav(
              controller: _bottomNavController,
              initialValue: 0,
              onMenuTap: (_) => {}),
    );
  }

  void sideBarItems() async {
    await _dataLoaded;
    if (homeItems.isNotEmpty && mounted && !_sideDrawerLoaded) {
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
