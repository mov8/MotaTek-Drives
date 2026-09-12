import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import '/models/other_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '/classes/classes.dart';
import 'package:universal_io/universal_io.dart';
import 'package:intl/intl.dart';
import '/helpers/helpers.dart';
import '/constants.dart';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller
///
Map ShopMarkdownStyle = {
  // 'h1': TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold), //
  'h1': {'color': Colors.blue, 'fontSize': 24.0, 'fontWeight': FontWeight.bold},
  'h2': {'color': Colors.blue, 'fontSize': 22.0, 'fontWeight': FontWeight.bold},
  'h3': {
    'color': Colors.black,
    'fontSize': 20.0,
    'fontWeight': FontWeight.bold
  },
  'h4': {
    'color': Colors.black,
    'fontSize': 18.0,
    'fontWeight': FontWeight.bold
  },
  'tableHead': {
    'color': Colors.black,
    'fontSize': 18.0,
    'fontWeight': FontWeight.bold
  },
  'tableBody': {
    'color': Colors.black,
    'fontSize': 16.0,
    'fontWeight': FontWeight.bold
  },
  'tableAlign': TextAlign.start,
  'backquote': {
    'color': Colors.black,
    'fontSize': 20.0,
    'fontWeight': FontWeight.bold
  },
  'code': {
    'color': Colors.black,
    'fontSize': 16.0,
    'fontWeight': FontWeight.bold
  },
};

String mdShopData = '''

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

class ShopItemTileController {
  _ShopItemTileState? _shopItemTileState;

  void _addState(_ShopItemTileState shopItemTileState) {
    _shopItemTileState = shopItemTileState;
  }

  bool get isAttached => _shopItemTileState != null;
  void contract() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _shopItemTileState?.changeOpenState();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void updatePhotos() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _shopItemTileState?.getPhotos();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error getting photos: $err');
    }
  }
}

class ShopItemTile extends StatefulWidget {
//  final PointOfInterestController? pointOfInterestController;
  final ShopItem shopItem;
  final ShopItemTileController controller;
  final int index;
  final Function(int)? onIconTap;
  final Function(bool, ShopItemTileController)? onExpandChange;
  final Function(int)? onDelete;
  final Function(int)? onAddImage;
  final Function(int, int)? onRated;
  final Function(int)? onChange;
  final Function(int)? onSelect; // final Key key;
  final bool expanded;
  final bool canEdit;
  final bool code;

  ShopItemTile(
      {super.key,
      required this.index,
      required this.shopItem,
      required this.controller,
      this.onIconTap,
      this.onExpandChange,
      this.onDelete,
      this.onAddImage,
      this.onChange,
      this.onRated,
      this.expanded = false,
      this.canEdit = true,
      this.code = true,
      this.onSelect});
  @override
  State<ShopItemTile> createState() => _ShopItemTileState();
}

class _ShopItemTileState extends State<ShopItemTile> {
  late int index;
  int imageUrlLength = 0;
  int imageIndex = 0;
  bool expanded = true;
  bool canEdit = true;
  DateFormat dateFormat = DateFormat("dd MMM yy");
  TextEditingController _textEditingController = TextEditingController();
  FocusNode fn1 = FocusNode();
  List<Photo> photos = [];

  final List<String> covers = [
    'all',
    'North',
    'North West',
    'North East',
    'West',
    'East',
    'South',
    'South West',
    'South East'
  ];

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  final ExpansibleController _expansibleController = ExpansibleController();
  final ImageRepository _imageRepository = ImageRepository();

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    photos = photosFromJson(
      photoString: jsonEncode(widget.shopItem.images),
      endPoint: '$urlShopItem/images/${widget.shopItem.uri}/',
    );
    dropDownMenuItems = covers
        .map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        )
        .toList();
  }

  @override
  void dispose() {
    fn1.dispose();
    super.dispose();
  }

  changeOpenState() {
    if (widget.expanded) {
      debugPrint('Controller closing tile $index');
      _expansibleController.collapse();
    } else {
      debugPrint('tile $index is already closed - widget.expanded = false');
    }
  }

  getPhotos() {
    try {
      photos = photosFromJson(
        photoString: jsonEncode(widget.shopItem.images),
        endPoint: '$urlShopItem/images/${widget.shopItem.uri}/',
      );
      imageUrlLength = widget.shopItem.images!.length;
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shopItem.images!.length != imageUrlLength) {
      getPhotos();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: Markdown(
          data: mdShopData,
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
        )),
      ),
    );
  }

  save(int id) {
    if (widget.index == id) {
      expanded = false;
    }
  }

  onDeleteImage(int idx) {
    debugPrint('delete image $idx');
    setState(() => photos.removeAt(idx));
  }

  expand(bool state, bool canEdit) {
    expanded = state;
  }

  loadImage(int id) async {
    if (widget.index == id) {
      int imageCount = photos.length + 1;
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
          Photo newPhoto = Photo(
              url: name, caption: 'image $imageCount', rotation: 0, key: key);
          photos.add(newPhoto);
          _expansibleController.expand(); // <-- Stop keyboard closing
          setState(() => fn1.requestFocus());
        } catch (e) {
          debugPrint('Error saving temporary image: ${e.toString()}');
        }
      }
    }
  }

  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
        key: Key('sli$index'), width: 160, child: Image.file(File(url)));
  }

  changeRating(value) {
    widget.onRated!(value, widget.index);
    setState(() => widget.shopItem.score = value.toDouble());
  }
}
