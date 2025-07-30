import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/services/services.dart';
import 'dart:developer' as developer;

class ShopForm extends StatefulWidget {
  // var setup;

  const ShopForm({super.key, setup});

  @override
  State<ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<ShopForm> {
  late Future<bool> _dataloaded;
  List<ShopItem> _items = [];
  int _action = 0;
  int _index = 0;
  int toInvite = 0;
  bool _expanded = false;

  final List<String> _titles = [
    "Shop page adverts",
    "Ad - ",
  ];

  @override
  void initState() {
    super.initState();
    // _dataloaded = dataFromDatabase();
    _dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    super.dispose();
  }

  Future<bool> dataFromWeb() async {
    _items = await getShopItems(0);
    if (_items.isEmpty) {
      newItem();
    }

    return true;
  }

  Widget portraitView({required BuildContext context}) {
    return Column(children: [
      Expanded(
        child: Column(
          children: [
            if (_items.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5.0),
                    child: ShopItemTile(
                      shopItem: _items[index],
                      index: index,
                      onExpandChange: (index) => expandCallBack(index),
                      onRated: (index, rate) => rating(rate, index),
                      onIconTap: (index) => callBack(index),
                      onAddImage: (index) => onAddImage(index),
                      //    onRemoveImage: (index, imageIndex) =>
                      //        onRemoveImage(index, imageIndex),
                      onAddLink: (index) => onAddLink(index),
                      onPost: (index) => onPost(index),
                      onDelete: (index) => onDelete(index),
                    ),
                  ),
                ),
              )
            ],
            if (!_expanded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Wrap(
                  spacing: 10,
                  children: [
                    ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => setState(() => newItem()),
                      backgroundColor: Colors.blue,
                      avatar: const Icon(
                        Icons.group_add,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'New Item', // - ${_action.toString()}',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            //       Align(
            //         alignment: Alignment.bottomLeft,
            //         child: _handleChips(),
            //       )
          ],
        ),
      )
    ]);
  }

  void callBack(int index) {
    debugPrint('Callback index: $index');
  }

  void expandCallBack(int index) {
    setState(() => _expanded = !_expanded);
  }

  void rating(int rate, int index) {
    debugPrint('Callback index: $index rating: $rate');
  }

  @override
  Widget build(BuildContext context) {
    // _action = 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives Shop Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              _items.isEmpty ? 'Add a ne promotion' : _items[_index].heading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            if (--_action >= 0) {
              setState(() {});
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: FutureBuilder<bool>(
        future: _dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitView(context: context);
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
          throw ('Error - FutureBuilder shop.dart');
        },
      ),
    );
  }

  Future<void> onDelete(int index) async {
    _items.removeAt(index);
    if (_items.isEmpty) {
      newItem();
    }
    setState(() => _expanded = false);
    developer.log('onAddImage', name: '_callback');
    return;
  }

  newItem() {
    _items.add(
      ShopItem(
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''Drives is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        links: 0,
      ),
    );
  }

  onAddImage(int index) async {
    _items[index].imageUrls = await loadDeviceImage(
        imageUrls: _items[index].imageUrls,
        itemIndex: index,
        imageFolder: 'shop_item');
    developer.log(_items[index].imageUrls, name: '_callback');
    setState(() => ());
  }

  onAddLink(int index) {
    developer.log('onAddLink', name: '_callback');
    setState(() => _items[index].links =
        _items[index].links < 2 ? ++_items[index].links : _items[index].links);
  }

  onPost(int index) {
    developer.log('onPost', name: '_callback');
    postShopItem(_items[index]);
  }

  void onSelect(int index) {
    developer.log('onSelect', name: '_callback');
  }
}
