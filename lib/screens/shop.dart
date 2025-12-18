import 'package:drives/helpers/edit_helpers.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart';
import '/services/services.dart';

class ShopForm extends StatefulWidget {
  // var setup;

  const ShopForm({super.key, setup});

  @override
  State<ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<ShopForm> {
  late Future<bool> _dataloaded;
  List<ShopItem> _items = [];
  int? _index;
  int toInvite = 0;
  bool _expanded = false;
  String _prompt = 'Add, delete or edit promotions';
  bool _changed = false;
  final List<bool> _changes = [];
  ShopItemTileController? _activeController = ShopItemTileController();

  @override
  void initState() {
    super.initState();
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
    for (int i = 0; i < _items.length; i++) {
      _changes.add(false);
    }
    return true;
  }

  /// expanded() is a bit tricky so for example
  /// The state needed is that only one tile is ever expanded
  /// A single controller for all tiles just doesn't work
  /// A list of controllers is problematic too as when the tile
  /// goes out of view it gets disposed of
  /// The answer is to create a controller instance for each tile
  /// as created, and hand that controller back to the parent when
  /// the expansionChange callback triggers. The parent can then
  /// use the controller to close the open tile if another one
  /// has been opened.

  expanded(int index, bool expanded, ShopItemTileController controller) {
    if (expanded) {
      try {
        _activeController?.contract();
      } catch (_) {
        debugPrint('Contract() failed');
      }
      setState(() {
        _index = index;
        _activeController = controller;
        _expanded = true;
        _prompt = 'Edit ${_items[index].heading}';
      });
    } else {
      if (index == _index) {
        // closing open tile
        setState(() {
          _prompt = 'Add, delete or edit promotions';
          _expanded = false;
          _index = null;
          _activeController = null;
        });
      }
    }
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
                      controller: ShopItemTileController(),
                      index: index,
                      onExpandChange: (open, controller) =>
                          expanded(index, open, controller),
                      onRated: (index, rate) => rating(rate, index),
                      onChange: (index) => setState(() {
                        _changes[index] = true;
                        _changed = true;
                      }),
                      expanded: index == _index,
                    ),
                  ),
                ),
              )
            ],
          ],
        ),
      )
    ]);
  }

  void rating(int rate, int index) {
    debugPrint('Callback index: $index rating: $rate');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(
        heading: 'Drives Shop Contents',
        prompt: _prompt,
        updateHeading: 'You have edited details.',
        updateSubHeading: 'Save or Ignore changes',
        update: _changed,
        showAction: _changed,
        overflowIcons: _expanded
            ? [
                Icon(Icons.delete),
                Icon(Icons.image),
                Icon(Icons.add_link),
                Icon(Icons.upload)
              ]
            : [Icon(Icons.post_add)],
        overflowPrompts: _expanded
            ? ['Delete promotion', 'Add image', 'Add link', 'Upload']
            : ['Add promotion'],
        overflowMethods:
            _expanded ? [onDelete, onAddImage, onAddLink, onPost] : [newItem],
        showOverflow: true,
        updateMethod: (update) => onPostAll(update),
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

  Future<void> onDelete() async {
    if (_items[_index!].uri.isNotEmpty) {
      try {
        deleteShopItem(shopUri: _items[_index!].uri);
      } catch (e) {
        debugPrint("Can't delete promotion");
      }
    }
    _items.removeAt(_index!);
    _changes.removeAt(_index!);
    if (_items.isEmpty) {
      newItem();
    }
    setState(() {
      _expanded = false;
      _index = null;
      _activeController = null;
    });
    return;
  }

  newItem() {
    _items.add(
      ShopItem(
        heading: 'Product being promoted...',
        subHeading: 'Product tag line...',
        body: 'The benefits of the item being promoted...',
        links: 0,
      ),
    );
    setState(() => _changes.add(false));
  }

  onAddImage() async {
    int taken = _items[_index!].imageUrls.countOccurrences('com.motatek') + 1;
    Photo? image =
        await getDeviceImage(folder: 'shop_item', fileName: 'promo_$taken');
    if (image != null) {
      List<Photo> photos =
          photosFromJson(photoString: _items[_index!].imageUrls);
      photos.add(image);
      String newUri = photosToString(photos: photos);
      _items[_index!].imageUrls = newUri;
    }

    debugPrint(_items[_index!].imageUrls.toString());
    setState(() => (_activeController!.updatePhotos()));
  }

  onAddLink() {
    _items[_index!].links = _items[_index!].links < 2
        ? ++_items[_index!].links
        : _items[_index!].links;
    _activeController!.addLink();
  }

  onPost() {
    bool isChanged = false;
    try {
      postShopItem(_items[_index!]);
      _changes[_index!] = false;
      for (int i = 0; i < _changes.length; i++) {
        isChanged = _changes[i];
        if (isChanged) {
          break;
        }
      }
    } catch (e) {
      debugPrint("Can't save ${_items[_index!].heading} - ${e.toString()}");
    }
    setState(() => _changed = isChanged);
  }

  onPostAll(bool save) {
    if (save) {
      for (int i = 0; i < _items.length; i++) {
        if (_changes[i]) {
          try {
            postShopItem(_items[i]);
          } catch (e) {
            debugPrint("Can't save ${_items[i].heading} - ${e.toString()}");
          }
        }
      }
      setState(() => _changed = false);
    }
  }
}
