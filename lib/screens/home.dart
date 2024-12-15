import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/models/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:drives/services/services.dart';

class HomeForm extends StatefulWidget {
  // var setup;

  const HomeForm({super.key, setup});

  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm> {
  int _groupIndex = 0;
  late Future<bool> _dataloaded;
  List<HomeItem> _items = [];
  List<EventInvitation> _invitees = [];
  int _action = 0;
  int _index = 0;
  // bool _adding = false;
  // bool _expanded = false;
  int toInvite = 0;

  String _alterDriveId = '';

  final List<String> _titles = [
    "Home page articles",
    "Article - ",
    "Trips I've saved to share",
  ];

  // List<GroupMember> allMembers = [];
  // List<MyTripItem> _myTripItems = [];

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

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    _items = await getHomeItems(0);
    if (_items.isEmpty) {
      _items.add(
        HomeItem(
          heading: 'New trip planning app',
          subHeading: 'Stop polishing your car and start driving it...',
          body: '''MotaTrip is a new app to help you make the most of 
              the countryside around you. 
              You can plan trips either on your own or you can explore 
              in a group''',
          //  imageUrl:
          //      '[{"url": "assets/images/splash.png","caption":"image 1"}]'),
        ),
      );

      //  _items.add(HomeItem(heading: ''));
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
                      onExpandChange: (index) => expandCallBack(index),
                      onRated: (index, rate) => rating(rate, index),
                      onIconTap: (index) => callBack(index),
                      onSelect: (index) {
                        setState(() {
                          _groupIndex = index;
                          _action = 1;
                        });
                      },
                      onDelete: (idx) => deleteTrip(idx),
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

  void callBack(int index) {
    debugPrint('Callback index: $index');
  }

  void expandCallBack(int index) {
    setState(() {
      _action = _action == 1 ? 0 : 1;
      _index = _action == 0 ? -1 : index;
    });
    debugPrint('Callback index: $index');
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
          'MotaTrip News Items',
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
              '${_titles[_action]}${_action == 1 ? ' ${_items[_groupIndex].heading}' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 10,
        children: [
          if (_action == 0) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() => _action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.note_add_sharp,
                color: Colors.white,
              ),
              label: const Text(
                'New Item', // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
          if (_action == 1) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => loadImage(_index), //_action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.image,
                color: Colors.white,
              ),
              label: const Text(
                "Image", // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => loadImage(_index), //_action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              label: const Text(
                "Delete", // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => postHomeItem(_items[_index]), //_action = 2),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.cloud_upload,
                color: Colors.white,
              ),
              label: const Text(
                "Upload", // - ${_action.toString()}',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  loadImage(int id) async {
    try {
      ImagePicker picker = ImagePicker();
      await //ImagePicker()
          picker.pickImage(source: ImageSource.gallery).then(
        (pickedFile) async {
          try {
            if (pickedFile != null) {
              final directory = (await getApplicationDocumentsDirectory()).path;

              /// Don't know what type of image so have to get file extension from picker file
              int num = 1;
              if (_items[id].imageUrls.isNotEmpty) {
                /// count number of images
                num = '{'.allMatches(_items[id].imageUrls).length + 1;
              }
              debugPrint('Image count: $num');
              String imagePath =
                  '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
              File(pickedFile.path).copy(imagePath);
              setState(() {
                _items[id].imageUrls =
                    '[${_items[id].imageUrls.isNotEmpty ? '${_items[id].imageUrls.substring(1, _items[id].imageUrls.length - 1)},' : ''}{"url":"$imagePath","caption":"image $num"}]';
                debugPrint('Images: $widget.pointOfInterest.images');
              });
            }
          } catch (e) {
            String err = e.toString();
            debugPrint('Error getting image: $err');
          }
        },
      );
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}
