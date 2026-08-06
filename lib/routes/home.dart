import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/tiles/home_tile.dart';
import '/classes/classes.dart';
import '/services/services.dart' hide getPosition;
import '/screens/screens.dart';
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

  // int _globalKeyIndex = -1;
  List<HomeItem> homeItems = [];
  final List<Widget> _sideBarContents = [];

  late Future<bool> _dataLoaded;

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
      return true;
      //   _bottomNavController.navigate();
    } else {
      //  homeItems = await loadHomeItems(); // get cached homeItems
      homeItems = await getHomeItems(1); // get API data
      return true;
    }
  }

  Widget _getPortraitBody() {
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
