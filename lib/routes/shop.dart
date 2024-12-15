import 'package:drives/services/services.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/classes/classes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _shopScreenState();
}

class _shopScreenState extends State<ShopScreen> {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  List<ShopItem> shopItems = [];

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = _getShopData();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<bool> _getShopData() async {
    if (!Setup().hasRefreshedShop && Setup().hasLoggedIn) {
      shopItems = await getShopItems(1);
      if (shopItems.isNotEmpty) {
        Setup().hasRefreshedShop = true;
        shopItems = await saveShopItemsLocal(shopItems);
      }
    } else {
      shopItems = await loadShopItems();
    }
    for (ShopItem shopItem in shopItems) {
      if (shopItem.url1.isNotEmpty) {
        shopItem.links = 1;
      }
      if (shopItem.url2.isNotEmpty) {
        shopItem.links = 2;
      }
    }
    return true;
  }

  Widget _getPortraitBody() {
    if (shopItems.isEmpty) {
      shopItems.add(
        ShopItem(
            id: -2,
            uri: 'assets/images/',
            heading: 'Promote your business, club or event.',
            subHeading: 'Target your audience precisely.',
            body:
                '''If you run a business or a club selling to motorists you can promote to them accurately.
  Audiences can be catigorised by car manufacturer, geographic region, club or group.''',
            imageUrls: '[{"url": "MobileMarketing.png", "caption": ""}]',
            url1: 'https://motatek.com/',
            buttonText1: 'Enquire Now'),
      );
    }
    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Offers for you',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
        /*  SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'the new free trip planning app',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),*/
      ])),
      for (int i = 0; i < shopItems.length; i++) ...[
        ShopTile(shopItem: shopItems[i])
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
            controller: _leadingWidgetController,
            onMenuTap: (index) =>
                _leadingWidget(_scaffoldKey.currentState)), // IconButton(
        title: const Text(
          'MotaTrip store',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
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
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        initialValue: 4,
        onMenuTap: (_) => {},
      ),
    );
  }
}
