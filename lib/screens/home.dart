import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import '/helpers/edit_helpers.dart';

class HomeForm extends StatefulWidget {
  const HomeForm({super.key, setup});
  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm> {
  late Future<bool> _dataloaded;
  List<HomeItem> _items = [];
  bool _expanded = false;
  int? _index;
  List<bool> _changes = [];
  bool _changed = false;
  String _prompt = 'Add, delete or edit page';
  HomeItemTileController? _activeController;

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

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    _items = await getHomeItems(1);
    if (_items.isEmpty) {
      newHomeItem();
    }
    for (int i = 0; i < _items.length; i++) {
      _changes.add(false);
    }
    return true;
  }

  expanded(int index, bool expanded, HomeItemTileController controller) {
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
          _prompt = 'Add, delete or edit page';
          _expanded = false;
          _index = null;
          _activeController = null;
        });
      }
    }
  }

  recordChange(int index) {
    _changes[index] = true;
    setState(() => _changed = true);
  }

  Widget portraitView() {
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
                    child: HomeItemTile(
                      homeItem: _items[index],
                      controller: HomeItemTileController(),
                      index: index,
                      onRated: (index, rate) => (),
                      onAddImage: (index) => loadImage(index),
                      onIconTap: (index) => (),
                      onSelect: (index) => postHomeItem(_items[index]),
                      onDelete: (index) => removeHomeItem(index),
                      onChange: (index) => recordChange(index),
                      onExpandChange: (open, controller) =>
                          expanded(index, open, controller),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(
        heading: 'Drives Home Contents',
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
        overflowPrompts:
            _expanded ? ['Delete page', 'Add image', 'Upload'] : ['Add page'],
        overflowMethods:
            _expanded ? [onDelete, onAddImage, onPost] : [newHomeItem],
        showOverflow: true,
        updateMethod: (update) => onPostAll(update),
      ),
      body: FutureBuilder<bool>(
        future: _dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitView();
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
          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  removeHomeItem(int index) async {
    await deleteHomeItem(_items[index]);
    _items.removeAt(index);
    if (_items.isEmpty) {
      newHomeItem();
    }
    setState(() => _expanded = false);
  }

  newHomeItem() {
    _items.add(
      HomeItem(
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''Drives is a new app to help you make the most of  the countryside around you. 
              You can plan trips either on your own or you can explore in a group''',
      ),
    );
  }

  loadImage(int index) async {
    _items[index].imageUrls = await loadDeviceImage(
        imageUrls: _items[index].imageUrls,
        itemIndex: index,
        imageFolder: 'home_page_item');
    setState(() => ());
  }

  Future<void> onDelete() async {
    _items.removeAt(_index!);
    _changes.removeAt(_index!);
    if (_items.isEmpty) {
      newHomeItem();
    }
    setState(() {
      _expanded = false;
      _index = null;
      _activeController = null;
    });
    return;
  }

  onAddImage() async {
    int taken = _items[_index!].imageUrls.countOccurrences('com.motatek') + 1;
    Photo? image =
        await getDeviceImage(folder: 'home_item', fileName: 'pic_$taken');
    if (image != null) {
      /// Don't need to specify endpoint as it's handled in the tile
      List<Photo> testPhotos =
          photosFromJson(photoString: _items[_index!].imageUrls);
      testPhotos.add(image);
      //  developer.log('before: ${_items[_index!].imageUrls}', name: 'photos_1');
      String testUri = photosToString(photos: testPhotos);
      _items[_index!].imageUrls = testUri;
      //  developer.log('after: ${_items[_index!].imageUrls}', name: 'photos_1');
    }

    debugPrint(_items[_index!].imageUrls.toString());
    setState(() => (_activeController!.updatePhotos()));
  }

  onPost() {
    try {
      postHomeItem(_items[_index!]);
      _changes[_index!] = false;
      for (int i = 0; i < _changes.length; i++) {
        _changed = _changes[i];
        if (_changed) {
          break;
        }
      }
    } catch (e) {
      debugPrint("Can't save ${_items[_index!].heading} - ${e.toString()}");
    }
  }

  onPostAll(bool save) {
    if (save) {
      for (int i = 0; i < _items.length; i++) {
        if (_changes[i]) {
          try {
            postHomeItem(_items[i]);
          } catch (e) {
            debugPrint("Can't save ${_items[i].heading} - ${e.toString()}");
          }
        }
      }
    }
  }
}
