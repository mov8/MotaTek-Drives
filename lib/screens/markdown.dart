import 'dart:typed_data';
import 'dart:math';
import 'dart:convert' show utf8;
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import '/routes/routes.dart';
import '/helpers/helpers.dart';

String mdData = '''
# Drives Free Trip Planning App
--- 

Name  | Favourite Colour
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
String mdHelp = '''
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

class MarkdownForm extends StatefulWidget {
  final Map<String, dynamic> markdownData;
  final String dataType;
  final String uri;
  const MarkdownForm({
    super.key,
    required this.markdownData,
    required this.dataType,
    this.uri = '',
  });
  @override
  State<MarkdownForm> createState() => _MarkdownFormState();
}

class _MarkdownFormState extends State<MarkdownForm> {
  // late Future<bool> _dataloaded;
  // List<MarkdownItem> _items = [];
  late Map<String, dynamic> _MarkdownItem;
  late MdStyleSheet _stylesheet;
  bool _expanded = false;
  int? _index;
  bool _code = true;
  List<bool> _changes = [];
  late Map<String, dynamic> _markdownData;
  List<Map<String, dynamic>> _images = [];
  // bool _changed = false;
  String _prompt = 'Add, delete or edit page';
  // MarkdownItemTileController? _activeController;
  final TextEditingController _textEditingController = TextEditingController();
  // final ImageRepository _imageRepository = ImageRepository();
  final LeadingWidgetController _leadingWidgetController =
      LeadingWidgetController();
  final SideToolbarController _sideToolBarController = SideToolbarController();
  final GlobalKey _scaffoldKey = GlobalKey();
  late final _controller;
  bool _hidden = true;
  List<String> _buffer = [];
  int _bufferIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = widget.dataType == 'shop'
        ? MapService().shopController
        : MapService().homeController;
    _stylesheet = _controller!.getStyle();

    _textEditingController.value =
        TextEditingValue(text: _controller!.getMarkdown() // mdHelp
            );
    _textEditingController.addListener(_lastCharacter);
    _markdownData = widget.markdownData;
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
    if (lastCharacter == " " ||
        _buffer.isEmpty ||
        lastCharacter == '\n' ||
        lastCharacter == '\t') {
      // save buffer for each new word and restrict buffer to 100 entries
      try {
        _controller?.update({
          'data': text,
          'style': _stylesheet,
          'images': _images
        }); // _styleSheet.toJson()});
        addToBuffer(text: text);
      } catch (e) {
        developer.log(
            'Markdown new word controller update error: ${e.toString()}',
            name: 'error');
      }
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
    _controller
        ?.update({'data': text, 'style': _stylesheet, 'images': _images});
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

/*
  Future<bool> dataFromWeb() async {
    try {
      _items = await getMarkdownItems(1);

      if (_items.isEmpty) {
        newMarkdownItem(mdData);
      }

      //  for (int i = 0; i < _items.length; i++) {
      //    if _items.
      //    _changes.add(false);
      //  }

      /// DEBUG - replace styleJson with json from api
      /// Each Markdown page content will have to have a stylesheet stored as json
      Map<String, dynamic> styleJson = {};

      _styleSheet = MdStyleSheet.fromJson(
          json: _items[0].style); // MdStyleSheet.fromJson(json: styleJson);
      _textEditingController.value = TextEditingValue(text: mdData);
    } catch (e) {
      developer.log('Error MarkdownForm().dataFromWeb(): ${e.toString()}',
          name: '_markdown_');
    }
    return true;
  }
*/
/*  
  expanded(int index, bool expanded, MarkdownItemTileController controller) {
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
        _prompt = 'Edit ${_MarkdownItem.heading}';
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
  */
/*
  recordChange(int index) {
    _changes[index] = true;
    setState(() => _changed = true);
  }
*/
  /// portraitView is a simple editor to allow the users to input markdown
  /// there is no syntax checking

  onUpdate(dynamic arg) {
    setState(() => _hidden = !_hidden);
  }

  onCodePressed() {
    setState(() => _code = !_code);
  }

  onRemovePressed() {
    /// Have to send the removed date to api and remove the item from MarkdownItems[]
  }

  onAddPressed() {
    /// Clear Markdown markdown and add new MarkdownItem() to MarkdownItems[]
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

  onUploadPressed() async {
    String data = _textEditingController.text;
    Map<String, dynamic> markdownItem =
        {}; // = MarkdownItem(heading: 'Heading', subheading: 'Subheading');
    if (data.isNotEmpty) {
      // final title = RegExp(r'#(.*)'); RegExp('$key="([^"]+)"')
      // r'#\s*(.*)' = lines with # followed by 0 or more spaces
      // with any character other than newline in group
      String? getAttr(String key) {
        final reg = RegExp('$key="([^"]+)"');
        return reg.firstMatch(data)?.group(1);
      }

      String? getUri() {
        /// regex means find the character group between '(cache/' and ')'
        /// \( = escaped  ( \s* = 0 or more spaces  cache/? = cache followed by 0 or 1 /
        /// (.*) = group of 0 or more of any character  \) = escaped )
        final reg = RegExp(r'\(\s*cache\/*(.*)\)');
        return reg.firstMatch(data)?.group(1);
      }

      final title = RegExp(r'#\s*(.*)');
      final match = title.allMatches(data);
      markdownItem['url'] = getUuid();
      markdownItem['heading'] = ' ';
      markdownItem['subheading'] = ' ';
      markdownItem['images'] = [];
      var matches = match.map((m) => m.group(0)).toList();
      if (matches.isNotEmpty) {
        markdownItem['heading'] = matches[0]!.split('#').last.trim();
        if (matches.length > 1) {
          markdownItem['subheading'] = matches[1]!.split('#').last.trim();
        }
      }
      if (data.isNotEmpty) {
        markdownItem['markdown'] = data;
        markdownItem['style'] = _stylesheet.toJson();
      }

      final image = RegExp(r'!\[alt\s*(.*)');
      final iMatch = image.allMatches(data);
      final iMatches = iMatch.map((i) => i.group(0)).toList();
      List<Map<String, dynamic>> images = [];
      if (iMatches.isNotEmpty) {
        for (int i = 0; i < iMatches.length; i++) {
          final String? src = getUri();
          final String? key = src?.split('.')[0];
          final String? caption = getAttr('caption');
          final String? align = getAttr('align');
          final int rotation = int.tryParse(getAttr('rotation') ?? '') ?? 0;
          final double width = double.tryParse(getAttr('width') ?? '') ?? 300;

          images.add({
            "url": src,
            "caption": caption,
            "align": align,
            "rotation": rotation,
            "width": width,
            "key": key
          });
        }
        markdownItem['images'] = images;
      }
      await postMarkdownItem(widget.uri, widget.dataType, markdownItem);
    }
  }

  Widget portraitView() {
    /// getButtons gets the contents of the SideToolbar that lets users change fonts etc
    MdStyleSheet style = MdStyleSheet();
    List<FormatEditor> buttons = getButtons(
        styleSheet: _stylesheet, onUpdate: onUpdate, hidden: _hidden);
    return SizedBox(
      height: MediaQuery.of(context).size.height - 250, //
      child: SingleChildScrollView(
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
      ),
    );
  }

  /// portraitViewMd displays the rendered markdown
  ///
  Widget portraitViewMd() {
    String data = _textEditingController.text;
    MdStyleSheet style = MdStyleSheet();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 50), //   all(8.0),
        child: Center(
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: data,
              //   extensionSet: customExtensionSet,
              imageBuilder: (Uri uri, String? title, String? alt) =>
                  imageBuilder(uri, title, alt),
              styleSheet: _stylesheet.markdownStyleSheet,
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
                }
              },
              child: Row(
                children: [e['iconData'], Text(e['text'])],
              ),
            ),
          )
          .toList(),
    );

    if (kIsWeb) {
      return ScreensAppBarBottom(
        prompt: 'Markdown - ${widget.dataType}',
        showAction: false, //true,
        overflowPrompts: [
          'Markdown help',
          'Image left',
          'Image centre',
          'Image right',
          'Style editor',
        ],
        overflowIcons: [
          Icon(Icons.help_outline_outlined,
              size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
          Icon(Icons.looks_one_outlined,
              size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
          Icon(Icons.looks_two_outlined,
              size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
          Icon(Icons.looks_3_outlined,
              size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
          Icon(Icons.line_style_outlined,
              size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
        ],
        overflowMethods: [
          () => setState(() => _sideToolBarController.close()),
          () => insertImage(orientation: 'left'),
          () => insertImage(orientation: 'centre'),
          () => insertImage(orientation: 'right'),
          () => setState(() => _hidden = false)
        ], // _expanded ? [addMember, editGroup] : [addGroup],
        showOverflow: true,
        actionButtons: getActionsButtons(
          code: _code,
          buffer: _buffer,
          overflow: overflow,
          addPressed: onAddPressed,
          removePressed: onRemovePressed,
          bufferIndex: _bufferIndex,
          codePressed: onCodePressed,
          undoPressed: onUndoPressed,
          redoPressed: onRedoPressed,
          uploadPressed: onUploadPressed,
        ),
        update: false,
        textColor: const Color.fromRGBO(1, 29, 51, 1),
        // updateMethod: (update) => (_) => (),
        content: portraitView(),
      );
    } else {
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
            'Markdown',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          toolbarHeight: 40,
          actions: getActionsButtons(
            code: _code,
            buffer: _buffer,
            overflow: overflow,
            bufferIndex: _bufferIndex,
            codePressed: onCodePressed,
            undoPressed: onUndoPressed,
            redoPressed: onRedoPressed,
            uploadPressed: onUploadPressed,
          ),
        ),
        body: _code
            ? portraitView()
            : portraitViewMd(), /*   FutureBuilder
          future: _dataloaded,
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              developer.log('Markdown() snapshot has error: ${snapshot.error}',
                  name: '_nav_');
            } else if (snapshot.hasData) {
              developer.log('Markdown() snapshot has data', name: '_nav_');
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
  */
      );
    }
  }

  /// The images will be stored on the api - /static/images/Markdown_page/user_id
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
        '![alt image:${_images.length} caption="image ${_images.length}" align="$orientation" width="200" rotation="0" ](cache/${_images.last['name'] ?? ' '})';
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

  removeMarkdownItem(int index) async {
    await deleteMarkdownItem(widget.dataType, widget.uri);
    // _items.removeAt(index);
    // if (_items.isEmpty) {
    //  newMarkdownItem(mdData);
    // }
    setState(() => _expanded = false);
  }

  newMarkdownItem(String mdData) async {
    final Map<String, dynamic> data;
    data = await shredMarkdown(markdown: mdData);
    MdStyleSheet stylesheet = MdStyleSheet();
    _markdownData = {
      'markdown': mdHelp,
      'heading': data['heading'],
      'subheading': data['subheading'],
      'images': data['images'],
      'style': stylesheet.toJson(),
    };
  }

  Future<void> onDelete() async {
    //   _items.removeAt(_index!);
    //   _changes.removeAt(_index!);
    //   if (_items.isEmpty) {
    newMarkdownItem(mdData);
    //   }
    setState(() {
      _expanded = false;
      _index = null;
      _controller = null;
    });
    return;
  }
/*
  onAddImage() async {
    int taken = _items[_index!].imageUrls.countOccurrences('com.motatek') + 1;
    Photo? image =
        await getDeviceImage(folder: 'Markdown_item', fileName: 'pic_$taken');
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
  onMarkdown() => setState(() => _code = false);
  onHelp() async {}
  onPost() {
    try {
      postMarkdownItem(_items[_index!]);
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
  */

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
        var imageMap = await MarkdownService()
            .imageRepository
            .loadImage(bytes: bytes, uri: name);
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
      postMarkdownItem(widget.uri, widget.dataType, _markdownData);
      /* for (int i = 0; i < _items.length; i++) {
        if (_changes[i]) {
          try {
            postMarkdownItem(_items[i]);
          } catch (e) {
            debugPrint("Can't save ${_items[i].heading} - ${e.toString()}");
          }
        } 
      } */
    }
  }
}
