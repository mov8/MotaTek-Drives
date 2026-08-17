import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:drives/helpers/markdown_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/tiles/home_tile.dart';
import '/classes/classes.dart';
import '/services/services.dart' hide getPosition;
// import 'package:flutter/services.dart' show rootBundle;
import '/screens/screens.dart';
import '/helpers/helpers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final ImageRepository _imageRepository;
  final GlobalKey _scaffoldKey = GlobalKey();
  // final GlobalKey _homeItemKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  late final MdStyleSheet _styleSheet;

  // int _globalKeyIndex = -1;
  List<HomeItem> homeItems = [];
  final List<Widget> _sideBarContents = [];

  late Future<bool> _dataLoaded;

  List<Map<String, dynamic>> _images = [];

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
    _imageRepository = ImageRepository();
    _dataLoaded = _getHomeData();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  @override
  void dispose() {
    _imageRepository.clear();
    _sideBarContents.clear();
    MapService().scrollToSideDrawerIndex.removeListener(_handleExternalScroll);
    super.dispose();
  }

  /// _getHomeData() used to trigger FutureBuilder
  /// Has to be used in the initState() and the result used
  /// in the FutureBuilder
  /// It's going to see if the server is up, and if so copy all the
  /// home_page items into a local SQLite cache. The home_tile will
  /// read the data from the cache saving network traffic and ensuring
  /// seamless use when off-lime. It also allows the home_page to be
  /// displayed before the user has logged in.
  /// Once the user logs in it will check that all the home_item entries
  /// are up to date and will synchronise the cache with the API data.

  Future<bool> _getHomeData() async {
    bool apiUp = await apiListening();
    debugPrint('Api listeninig: ${apiUp.toString()}');
    // Setup().hasLoggedIn =
    if (Setup().jwt.isEmpty && mounted) {
      Setup().loggingIn = true;
      Login(context: context).tryLoggingIn().then((_) async {
        try {
          Setup().serverUp = true; // debug
        } catch (e) {
          debugPrint('error: ${e.toString()}');
        }
        if (Setup().serverUp) {
          homeItems = await getHomeItems(1);
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

        if (homeItems.isNotEmpty) {
          Setup().hasLoggedIn = true;
          getStats();
        } else {
          homeItems.add(HomeItem(
            id: -2,
            uri: 'assets/images',
            heading:
                'New trip planning app for individuals, groups of friends and clubs',
            subHeading: 'Stop polishing your car and start driving it...',
            body:
                '''Drives is a new app to help you make the most of the countryside around you. You can plan trips either on your own or you can explore in a group''',
            imageUrls: '[{"url": "assets/images/aiaston.png", "caption": ""}]',
          ));

          homeItems.add(
            HomeItem(
                id: -2,
                uri: 'assets/images',
                heading:
                    'Share your trips with friends, club members or publish them to everybody',
                subHeading:
                    'Let others know about your great trips, and download trips others have discovered already.',
                body:
                    '''Uploaded trips can be rated to let you know how much others enjoyed it. Waypoints like scenery, nice roads, pubs and restaurants can be rated too.''',
                imageUrls:
                    '[{"url": "assets/images/meeting.png", "caption": ""}]'), //CarGroup.png'),
          );
        }
      });

      // TODO: Get the markdown stylesheet from the api

      Map<String, dynamic> styleJson = {};

      _styleSheet = MdStyleSheet.fromJson(json: styleJson);
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
      //  homeItems = await loadHomeItems(); // get cached homeItems
      homeItems = await getHomeItems(1); // get API data
      Map<String, dynamic> styleJson = {};

      _styleSheet = MdStyleSheet.fromJson(json: styleJson);
      return true;
    }
  }

  Future<String> getFileData(String path) async {
    // return '';
    // return await rootBundle.loadString(path);
    return await DefaultAssetBundle.of(context).loadString(path);
  }

  String mdData = '''
# Drives Trip Planning and Sharing App
---

*A memorable drive is not just about reaching a destination, but all about enjoying the journey...*

**How many times on a beautiful day have you not known where to go?**

> Drives makes planning great trips easy

- Based on Open Street Maps data
- Publish and download memorable trips
- Publish points of interest and great stretches of road
- Create new trips linking published highlights
- Can track where you've been when out exploring
- Powerful controllable routing engine
- Turn-by-turn instructions with AI voice
- Discretionary re-routing
- Support for group drives
- Built in group chat messaging


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

  Widget _getPortraitBodyMd() {
    _textEditingController.value = TextEditingValue(
      text: mdData, // mdHelp
    );
    String data = _textEditingController.text;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 50), //   all(8.0),
        child: Center(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: data,
              imageBuilder: (Uri uri, String? title, String? alt) {
                String text = alt ?? '';

                String? getAttr(String key) {
                  final reg = RegExp('$key="([^":]+)"');
                  return reg.firstMatch(text)?.group(1);
                }

                developer.log('ImageShortCodeBuilder() called',
                    name: '_markdown_');
                final String? caption = getAttr('caption');
                final String align = getAttr('align') ?? 'center';
                final double rotation =
                    double.tryParse(getAttr('rotation') ?? '') ?? 0.0;
                final double width =
                    double.tryParse(getAttr('width') ?? '') ?? 300.0;

                bool cached = uri.toString() == 'cache';
                MainAxisAlignment mainAlign;
                switch (align) {
                  case 'left':
                    mainAlign = MainAxisAlignment.start;
                    break;
                  case 'right':
                    mainAlign = MainAxisAlignment.end;
                    break;
                  default:
                    mainAlign = MainAxisAlignment.center;
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: mainAlign,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: Transform.rotate(
                            angle: pi *
                                rotation, //2 pi radians = 360  widget.photos[i].rotation * 0.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cached
                                  ? Image.memory(
                                      _imageRepository.getBytes(
                                          key: _images[0]['key']),
                                      width: width,
                                      fit: BoxFit.contain,
                                      // Error handling is vital for Web/Mobile
                                      errorBuilder: (context, _, __) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : Image.network(
                                      uri.toString(),
                                      width: 200,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (caption != null) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Text(
                          caption,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ]
                  ],
                );
              },
              styleSheet: _styleSheet.markdownStyleSheet,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPortraitBodyMD1() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: Markdown(
          data: mdData,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black),
            h1: const TextStyle(
                color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(
                color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
            h3: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            h4: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            tableBody: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            tableHead: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            tableHeadAlign: TextAlign.start,
            blockquote: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            code: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        )

            /*FutureBuilder(
            future: getFileData('assets/markdown/markdown_source_data.md'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text('Loading Markdown Info...');
              } else if (snapshot.hasError) {
                return Text('Loading Markdown Failed!');
              }
              String data =   

              return 
              // Text('Markdown should be here!',
              //     style: TextStyle(fontSize: 22, color: Colors.red));
               Markdown(
                 data: snapshot.data!,
              //  selectable: true,
                 );
            },
          ), */
            ),
      ),
    );
  }

  Widget _getPortraitBodyMD2() {
    double leftPadding =
        MediaQuery.of(context).size.width * (kIsWeb ? 0.38 : 0);
    try {
      Widget form = Padding(
        padding: EdgeInsets.fromLTRB(leftPadding + 10, 5, 10, 5),
        child: // Card(
            ClipRRect(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(10.0)),
          //  child: Expanded(
          child: Container(
            color: const Color.fromRGBO(54, 143, 244, 0.411),
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
              // child: Expanded(
              child: Column(
                children: [
                  Card(
                    child: Column(
                      children: [
                        // Padding(
                        //   padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                        //  child:
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            'Drives',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            'the new free trip planning app',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          //   ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ScrollablePositionedList.builder(
                      itemCount: homeItems.length,
                      itemScrollController: _itemScrollController,
                      itemBuilder: (context, index) => HomeTile(
                        homeItem: homeItems[index],
                        imageRepository: _imageRepository,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // MapService().sideDrawerController!.setVisible(visible: true);
      return form;
    } catch (e) {
      developer.log(
          'Error Home().getPortraitBody() form error: ${e.toString()}',
          name: 'error');
      return Text('Its fallen over: ${e.toString()}');
    }
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
            return _getPortraitBodyMd();
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

  /// getSideDrawerTiles() generates the abbreviated tiles for the side drawer from
  /// the raw api data. This will be stored in the side drawer cache so that other
  /// data can be shown in the side drawer, and then the original data can be restored.

  List<Widget> getSideDrawerTiles() {
    _sideBarContents.clear();
    try {
      for (int i = 0; i < homeItems.length; i++) {
        _sideBarContents.add(
          getSideDrawerTile(
            key: Key('sdt$i'),
            homeItem: homeItems[i],
            index: i,
            onPress: (index) => MapService().requestScroll(index),
          ),
        ); //getContents(index)));
      }
    } catch (e) {
      developer.log('Error Home().getDrawerTiles(): ${e.toString()}',
          name: 'error');
    }
    return _sideBarContents;
  }

  Widget getSideDrawerTile(
      {required Key key,
      required HomeItem homeItem,
      required int index,
      required Function(int) onPress}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Card(
        key: key,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(5, 0, 0, 0),
          child: Row(
            children: [
              if (homeItem.getPhotos().isNotEmpty) ...[
                Expanded(
                  flex: 10,
                  //     alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: RotatedBox(
                      quarterTurns: homeItems[index].getPhotos().first.rotation,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadiusGeometry.all(Radius.circular(10.0)),
                        child: FutureBuilder(
                          future: getImageFromPhoto(
                              photo: homeItems[index].getPhotos().first,
                              imageRepository: _imageRepository),
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
                        homeItem.heading,
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        homeItem.subHeading,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      SizedBox(height: 20),

                      Text(
                        'published: ${dateFormatDoc.format(homeItem.added)}',
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

  Future<void> loadImage(int id) async {
    final ImagePicker picker = ImagePicker();
    final XFile? xImage = await picker.pickImage(source: ImageSource.gallery);
    if (xImage != null) {
      try {
        String name = '${getUuid()}.${xImage.name.split(".").last}';
        Uint8List bytes = await xImage.readAsBytes();
        var imageMap =
            await _imageRepository.loadImage(bytes: bytes, uri: name);
        // get the new key's value to access the image
        String key = imageMap.keys.first;
        _images.add({'name': name, 'key': key});
      } catch (e) {
        debugPrint('Error saving temporary image: ${e.toString()}');
      }
    }
  }

  void sideBarItems() async {
    await _dataLoaded;
    getSideDrawerTiles();
    if (_sideBarContents.isNotEmpty && mounted) {
      MapService().sideDrawerController!.open();
      MapService().sideDrawerController!.setContent(
          content: BottomDrawerItems.home, drawerItems: _sideBarContents);
      MapService().sideDrawerController!.setFixed(fixed: true);
      MapService().sideDrawerController!.setVisible(visible: true);
    }
  }
}
