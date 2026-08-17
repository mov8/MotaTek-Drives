import 'dart:typed_data';
import 'dart:math';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import '/helpers/helpers.dart';

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


> [!INFO]  Callout ?                                                                                   


sentence with a footnote. [^1] 

- [x] **First line**
- [ ] Second line
- [ ] Third line

this is a ==highlight==

this is a ~subscript~ 

1. **Ordered 1**
2. Ordered 2
3. Ordered 3

- **Unordered 1**
- Unordered 2
- Unordered 3

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

/// Four tabs appear to work as a line break
String mdShopHelp = '''
# Markdown syntax 
---
| Element | Syntax |
|----------|-----------------------------------|
|Headings  | `# H1  ## H2          ### H3 #### H4`|
|Bold | ` **bold text** `|
|Italic | ` *italicised text* `|
|Blockquote | ` > blockquote `|
|Ordered List | `1. First Item        2. Second Item`|
|Unordered List | `- First Item       - Second Item `|
|Horizontal Rule | `---`|
|Link | ` [title](https://www.example.com) `|
|Check List | ` - [x] Item 1        - [ ] Item 2 `|
|Table | `!Col 1 !Col 2 !       !------!-------!        !text 1!text 2!       !text 3! text 4!`|
|Line break| `four       tabs`|

''';

class ShopForm extends StatefulWidget {
  const ShopForm({super.key, setup});
  @override
  State<ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<ShopForm> {
  late Future<bool> _dataloaded;
  List<ShopItem> _items = [];
  bool _expanded = false;
  int? _index;
  bool _code = true;
  List<bool> _changes = [];
  List<Map<String, dynamic>> _images = [];
  bool _changed = false;
  String _prompt = 'Add, delete or edit page';
  ShopItemTileController? _activeController;
  final TextEditingController _textEditingController = TextEditingController();
  final ImageRepository _imageRepository = ImageRepository();
  final LeadingWidgetController _leadingWidgetController =
      LeadingWidgetController();
  final SideToolbarController _sideToolBarController = SideToolbarController();
  final GlobalKey _scaffoldKey = GlobalKey();
  late MdStyleSheet _styleSheet;
  bool _hidden = true;
  List<String> _buffer = [];
  int _bufferIndex = -1;

  @override
  void initState() {
    super.initState();
    _dataloaded = dataFromWeb();

    _textEditingController.value = TextEditingValue(
      text: mdData, // mdHelp
    );

    _textEditingController.addListener(_lastCharacter);

    //  _textEditingController.text = mdData;
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _textEditingController.dispose();
    super.dispose();
  }

  void _lastCharacter() {
    final text = _textEditingController.text;
    final selection = _textEditingController.selection;
    if (text.isEmpty || !selection.isCollapsed || selection.end <= 0) {
      return;
    }
    String lastCharacter = text.characters.elementAt(selection.end - 1);
    if (lastCharacter == " " || _buffer.isEmpty) {
      // save buffer for each new word and restrict buffer to 100 entries
      addToBuffer(text: text);
      developer.log('buffer length:${_buffer.length}', name: '_tools_');
    }
  }

  Map<String, dynamic> textStyle = {
    'color': Colors.blue,
    'fontSize': 24,
    'fontWeight': FontWeight.bold,
    'fontStyle': FontStyle.normal,
  };

  void addToBuffer({String? text}) {
    text ??= _textEditingController.text;
    setState(() {
      _buffer.insert(0, text!);
      if (_buffer.length == 101) {
        _buffer.removeAt(100);
        _bufferIndex = 0;
      }
    });
  }

  Map<String, dynamic> mdStyle = {
    'caption': 'body',
    'attribute': 'p',
    'textStyle': {
      'color': Colors.blue,
      'fontSize': 24,
      'fontWeight': FontWeight.bold,
      'fontStyle': FontStyle.normal,
    }
  };
  List<Map<String, dynamic>> msStyles = [];

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    _items = await getShopItems(1);
    if (_items.isEmpty) {
      newShopItem();
    }

    for (int i = 0; i < _items.length; i++) {
      _changes.add(false);
    }

    /// DEBUG - replace styleJson with json from api
    /// Each shop page content will have to have a stylesheet stored as json
    Map<String, dynamic> styleJson = {};

    _styleSheet = MdStyleSheet.fromJson(json: styleJson);

    return true;
  }

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

  /// portraitView is a simple editor to allow the users to input markdown
  /// there is no syntax checking

  onUpdate(dynamic arg) {
    setState(() => _hidden = !_hidden);
  }

  onCodePressed() {
    setState(() => _code = !_code);
  }

  onUndoPressed() {
    if (_bufferIndex < _buffer.length) {
      _bufferIndex++;
      setState(() => _textEditingController.value =
          TextEditingValue(text: _buffer[_bufferIndex]));
    }
  }

  onRedoPressed() {
    if (_bufferIndex > 0) {
      _bufferIndex--;
      setState(() => _textEditingController.value =
          TextEditingValue(text: _buffer[_bufferIndex]));
    }
  }

  Widget portraitView() {
    List<FormatEditor> buttons = getButtons(
        styleSheet: _styleSheet, onUpdate: onUpdate, hidden: _hidden);
    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      "Enter Markdown - use the Markdown help from the overflow options menu...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
                controller: _textEditingController,
                minLines: 50,
                maxLines: null,
                expands: false,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ),
          for (int i = 0; i < buttons.length; i++) ...[
            Positioned(
              top: 10 +
                  (buttons[i].height * i) -
                  (i == 0 ? 0 : (buttons[1].height - buttons[0].height)),
              right: 5,
              child: buttons[i],
            )
          ],
        ],
      ),
    );
  }

  /// portraitViewMd displays the rendered markdown
  ///
  Widget portraitViewMd() {
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

  @override
  Widget build(BuildContext context) {
    PopupMenuButton overflow = PopupMenuButton(
      itemBuilder: (context) => markdownOptions
          .map<PopupMenuEntry<String>>(
            (e) => PopupMenuItem(
              textStyle: TextStyle(fontSize: 18, color: Colors.black),
              onTap: () async {
                debugPrint('Admin Option: ${e['text']}');
                if (e['value'] == 'help') {
                  setState(() => _sideToolBarController.close());
                } else if (e['value'] == 'imageLeft') {
                  insertImage(orientation: 'left');
                } else if (e['value'] == 'imageCentre') {
                  insertImage(orientation: 'centre');
                } else if (e['value'] == 'imageRight') {
                  insertImage(orientation: 'right');
                } else if (e['value'] == 'style') {
                  setState(() => _hidden = false);
                  //  markdownStyleDialog(context);
                }
              },
              child: Row(
                children: [e['iconData'], Text(e['text'])],
              ),
            ),
          )
          .toList(),
    );

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Shop',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        toolbarHeight: 40,
        actions: getActions(
          code: _code,
          buffer: _buffer,
          overflow: overflow,
          bufferIndex: _bufferIndex,
          codePressed: onCodePressed,
          undoPressed: onUndoPressed,
          redoPressed: onRedoPressed,
        ),
      ),
      body: FutureBuilder<bool>(
        future: _dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            developer.log('Shop() snapshot has error: ${snapshot.error}',
                name: '_nav_');
          } else if (snapshot.hasData) {
            developer.log('Shop() snapshot has data', name: '_nav_');
            return _code ? portraitView() : portraitViewMd();
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
          return Center(
            child: Text(
              'FutureBuilder failed',
              style: TextStyle(fontSize: 25, color: Colors.red),
            ),
          );
          // throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  /// The images will be stored on the api - /static/images/shop_page/user_id
  /// The images will have the user_id added in the api - not before
  /// The images will be held in _imageRepository until they are uploaded
  /// The reference to the image is held in _images name is the filename.
  /// The image is referenced in the markdown as _images[index+1]
  /// orientation is taken from the option chosen from the overflow menu,
  /// and the rotation is in radians atm.

  Future<void> insertImage({String orientation = 'centre'}) async {
    await loadImage(-1);
    _images.last['orientation'] = orientation;
    final text = _textEditingController.text;
    final selection = _textEditingController.selection;
    int start = selection.baseOffset;
    if (start < 0) start = text.length;
    //  _imageRepository.loadImage()
    addToBuffer(text: text);
    final insertion =
        '![alt image:${_images.length} caption="image ${_images.length}" align="$orientation" width="200" rotation="0" ](cache)';
    //  '{{< image src= repository/${_images.last["key"]} align="$orientation" width="250"}}';
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      insertion,
    );
    _textEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + insertion.length));
    addToBuffer();
  }

  removeShopItem(int index) async {
    await deleteShopItem(_items[index]);
    _items.removeAt(index);
    if (_items.isEmpty) {
      newShopItem();
    }
    setState(() => _expanded = false);
  }

  newShopItem() {
    _items.add(
      ShopItem(
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''Drives is a new app to help you make the most of  the countryside around you. 
              You can plan trips either on your own or you can explore in a group''',
      ),
    );
  }

  Future<void> onDelete() async {
    _items.removeAt(_index!);
    _changes.removeAt(_index!);
    if (_items.isEmpty) {
      newShopItem();
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
        await getDeviceImage(folder: 'shop_item', fileName: 'pic_$taken');
    if (image != null) {
      /// Don't need to specify endpoint as it's handled in the tile
      List<Photo> testPhotos =
          photosFromJson(photoString: _items[_index!].imageUrls);
      testPhotos.add(image);
      String testUri = photosToString(photos: testPhotos);
      _items[_index!].imageUrls = testUri;
    }

    debugPrint(_items[_index!].imageUrls.toString());
    setState(() => (_activeController!.updatePhotos()));
  }

  onMarkdown() => setState(() => _code = true);
  onShop() => setState(() => _code = false);
  onHelp() async {}
  onPost() {
    try {
      postShopItem(_items[_index!]);
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

  /// Handling images:
  /// User selects image from gallery - image remains in _imageRepository
  /// User saves the Markdown image gets uploaded to api
  /// The Markdown identifier holds the api url and position metadata
  /// On viewing the Markdown the image gets pulled from api and rendered
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
    }
  }
}
