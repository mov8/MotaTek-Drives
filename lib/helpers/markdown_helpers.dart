import 'dart:typed_data' as dt;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:developer' as developer;
import '../constants.dart';

class ShortcodeSyntax extends md.InlineSyntax {
  // This Regex looks for {{< image ... >}}
  // It allows for optional spaces and matches everything inside the brackets
  ShortcodeSyntax() : super(r'\{\{<\s*(image.*?)\s*>\}\}');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // match[1] is the part inside the braces: "image src='...'"
    // We create a custom element called 'shortcode'
    final element = md.Element('shortcode', [md.Text(match[1]!)]);

    parser.addNode(element);
    return true;
  }
}

class ImageShortcodeBuilder extends MarkdownElementBuilder {
  ImageShortcodeBuilder();
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String text = element.textContent;
    developer.log('ImageShortCodeBuilder() called', name: '_markdown_');
    dt.Uint8List? image;
    String? getAttr(String key) {
      final reg = RegExp('$key="([^"]+)"');
      return reg.firstMatch(text)?.group(1);
    }

    developer.log('ImageShortCodeBuilder() called', name: '_markdown_');
    final String? src = getAttr('src');
    final String align = getAttr('align') ?? 'center';
    final double width = double.tryParse(getAttr('width') ?? '') ?? 300.0;

    String key = '';

    developer.log(
        'ImageShortCodeBuilder() src ${src == null ? "is null" : "isn't null"}',
        name: '_markdown_');

    if (src == null) return null;
    // Handle Alignment
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

    return Row(
      mainAxisAlignment: mainAlign,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            image!,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => const Icon(Icons.broken_image),
          ),
        ),
      ],
    );
  }
}

/// Creates the list of TextStyle attributes as a list of CompactDropdowns
/// It also updates the MarkdownStylesheet
List<CompactDropdown> dropdownsTextStyle(
    String styleKey, MdStyleSheet styleSheet) {
  TextStyle textStyle = styleSheet.getTextStyle(key: styleKey);

  /// Ensure the single instance of MarkdownStyle is updated
  onChanged(value, key) {
    developer.log('dropdownsTextStyle($styleKey).onChaged($value $key) called',
        name: '_tools_');

    switch (key) {
      case 'fontSize':
        {
          textStyle = textStyle.copyWith(
              fontSize: fontSize.values
                  .toList()[fontSize.keys.toList().indexOf(value)]);
          break;
        }
      case 'fontStyle':
        {
          textStyle = textStyle.copyWith(
              fontStyle: fontStyle.values
                  .toList()[fontStyle.keys.toList().indexOf(value)]);
          break;
        }
      case 'fontWeight':
        {
          textStyle = textStyle.copyWith(
              fontWeight: fontWeight.values
                  .toList()[fontWeight.keys.toList().indexOf(value)]);
          break;
        }
      case 'color':
        {
          textStyle = textStyle.copyWith(
              color:
                  colour.values.toList()[colour.keys.toList().indexOf(value)]);
          break;
        }
    }
    styleSheet.updateTag(
        tag: {'$styleKey': textStyle}); // <-- tag is Map<key TextStyle>
  }

  return [
    CompactDropdown(
      heading: 'font size',
      styleKey: 'fontSize',
      value: fontSize.keys.toList()[fontSize.values
          .toList()
          .indexOf(textStyle.fontSize ?? fontSize.values.toList().first)],
      items: fontSize.keys.toList(),
      width: 80,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'font style',
      styleKey: 'fontStyle',
      value: fontStyle.keys.toList()[fontStyle.values
          .toList()
          .indexOf(textStyle.fontStyle ?? fontStyle.values.toList().first)],
      items: fontStyle.keys.toList(),
      width: 80,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'font weight',
      styleKey: 'fontWeight',
      value: fontWeight.keys.toList()[fontWeight.values
          .toList()
          .indexOf(textStyle.fontWeight ?? fontWeight.values.toList().first)],
      items: fontWeight.keys.toList(),
      width: 80,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'colour',
      styleKey: 'color',
      value: colour.keys.toList()[colour.values
          .toList()
          .indexOf(textStyle.color ?? colour.values.toList().first)],
      items: colour.keys.toList(),
      width: 80,
      onChanged: onChanged,
    ),
  ];
}

class CompactDropdown<T> extends StatefulWidget {
  T value;
  List<T> items;
  double width;
  Function(T?, String) onChanged;
  Widget Function(T)? renderChild;
  String heading;
  String suffix;
  String styleKey;
  CompactDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.width,
    required this.onChanged,
    this.renderChild,
    required this.heading,
    this.suffix = "",
    this.styleKey = "",
  });
  @override
  State<CompactDropdown> createState() => _CompactDropdownState();
}

class _CompactDropdownState<T> extends State<CompactDropdown<T>> {
  late T _value;
  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: DropdownButtonHideUnderline(
        // <--- REMOVES BORDER
        child: DropdownButton<T>(
          value: _value,
          isDense: true, // <--- REDUCES SPACE
          isExpanded: true, // <--- ALLOWS TEXT TO TAKE ALL WIDTH
          onChanged: changed, // onChanged,
          menuMaxHeight: 400,
          dropdownColor: const Color.fromRGBO(88, 1, 250, 0.336),
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white), // Smaller font for web/dialogs
          items: widget.items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: widget.renderChild != null
                  ? widget.renderChild!(item)
                  : Text("${item.toString().split('.').last}${widget.suffix}"),
            );
          }).toList(),
        ),
      ),
    );
  }

  void changed(value) {
    developer.log('Compact().onChanged value: $value', name: '_tools_');
    setState(() => _value = value);
    widget.onChanged(value, widget.styleKey);
  }
}

class MdStyleSheet extends StatelessWidget {
  MarkdownStyleSheet? markdownStyleSheet = MarkdownStyleSheet();
  MdStyleSheet({super.key, MarkdownStyleSheet? styleSheet})
      : markdownStyleSheet = styleSheet ?? MarkdownStyleSheet();
  factory MdStyleSheet.fromJson({required json}) {
    MarkdownStyleSheet styleSheet = markdownStyleSheetFromJson();
    return MdStyleSheet(styleSheet: styleSheet);
  }

  @override
  Widget build(BuildContext context) {
    return Text('');
  }

  MarkdownStyleSheet styleSheetFromJson({required String json}) {
    MarkdownStyleSheet mdStyleSheet = markdownStyleSheet!.copyWith();
    return mdStyleSheet;
  }

  dynamic toJson() {
    Map<String, dynamic> jsonStyle = {
      'p': markdownStyleSheet!.p ??
          TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.bold),
      'blockquoteAlign':
          markdownStyleSheet!.blockquoteAlign ?? WrapAlignment.end,
      'blockquotePadding': markdownStyleSheet!.blockquotePadding ??
          EdgeInsets.fromLTRB(20, 0, 80, 0), //    (16),
      'h1': markdownStyleSheet!.h1 ??
          TextStyle(
              color: Colors.blue,
              fontSize: 24,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.bold),
      'h2': markdownStyleSheet!.h2 ??
          TextStyle(
              color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
      'h3': markdownStyleSheet!.h3 ??
          TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      'h4': markdownStyleSheet!.h4 ??
          TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      'tableBody': markdownStyleSheet!.tableBody ??
          TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      'tableHead': markdownStyleSheet!.tableHead ??
          TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      'tableHeadAlign': markdownStyleSheet!.tableHeadAlign ?? TextAlign.start,
      'blockquote': markdownStyleSheet!.blockquote ??
          TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      'checkbox': markdownStyleSheet!.checkbox ??
          TextStyle(
              color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
      'listBullet': markdownStyleSheet!.listBullet ??
          TextStyle(
              color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
      'code': markdownStyleSheet!.code ??
          TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    };
    return jsonStyle;
  }

  /// Update the StyleSheet elements from the editors. The tags can't be updated directly as the
  /// fields are all final. Have to convert to json then update then convert back,
  updateTag({required Map<String, dynamic> tag}) {
    dynamic jsonStyle = toJson();
    jsonStyle[tag.keys.first] = tag.values.first;
    markdownStyleSheet = markdownStyleSheetFromJson(jsonStyle: jsonStyle);
  }

  TextStyle getTextStyle({required String key}) {
    return toJson()[key];
  }
}

MarkdownStyleSheet markdownStyleSheetFromJson(
    {Map<String, dynamic>? jsonStyle}) {
  jsonStyle ??= {};
  return MarkdownStyleSheet(
    p: jsonStyle['p'] ??
        TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal),
    h1: jsonStyle['h1'] ??
        TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.bold),
    h2: jsonStyle['h2'] ??
        TextStyle(
            color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
    h3: jsonStyle['h3'] ??
        TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    h4: jsonStyle['h4'] ??
        TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    tableBody: jsonStyle['tableBody'] ??
        TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    tableHead: jsonStyle['tableHead'] ??
        TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    tableHeadAlign: jsonStyle['tableHeadAlign'] ?? TextAlign.start,
    blockquote: jsonStyle['blockQuote'] ??
        TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    code: jsonStyle['code'] ??
        TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    checkbox: jsonStyle['checkbox'] ??
        TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    listBullet: jsonStyle['listBullet'] ??
        TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    listBulletPadding: EdgeInsets.fromLTRB(0, 5, 5, 0),
  );
}

List<Widget> getActions(
    {bool code = true,
    List<String>? buffer,
    int bufferIndex = -1,
    PopupMenuButton? overflow,
    codePressed,
    undoPressed,
    redoPressed}) {
  buffer ??= [];
  return [
    IconButton(
      onPressed: codePressed,
      icon: Icon(
        code ? Icons.code_off : Icons.code,
      ),
    ),
    if (code == true) ...[
      IconButton(
        onPressed: () => {},
        icon: Icon(
          Icons.upload,
        ),
      ),
      IconButton(
        icon: Icon(
          Icons.undo_outlined,
          color: buffer.isEmpty || bufferIndex == buffer.length - 1
              ? Colors.grey
              : Colors.white,
        ),
        onPressed: undoPressed,
      ),
      IconButton(
        icon: Icon(
          Icons.redo_outlined,
          color:
              buffer.isEmpty || bufferIndex <= 0 ? Colors.grey : Colors.white,
        ),
        onPressed: redoPressed,
      ),
      if (overflow != null) overflow
      /*   PopupMenuButton(
        itemBuilder: (context) => markdownOptions
            .map<PopupMenuEntry<String>>(
              (e) => PopupMenuItem(
                textStyle: TextStyle(fontSize: 18, color: Colors.black),
                onTap: overflowTap(e['value']),

                /* () async {
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
                */
                child: Row(
                  children: [e['iconData'], Text(e['text'])],
                ),
              ),
            )
            .toList(),
      ), */
    ],
  ];
}

List<Map<String, dynamic>> markdownOptions = [
  {
    'text': ' Markdown help',
    'iconData': const Icon(Icons.help_outline_outlined,
        size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
    'value': 'help'
  },
  {
    'text': ' Image to left',
    'iconData': Icon(Icons.looks_one_outlined,
        //   Icon(IconData(0xeeaf, fontFamily: 'MaterialIcons'), //   looks_one,
        size: 30,
        color: Color.fromRGBO(22, 20, 20, 1)),
    'value': 'imageLeft'
  },
  {
    'text': ' Image centre',
    'iconData': const Icon(Icons.looks_two_outlined,
        size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
    'value': ' imageCentre'
  },
  {
    'text': 'Image right',
    'iconData': const Icon(Icons.looks_3_outlined,
        size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
    'value': 'imageRight'
  },
  {
    'text': 'Style editor',
    'iconData': const Icon(Icons.line_style_outlined,
        size: 30, color: Color.fromRGBO(22, 20, 20, 1)),
    'value': 'style'
  },
];
