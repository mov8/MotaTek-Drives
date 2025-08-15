import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/services/services.dart';

class HomeForm extends StatefulWidget {
  const HomeForm({super.key, setup});
  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm> {
  late Future<bool> _dataloaded;
  List<HomeItem> _items = [];
  bool _expanded = false;

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
    return true;
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
                      index: index,
                      onRated: (index, rate) => (),
                      onAddImage: (index) => loadImage(index),
                      onIconTap: (index) => (),
                      onSelect: (index) => postHomeItem(_items[index]),
                      onDelete: (index) => removeHomeItem(index),
                      onExpandChange: (idx) =>
                          setState(() => _expanded = idx != -1),
                    ),
                  ),
                ),
              )
            ],
            Align(
              alignment: Alignment.bottomLeft,
              child: _handleChips(),
            )
          ],
        ),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives News Items',
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
              "Home page articles",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(onPressed: () => Navigator.pop(context)),
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

  Widget _handleChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Wrap(
        spacing: 10,
        children: [
          if (!_expanded) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => newHomeItem()),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.note_add_sharp,
                color: Colors.white,
              ),
              label: const Text(
                'New home page article', // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ],
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
}
