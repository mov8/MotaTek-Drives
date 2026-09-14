import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
// import 'package:drives/helpers/markdown_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
// import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:markdown/markdown.dart' as md;
import '/constants.dart';
import '/models/other_models.dart';
// import '/tiles/shop_tile.dart';
import '/classes/classes.dart';
import '/services/services.dart' hide getPosition;
// import 'package:flutter/services.dart' show rootBundle;
import '/screens/screens.dart';
import '/helpers/helpers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ShopController {
  _ShopState? _shopState;
  void _addState(_ShopState shopState) {
    _shopState = shopState;
  }

  bool get isAttached => _shopState != null;

  void update(Map<String, dynamic> data) {
    if (isAttached) {
      _shopState?.updateData(data);
    }
  }

  int get index => _shopState!._index;
  String getMarkdown() => _shopState!.mdData;
  MdStyleSheet getStyle() => _shopState!._styleSheet;
}

class Shop extends StatefulWidget {
  // final ShopController? controller = MapService().shopController;
  const Shop({super.key});
  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  // late final ImageRepository _imageRepository;
  final GlobalKey _scaffoldKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  late MdStyleSheet _styleSheet;
  List<ShopItem> shopItems = [];
  final List<Widget> _sideBarContents = [];
  int _index = 0;
  late Future<bool> _dataLoaded;

  List<Map<String, dynamic>> _images = [];

  /// _handleExternalScroll executes the scrolling of the page content triggered by
  /// the SideDrawer. The ItemScrollController sits in this, the target object. MapService()
  /// just holds the index as a ValueNotifier. It exposes a method - requestScroll(index) that is
  /// used by the SideDrawer to send the required position to scroll to. Being a ValueNotifier the
  /// value is picked up here as the receiver, and the controller scrolls to the required target.
  /// SideDrawer().scroll() --> MapService().requestScroll() --> ShopPage()._handleExternalScroll()

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
    _styleSheet = MdStyleSheet();
    // _imageRepository = ImageRepository();
    if (MapService().shopController != null) {
      MapService().shopController!._addState(this);
    }
    _dataLoaded = _getShopData();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  @override
  void dispose() {
    // _imageRepository.clear();
    _sideBarContents.clear();
    MapService().scrollToSideDrawerIndex.removeListener(_handleExternalScroll);
    super.dispose();
  }

  /// _getShopData() used to trigger FutureBuilder
  /// Has to be used in the initState() and the result used
  /// in the FutureBuilder
  /// It's going to see if the server is up, and if so copy all the
  /// shop_page items into a local SQLite cache. The shop_tile will
  /// read the data from the cache saving network traffic and ensuring
  /// seamless use when off-lime. It also allows the shop_page to be
  /// displayed before the user has logged in.
  /// Once the user logs in it will check that all the shop_item entries
  /// are up to date and will synchronise the cache with the API data.

  Future<bool> _getShopData() async {
    try {
      List<Map<String, dynamic>> items = await getMarkdownItems(type: 'shop');
      for (int i = 0; i < items.length; i++) {
        shopItems.add(ShopItem.fromMap(map: items[i]));
      }
      if (shopItems.isNotEmpty) {
        mdData = shopItems[0].markdown;
        _styleSheet = MdStyleSheet.fromJson(json: shopItems[0].style);
      }
    } catch (e) {
      developer.log('Error Shop()_getShopData() : ${e.toString()}',
          name: 'error');
    }
    return true;
  }

  String mdData3 = '''

# Drives Marketplace   

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

# Drives Marketplace
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

# Special new offers

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

  void updateData(Map<String, dynamic> data) {
    try {
      setState(() {
        _index = data['index'] ?? _index;
        mdData = data['data'] ?? '';
        _styleSheet = data['style'] ?? _styleSheet;
        _images = data['images'] ?? _images;
        //   MdStyleSheet.fromJson(json: data['style'] ?? _styleSheet.toJson());
      });
    } catch (e) {
      developer.log('Shop().updateData() error: ${e.toString()}',
          name: 'error');
    }
  }

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
                extensionSet: md.ExtensionSet.gitHubFlavored,
                builders: {
                  /// shortcode is the parser name in ShortcodeSyntax()
                  'shortcode': SpaceShortcodeBuilder(),
                },
                inlineSyntaxes: [ShortcodeSyntax()],
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
            debugPrint('Snapshot error: ${snapshot.error}');
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
              initialValue: 4,
              onMenuTap: (_) => {}),
    );
  }

  void sideBarItems() async {
    await _dataLoaded;
    if (shopItems.isNotEmpty && mounted) {
      MapService().sideDrawerController!.open();
      MapService()
          .sideDrawerController!
          .setContent(content: BottomDrawerItems.shop, drawerItems: shopItems);
      MapService().sideDrawerController!.setFixed(fixed: true);
      MapService().sideDrawerController!.setVisible(visible: true);
    }
  }
}
