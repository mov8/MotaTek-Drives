import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:developer' as developer;
import '../constants.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/screens/main_drawer.dart';
import '/tiles/tiles.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ImageRepository _imageRepository = ImageRepository();
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<ShopItem> shopItems = [];

  final List<Widget> _sideBarContents = [];

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Make the navigation bar transparent
        systemNavigationBarColor: Colors.transparent,
        // Ensure the navigation bar icons are visible
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    MapService().scrollToSideDrawerIndex.addListener(_handleExternalScroll);
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = _getShopData();
  }

  @override
  void dispose() {
    _imageRepository.clear();
    MapService().scrollToSideDrawerIndex.removeListener(_handleExternalScroll);
    super.dispose();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<bool> _getShopData() async {
    if (Setup().hasLoggedIn) {
      //!Setup().hasRefreshedShop && Setup().hasLoggedIn) {
      shopItems = await getShopItems(1);
      if (shopItems.isNotEmpty) {
        Setup().hasRefreshedShop = true;
      }
    }
    for (ShopItem shopItem in shopItems) {
      if (shopItem.url1.isNotEmpty) {
        shopItem.links = 1;
      }
      if (shopItem.url2.isNotEmpty) {
        shopItem.links = 2;
      }
    }
    if (shopItems.isEmpty) {
      shopItems.add(
        ShopItem(
            id: -2,
            uri: 'assets/images',
            heading: 'Promote your business, club or event.',
            subHeading: 'Target your audience precisely.',
            body:
                '''If you run a business or a club selling to motorists you can promote to them accurately. Audiences can be catigorised by car manufacturer, geographic region, club or group.''',
            imageUrls:
                '[{"url": "assets/images/MobileMarketing.png", "caption": ""}]',
            url1: 'https://motatek.com/',
            buttonText1: 'Enquire Now'),
      );
    }
    return true;
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
                            'Shop',
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
                            'offers for you to purchase and help support the Drives community.',
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
                      itemCount: shopItems.length,
                      itemScrollController: _itemScrollController,
                      itemBuilder: (context, index) => ShopTile(
                        shopItem: shopItems[index],
                        imageRepository: _imageRepository,
                      ),
                    ),
                  ),
                ],
              ), // */
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
                'Drives store',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                    onPressed: () => {},
                    icon: Icon(Icons.help_outline_outlined))
              ],
              backgroundColor: Colors.blue,
            ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            developer.log(
                'FutureBuilder - shopItems.length: ${shopItems.length}',
                name: '_shop');
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
          throw ('Error - FutureBuilder in main.dart');
        },
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : RoutesBottomNav(
              controller: _bottomNavController,
              initialValue: 4,
              onMenuTap: (_) => {},
            ),

      // ),
    );
  }

  /// getSideDrawerTiles() generates the abbreviated tiles for the side drawer from
  /// the raw api data. This will be stored in the side drawer cache so that other
  /// data can be shown in the side drawer, and then the original data can be restored.

  List<Widget> getSideDrawerTiles() {
    _sideBarContents.clear();
    try {
      for (int i = 0; i < shopItems.length; i++) {
        _sideBarContents.add(
          getSideDrawerTile(
            key: Key('sdt$i'),
            shopItem: shopItems[i],
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
      required ShopItem shopItem,
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
              if (shopItem.getPhotos().isNotEmpty) ...[
                Expanded(
                  flex: 10,
                  //     alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: RotatedBox(
                      quarterTurns: shopItems[index].getPhotos().first.rotation,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadiusGeometry.all(Radius.circular(10.0)),
                        child: FutureBuilder(
                          future: getImageFromPhoto(
                              photo: shopItems[index].getPhotos().first,
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
                        shopItem.heading,
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        shopItem.subHeading,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      SizedBox(height: 20),

                      Text(
                        'published: ${dateFormatDoc.format(shopItem.added ?? DateTime.now())}',
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
