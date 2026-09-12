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

class ShopController {
  _ShopState? _shopState;

/*
  void _addState(_ShopState shopState) {
    _shopState = shopState;
  }
*/
  void _addState(_ShopState, shopState) {
    _shopState = shopState;
  }

  bool get isAttached => _shopState != null;

  int get index => _shopState!._index;

  void update(Map<String, dynamic> data) {
    _shopState?.updateData(data);
  }

  String getMarkdown() => _shopState!.mdData;
  MdStyleSheet getStyle() => _shopState!._styleSheet;
}

class Shop extends StatefulWidget {
  const Shop({super.key, int index = 0});
  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  late MdStyleSheet _styleSheet;
  List<ShopItem> shopItems = [];
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

    if (MapService().shopController != null) {
      //  MapService().shopController!._addState();
    }
    _dataLoaded = _getShopData();
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

  Future<bool> _getShopData() async {
    try {
      List<Map<String, dynamic>> items = await getMarkdownItems(type: 'shop');
      for (int i = 0; i < items.length; i++) {
        shopItems.add(ShopItem.fromMap(map: items[i]));
      }
      mdData = shopItems[0].markdown;
    } catch (e) {
      developer.log('Error Shop()_getShopData() : ${e.toString()}',
          name: 'error');
    }
    if (shopItems.isEmpty) {
      shopItems = [
        ShopItem(
            heading: 'Drives trip planning app',
            subheading: 'there is always somewhere to go',
            markdown: mdData,
            style: _styleSheet.toJson())
      ];
    }
    return true;
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
/*
  Future<bool> _getShopData() async {
    bool apiUp = await apiListening();
    developer.log('Api listening: ${apiUp.toString()}', name: '_markdown_');
    // Setup().hasLoggedIn =
    // List<ShopItem> = [];
    /// nested function to return a [empty ShopItem]
    List<ShopItem> getShopItemList() {
      // Map<String, dynamic> style = {};
      try {
        if (shopItems.isEmpty) {
          final items = shredMarkdown(markdown: mdData);
          //   style = Map<String, dynamic>.from(_styleSheet.toJson());
          shopItems.add(ShopItem(
            markdown: mdData,
            heading: items['heading'],
            subheading: items['subheading'],
            style: _styleSheet.toJson(),
            images: [],
          )
              // style: style),
              );
        }
      } catch (e) {
        developer.log(
            '_getShopData() error: ${e.toString()} ', // type:${style.runtimeType}',
            name: '_markdown_');
      }

      return shopItems;
    }

//
    if (Setup().jwt.isEmpty && mounted) {
      Setup().loggingIn = true;
      Login(context: context).tryLoggingIn().then((_) async {
        /// ShopItem() contains the markdown and the style
        if (Setup().serverUp) {
          shopItems = await getShopItems(1);
        } // get API data

        /// If the app hangs sometimes it's
        /// due to getting the current position have to restart the
        /// phone

        Setup().lastPosition = await getPosition();
        if (Setup().appState.isEmpty) {
          Setup().bottomNavIndex = 0;
        } else {
          Setup().bottomNavIndex = jsonDecode(Setup().appState)['route'] ?? 0;
        }

        if (shopItems.isNotEmpty) {
          Setup().hasLoggedIn = true;
          getStats();
        } else {
          shopItems.add(ShopItem(
            style: {},
          ));
        }
      });

      // todo - Get the markdown stylesheet from the api

      _styleSheet = MdStyleSheet.fromJson(json: shopItems[0].style);

      if (shopItems.isEmpty) {
        try {
          shopItems = getShopItemList();
        } catch (e) {
          developer.log('Error getShopItemList(): ${e.toString()}',
              name: '_markdown_');
        }
      }
      return true;
    } else if (Setup().bottomNavIndex > 0) {
      // Look to see if the app was left open
      _bottomNavController.setValue(Setup().bottomNavIndex);
      // Setup().appState = "{route: 2, trip_id: 233}";
      if (Setup().appState == '') {
        Setup().bottomNavIndex = 0;
      } else {
        Setup().bottomNavIndex = jsonDecode(Setup().appState)['route'] ?? 0;
      }
      Setup().setupToDb();
      Map<String, dynamic> styleJson = {};
      _styleSheet = MdStyleSheet.fromJson(json: styleJson);
      return true;
      //   _bottomNavController.navigate();
    } else {
      //  shopItems = await loadShopItems(); // get cached shopItems
      shopItems = await getShopItems(1); // get API data
      Map<String, dynamic> styleJson = {};

      _styleSheet = MdStyleSheet.fromJson(json: styleJson);
      if (shopItems.isEmpty) {
        try {
          shopItems = getShopItemList();
        } catch (e) {
          developer.log('Error getShopItemList(): ${e.toString()}',
              name: '_markdown_');
        }
      }
      return true;
    }
  }

  Future<String> getFileData(String path) async {
    // return '';
    // return await rootBundle.loadString(path);
    return await DefaultAssetBundle.of(context).loadString(path);
  }
*/
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

// shopItems.clear();

  void updateData(Map<String, dynamic> data) {
    try {
      setState(() {
        mdData = data['data'] ?? '';
        _styleSheet = data['style'];
        //  MdStyleSheet.fromJson(json: data['style']);
        _index = data['index'] ?? _index;
      });
    } catch (e) {
      developer.log('Shop().updateData() error: ${e.toString()}',
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

/*
  Widget getSideDrawerTile(
      {required Key key,
      required ShopItem shopItem,
      required int index,
      required Function(int) onPress}) {
    final String imageString = (shopItems[index].images ?? '').toString();
    Map<String, dynamic> imageMap = {};
    if (imageString.isNotEmpty) {
      imageMap = jsonDecode(imageString);
    }
    developer.log('getSideDrawerTile() called', name: '_markdown_');
    return Padding(
      padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Card(
        key: key,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(5, 0, 0, 0),
          child: Row(
            children: [
              if (imageString.isNotEmpty) ...[
                Expanded(
                  flex: 10,
                  //     alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: RotatedBox(
                      quarterTurns: int.tryParse(imageMap['rotation'] ?? '0')!,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadiusGeometry.all(Radius.circular(10.0)),
                        child: FutureBuilder(
                          future: getImageFromPhoto(
                              photo: Photo(
                                  url: imageMap['url'],
                                  align: imageMap['align'],
                                  width: imageMap['width'],
                                  caption: imageMap['caption'],
                                  rotation: imageMap[
                                      'rotation']), // shopItems[index].getPhotos().first,
                              imageRepository:
                                  MarkdownService().imageRepository),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const ImageMissing(width: 150);
                            } else if (snapshot.hasData) {
                              return snapshot.data!;
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                flex: 10,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 5, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopItem.heading,
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        shopItem.subheading,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      SizedBox(height: 20),

                      Text(
                        'published: ${dateFormatDoc.format(shopItem.added)}',
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ), // DateFormat('E dd/MM/yyyy')
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 2, 0),
                  child: IconButton(
                    onPressed: () {
                      onPress(index);
                    },
                    icon: Icon(Icons.arrow_circle_right_outlined, size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
*/
  /* Future<void> loadImage(int id) async {
    final ImagePicker picker = ImagePicker();
    final XFile? xImage = await picker.pickImage(source: ImageSource.gallery);
    if (xImage != null) {
      try {
        String name = '${getUuid()}.${xImage.name.split(".").last}';
        Uint8List bytes = await xImage.readAsBytes();
        var imageMap = await MarkdownService()
            .imageRepository
            .loadImage(bytes: bytes, uri: name);
        // get the new key's value to access the image
        String key = imageMap.keys.first;
        _images.add({'name': name, 'key': key});
      } catch (e) {
        debugPrint('Error saving temporary image: ${e.toString()}');
      }
    }
  }
*/
  void sideBarItems() async {
    await _dataLoaded;
    if (shopItems.isNotEmpty && mounted && !_sideDrawerLoaded) {
      MapService().sideDrawerController!.open();
      MapService()
          .sideDrawerController!
          .setContent(content: BottomDrawerItems.shop, drawerItems: shopItems);
      MapService().sideDrawerController!.setFixed(fixed: true);
      MapService().sideDrawerController!.setVisible(visible: true);
      _sideDrawerLoaded = true;
    }
  }
}
