import 'dart:typed_data' as dt;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:developer' as developer;
import '/classes/classes.dart';
import '/services/services.dart';
import '../constants.dart';

/// shredMarkdown() returns a Map<String, dynamic>:
/// {'title': String, 'subtitle': String, images: List<Map<String, dynamic>}
/// images '{"url": "$src", "caption": "$caption", "align": "$align", "rotation": $rotation, "width": $width, "key": "$key"}');

Future<Map<String, dynamic>> shredMarkdown({required String markdown}) async {
  Map<String, dynamic> elements = {
    'heading': 'Heading',
    'subheading': 'Subheading',
    'images': []
  };
  if (markdown.isNotEmpty) {
    // final title = RegExp(r'#(.*)'); RegExp('$key="([^"]+)"')
    // r'#\s*(.*)' = lines with # followed by 0 or more spaces
    // with any character other than newline in group
    String? getAttr(String key) {
      final reg = RegExp('$key="([^"]+)"');
      return reg.firstMatch(markdown)?.group(1);
    }

    String? getUri() {
      /// regex means find the character group between '(cache/' and ')'
      /// \( = escaped  ( \s* = 0 or more spaces  cache/? = cache followed by 0 or 1 /
      /// (.*) = group of 0 or more of any character  \) = escaped )
      RegExp reg = RegExp(r'\(\s*cache\/*(.*)\)');
      return reg.firstMatch(markdown)?.group(1);
    }

    final title = RegExp(r'#\s*(.*)');
    final match = title.allMatches(markdown);

    var matches = match.map((m) => m.group(0)).toList();
    if (matches.isNotEmpty) {
      elements['heading'] = matches[0]!.split('#').last.trim();
      if (matches.length > 1) {
        elements['subheading'] = matches[1]!.split('#').last.trim();
      }
    }
    final image = RegExp(r'!\[alt\s*(.*)');
    final iMatch = image.allMatches(markdown);
    final iMatches = iMatch.map((i) => i.group(0)).toList();
    List<String> images = [];
    if (iMatches.isNotEmpty) {
      for (int i = 0; i < iMatches.length; i++) {
        final String? src = getUri();
        final String? key = src?.split('.')[0];
        final String? caption = getAttr('caption');
        final String? align = getAttr('align');
        final int rotation = int.tryParse(getAttr('rotation') ?? '') ?? 0;
        final double width = double.tryParse(getAttr('width') ?? '') ?? 300;
        images.add(
            '{"url": "$src", "caption": "$caption", "align": "$align", "rotation": $rotation, "width": $width, "key": "$key"}');
      }
    }
    elements['images'] = images;
    developer.log(
        'HomeItem.heading: ${elements['heading']} subheading: ${elements['subheading']} images: ${elements['images']}',
        name: '_images_');
  }

  return elements;
}

cacheImages(item) async {
  List<Map<String, dynamic>> images = jsonDecode(item.images);
  for (int i = 0; i < images.length; i++) {}
}

imageBuilder(Uri uri, String? title, String? alt) {
  developer.log('ImageBuilder().url: ${uri.toString()}', name: '_images_');
  String text = alt ?? '';
  bool cached = uri.toString().contains('cache');
  String? getAttr(String key) {
    final reg = RegExp('$key="([^":]+)"');
    return reg.firstMatch(text)?.group(1);
  }

  final String? caption = getAttr('caption');
  final String align = getAttr('align') ?? 'center';
  final double rotation = double.tryParse(getAttr('rotation') ?? '') ?? 0.0;
  final double width = double.tryParse(getAttr('width') ?? '') ?? 300.0;

  String? getKey() {
    final reg = RegExp(r'\w*\s*\/*(.*)\.');
    String? key = reg.firstMatch(uri.toString())?.group(1);
    return key!;
  }

  final String key = getKey() ?? ' ';

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

  // uriString =
  //     'http://10.101.1.216:5001/static/images/home/f9440cb2e8c747c2811bc80ef5653ce6/01a05c9ef8ed7b8f8b0f63363cafa5b9/01a05c9e0e167a1ab481605f26f0f9c2.jpg';

  developer.log('Image url: ${uri.toString()}', name: '_images_');

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
                        MarkdownService().imageRepository.getBytes(key: key),
                        width: width,
                        fit: BoxFit.contain,
                        // Error handling is vital for Web/Mobile
                        errorBuilder: (context, _, __) =>
                            const Icon(Icons.broken_image),
                      )
                    : Image.network(
                        uri.toString(),
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          developer.log(
                              'imageBuilder() Image url: $urlBase/${uri.toString()}',
                              name: '_images_');
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          developer.log(
                              'imageBuilder(),errorBuilder error:${exception.toString()} uri: $urlBase/${uri.toString()}',
                              name: '_error_');
                          return ImageMissing(width: width);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      if (caption != null) ...[
        Row(
          mainAxisAlignment: mainAlign,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: Text(
                caption,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ]
    ],
  );
}

/*
below is the cheat-sheet from regxr.com - useful, and has a checker

Character classes 
. any character except new line
\w \d \s  word character (alphanumeric & underscore), digit, whitespace
\W \D \S  not word digit or whitespace
[abc] any of a, b, or c
[^abc] not a, b, or c
[a-g] characters between a & g

Anchors
^abc$ start/end of string
\b \B word, not-word boundary

Escaped characters
\. \* \\ escaped special characters
\t \n \r tab, linefeed, carriage return

Groups & Lookaround in Flutter the group(1) = match[1] match[0] being the whole match line
(abc) capture group
\1 backreference to group #1
(?:abc) no-capturing group
(?=abc) positive lookahead
(?!abc) negative lookahead

Qualifiers & Alternatives
a* a+ a? 0 or more, 1 or more, 0 or 1
a{5} a{2,} exactly 5, two or more
a{1,3} between one and three
a+? a{2,} match as few as possible
ab|cd match ab or cd

there are no spaced between {{< and >}} 
\{ \} = escaped '{' and '}'
\s* = 0 or more spaces
. = any character except line break
* = match 0 or more
? = match as characters as possible


eg String pattern = r'd+.d+';  checks for digit(s).digits(s)
characters that Regex requires escaping .*?[]{}()|^$
in addition Dart requires that \ needs escaping so in literals use \\ 
To create a pattern that contains excluded characters start and end the pattern with '\b'
eg for emails pattern = r'\bw+@w+\b'
*/

class ShortcodeSyntax extends md.InlineSyntax {
  ShortcodeSyntax() : super(_pattern);

  /// regex explanation see cheat-sheet above
  /// \{ \} - escaped reserved characters
  /// \s* - allow spaces between {< and content * means 0 or more
  /// (.*?) - group1 any .* ant alpha numerics ? make it non-greedy ie stop at end
  static const _pattern = r'\{\{<\s*(.*?)\s*>\}\}';
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      parser.addNode(md.Element.text('shortcode', match[1]!));
      return true;
    } catch (e) {
      developer.log('ShortcodeSyntax() error: {e.toString()}', name: 'error');
      return false;
    }
  }
}

class LineBreakSyntax extends md.InlineSyntax {
  LineBreakSyntax() : super(r'(?:\\|  +)\n');

  /// regex explanation see cheat-sheet above
  /// \{ \} - escaped reserved characters
  /// \s* - allow spaces between {< and content * means 0 or more
  /// (.*?) - group1 any .* ant alpha numerics ? make it non-greedy ie stop at end
  // static const _pattern = r'<<\s*(.*?)\s*>>';
  // static const _pattern = r'(?:\s{2,})$';
  //  static const _pattern = r'(?:\\|  +)\n';
  // static const _pattern = r'((?:\s{2,}\n)|(?:\s{2,}\r))'; //  |\\)?\n';
  // static const _pattern = r'(?:\s{2,})\n';

  /// (?: means it's a non-capturing group
  // static const _pattern = r'((?:\s{2,}\n)|(?:\s{2,}\r))'; //  |\\)?\n';
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      parser.addNode(md.Element.empty('linebreak'));
      return true;
    } catch (e) {
      developer.log('ShortcodeSyntax() error: {e.toString()}', name: 'error');
      return false;
    }
  }
}

class LineBreakBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return (Text('\n'));
  }
}

class SpaceShortcodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    // Extract height attribute
    double height = 20;
    try {
      /// regex explanation - see cheat-sheet above
      /// \s* = 0 or more spaces - allow spaces
      /// "? = 0 or 1 "s - makes the quotes optional
      /// (\d+) = group with digits in - they're what we're interested in
      final heightMatch =
          RegExp(r'height\s*=\s*"?\s*(\d+)\s*"?').firstMatch(text);
      height = double.tryParse(heightMatch?.group(1) ?? '20') ?? 20.0;
    } catch (e) {
      developer.log('error parsing the double: ${e.toString()}', name: 'error');
    }

    // Return a simple empty box
    return SizedBox(height: height);
  }
}

class ImageShortcodeBuilder extends MarkdownElementBuilder {
  ImageShortcodeBuilder();
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String text = element.textContent;
    dt.Uint8List? image;

    String? getAttr(String key) {
      final reg = RegExp('$key="([^"]+)"');
      return reg.firstMatch(text)?.group(1);
    }

    String? getUri() {
      /// uri markdown syntax (cache/9797...9898.jpg) the Regex has to escape (, ), and s*
      /// group(0) is whole match group(1) is the data retrieved in (.*)
      final reg = RegExp(r'\(\s*cache(.*)\)');
      return reg.firstMatch(text)?.group(1);
    }

    final String? src = getUri();
    final String align = getAttr('align') ?? 'center';
    final double width = double.tryParse(getAttr('width') ?? '') ?? 300.0;

    String key = '';

    developer.log(
        'ImageShortCodeBuilder() src ${src == null ? "is null" : "isn't null"}',
        name: '_images_');

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
    String styleKey, MdStyleSheet styleSheet,
    {double width = 80}) {
  TextStyle textStyle = TextStyle();
  try {
    textStyle = styleSheet.getTextStyle(key: styleKey);
  } catch (e) {
    developer.log('error getting textStyle: ${e.toString()}', name: 'error');
  }

  /// Ensure the single instance of MarkdownStyle is updated
  onChanged(value, key) {
    switch (key) {
      case 'fontSize':
        {
          try {
            textStyle = textStyle.copyWith(
                fontSize: fontSizes.values
                    .toList()[fontSizes.keys.toList().indexOf(value)]);
          } catch (e) {
            developer.log('error 1 : ${e.toString()}', name: 'error');
          }
          break;
        }
      case 'fontStyle':
        {
          try {
            textStyle = textStyle.copyWith(
                fontStyle: fontStyles.values
                    .toList()[fontStyles.keys.toList().indexOf(value)]);
          } catch (e) {
            developer.log('error 2 : ${e.toString()}', name: 'error');
          }
          break;
        }
      case 'fontWeight':
        {
          try {
            textStyle = textStyle.copyWith(
                fontWeight: fontWeights.values
                    .toList()[fontWeights.keys.toList().indexOf(value)]);
          } catch (e) {
            developer.log('error 3 : ${e.toString()}', name: 'error');
          }
          break;
        }
      case 'color':
        {
          try {
            textStyle = textStyle.copyWith(
                color: colour.values
                    .toList()[colour.keys.toList().indexOf(value)]);
          } catch (e) {
            developer.log('error 1 : ${e.toString()}', name: 'error');
          }
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
      value: fontSizes.keys.toList()[fontSizes.values
          .toList()
          .indexOf(textStyle.fontSize ?? fontSizes.values.toList().first)],
      items: fontSizes.keys.toList(),
      width: width,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'font style',
      styleKey: 'fontStyle',
      value: fontStyles.keys.toList()[fontStyles.values
          .toList()
          .indexOf(textStyle.fontStyle ?? fontStyles.values.toList().first)],
      items: fontStyles.keys.toList(),
      width: width,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'font weight',
      styleKey: 'fontWeight',
      value: fontWeights.keys.toList()[fontWeights.values
          .toList()
          .indexOf(textStyle.fontWeight ?? fontWeights.values.toList().first)],
      items: fontWeights.keys.toList(),
      width: width,
      onChanged: onChanged,
    ),
    CompactDropdown(
      heading: 'colour',
      styleKey: 'color',
      value: colour.keys.toList()[colour.values
          .toList()
          .indexOf(textStyle.color ?? colour.values.toList().first)],
      items: colour.keys.toList(),
      width: width,
      onChanged: onChanged,
    ),
  ];
}

MarkdownStyleSheet getBaseStyle() {
  return MarkdownStyleSheet(
    p: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal),
    h1: TextStyle(
        color: Colors.amber, // Colors.blue,
        fontSize: 24,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    h2: TextStyle(
        color: Colors.blue,
        fontSize: 22,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    h3: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    h4: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    tableBody: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    tableHead: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    tableHeadAlign: TextAlign.start,
    blockquote: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    /*  blockquoteDecoration: BoxDecoration(
      color: Color(0xFFF1F5F9),
      border: Border(
        left: BorderSide(
          color: Colors.blue, // Accent color (e.g., Blue)
          width: 10.0, // Thick left line
        ),
      ),
    ),
    */
    code: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    checkbox: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    listBullet: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold),
    listBulletPadding: EdgeInsets.fromLTRB(0, 5, 5, 0),
  );
}

class MdStyleSheet {
  //extends StatelessWidget {
  MarkdownStyleSheet markdownStyleSheet;
  MdStyleSheet({MarkdownStyleSheet? styleSheet})
      : markdownStyleSheet = styleSheet ?? getBaseStyle();
  factory MdStyleSheet.fromJson({required json}) {
    MarkdownStyleSheet base = getBaseStyle();
    json ??= {'x': 0};
    base.copyWith(
      p: json.containsKey('p') ? textStyleFromMap(json['p']) : base.p,
      h1: json.containsKey('h1') ? textStyleFromMap(json['h1']) : base.h1,
      h2: json.containsKey('h2') ? textStyleFromMap(json['h2']) : base.h2,
      h3: json.containsKey('h3') ? textStyleFromMap(json['h3']) : base.h3,
      h4: json.containsKey('h4') ? textStyleFromMap(json['h4']) : base.h4,
      tableBody: json.containsKey('tableBody')
          ? textStyleFromMap(json['tableBody'])
          : base.tableBody,
      tableHead: json.containsKey('tableHead')
          ? textStyleFromMap(json['tableHead'])
          : base.tableHead,
      tableHeadAlign: json.containsKey('tableHeadAlign')
          ? textAlignFromMap(json['tableHeadAlign'])
          : base.tableHeadAlign,
      blockquote: json.containsKey('blockquote')
          ? textStyleFromMap(json['blockquote'])
          : base.blockquote,
      checkbox: json.containsKey('checkbox')
          ? textStyleFromMap(json['checkbox'])
          : base.checkbox,
      listBullet: json.containsKey('listBullet')
          ? textStyleFromMap(json['listBullet'])
          : base.listBullet,
      code:
          json.containsKey('code') ? textStyleFromMap(json['code']) : base.code,
    );
    // markdownStyleSheet = base;
    return MdStyleSheet(styleSheet: base);
  }
/*
  @override
  Widget build(BuildContext context) {
    return Text('');
  }
*/

  MarkdownStyleSheet styleSheetFromJson({required Map<String, dynamic> json}) {
    final base = MarkdownStyleSheet();
    base.copyWith(
      p: json.containsKey('p') ? textStyleFromMap(json['p']) : base.p,
      h1: json.containsKey('h1') ? textStyleFromMap(json['h1']) : base.h1,
      h2: json.containsKey('h2') ? textStyleFromMap(json['h2']) : base.h2,
      h3: json.containsKey('h3') ? textStyleFromMap(json['h3']) : base.h3,
      h4: json.containsKey('h4') ? textStyleFromMap(json['h4']) : base.h4,
      tableBody: json.containsKey('tableBody')
          ? textStyleFromMap(json['tableBody'])
          : base.tableBody,
      tableHead: json.containsKey('tableHead')
          ? textStyleFromMap(json['tableHead'])
          : base.tableHead,
      tableHeadAlign: json.containsKey('tableHeadAlign')
          ? textAlignFromMap(json['tableHeadAlign'])
          : base.tableHeadAlign,
      blockquote: json.containsKey('blockquote')
          ? textStyleFromMap(json['blockquote'])
          : base.blockquote,
      checkbox: json.containsKey('checkbox')
          ? textStyleFromMap(json['checkbox'])
          : base.checkbox,
      listBullet: json.containsKey('listBullet')
          ? textStyleFromMap(json['listBullet'])
          : base.listBullet,
      code:
          json.containsKey('code') ? textStyleFromMap(json['code']) : base.code,
    );
    return base;
  }

  Map<String, dynamic> toJson() {
    developer.log('Calling MdStylesSheet().toJson()', name: '_markdown_');
    return Map<String, dynamic>.from({
      'p': markdownStyleSheet.p?.toDataMap(),
      'h1': markdownStyleSheet.h1?.toDataMap(),
      'h2': markdownStyleSheet.h2?.toDataMap(),
      'h3': markdownStyleSheet.h3?.toDataMap(),
      'h4': markdownStyleSheet.h4?.toDataMap(),
      'tableBody': markdownStyleSheet.tableBody?.toDataMap(),
      'tableHead': markdownStyleSheet.tableHead?.toDataMap(),
      'tableHeadAlign': markdownStyleSheet.tableHeadAlign?.name,
      'blockquote': markdownStyleSheet.blockquote?.toDataMap(),
      'checkbox': markdownStyleSheet.checkbox?.toDataMap(),
      'listBullet': markdownStyleSheet.listBullet?.toDataMap(),
      'code': markdownStyleSheet.code?.toDataMap(),
    });
  }

  dynamic fromJson({required Map<String, dynamic> map}) {
    return {
      'p': textStyleFromMap(map['p']),
      'h1': textStyleFromMap(map['h1']),
      'h2': textStyleFromMap(map['h2']),
      'h3': textStyleFromMap(map['h3']),
      'h4': textStyleFromMap(map['h4']),
      'tableBody': textStyleFromMap(map['tableBody']),
      'tableHead': textStyleFromMap(map['tableHead']),
      'tableheadAlign': TextAlign.values.byName(map['tableHeadAlign']),
      'blockquote': textStyleFromMap(map['blockquote']),
      'checkbox': textStyleFromMap(map['checkbox']),
      'listBullet': textStyleFromMap(map['listBullet']),
      'code': textStyleFromMap(map['code']),
    };
  }

/*
  dynamic toJsonString() {
    Map<String, dynamic> jsonStyle = {
      'p': markdownStyleSheet!.p.toString(),
      'blockquoteAlign': markdownStyleSheet!.blockquoteAlign.toString(),
      'blockquotePadding': markdownStyleSheet!.blockquotePadding.toString(),
      'h1': markdownStyleSheet!.h1.toString(),
      'h2': markdownStyleSheet!.h2.toString(),
      'h3': markdownStyleSheet!.h3.toString(),
      'h4': markdownStyleSheet!.h4.toString(),
      'tableBody': markdownStyleSheet!.tableBody.toString(),
      'tableHead': markdownStyleSheet!.tableHead.toString(),
      'tableHeadAlign': markdownStyleSheet!.tableHeadAlign.toString(),
      'blockquoteDecoration':
          markdownStyleSheet!.blockquoteDecoration.toString(),
      'checkbox': markdownStyleSheet!.checkbox.toString(),
      'listBullet': markdownStyleSheet!.listBullet.toString(),
      'code': markdownStyleSheet!.code.toString(),
    };
    return jsonStyle;
  }
*/
  /// Update the StyleSheet elements from the editors. The tags can't be updated directly as the
  /// fields are all final. Have to convert to json then update then convert back,
  updateTag({required Map<String, dynamic> tag}) {
    dynamic jsonStyle = toJson();
    jsonStyle[tag.keys.first] = tag.values.first;
    markdownStyleSheet = markdownStyleSheetFromJson(jsonStyle: jsonStyle);
  }

  TextStyle getTextStyle({required String key}) {
    TextStyle style = TextStyle();
    try {
      /// style = toJson()[key];
      style = textStyleFromMap(toJson()[key]);
    } catch (e) {
      developer.log('error getting TextStyle() getTextStyle(): ${e.toString()}',
          name: 'error');
    }
    return style;
    // textStyleFromMap(toJson()[key]);
  }
}

/// Custom InlineSyntax to capture both soft breaks (raw \n)
/// and hard breaks (two spaces or a backslash followed by \n)
class SoftAndHardLineBreakSyntax extends md.InlineSyntax {
  // This regex matches:
  // 1. (?:  |\\)? -> Optional two spaces or a trailing backslash
  // 2. \n          -> Followed by a newline character

/*
  static const _pattern = r'\{\{<\s*(.*?)\s*>\}\}';
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      parser.addNode(md.Element.text('shortcode', match[1]!));
      return true;
    } catch (e) {
      developer.log('ShortcodeSyntax() error: {e.toString()}', name: 'error');
      return false;
    }
  }

*/
  static const _pattern = r'\{\{<\s*(.*?)\s*>\}\}';
  SoftAndHardLineBreakSyntax() : super(_pattern); //r'(?:  |\\)?\n');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // Generate an element that Flutter's Markdown widget recognizes as a <br> tag
    parser.addNode(md.Element.empty('br'));
    return true;
  }
}

class DesignerMarkdownViewer extends StatelessWidget {
  final String markdownText;
  final dynamic customExtensionSet; // From your previous soft-break setups

  const DesignerMarkdownViewer({
    super.key,
    required this.markdownText,
    this.customExtensionSet,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    final professionalStyle = MarkdownStyleSheet.fromTheme(baseTheme).copyWith(
      // 1. Set global vertical layout rhythm
      blockSpacing: 20.0,

      // 2. Format content margins inside the container box
      blockquotePadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),

      // 3. Complete box styling containing the background icon layer
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(12.0)),
        border: const Border(
          left: BorderSide(
            color: Colors.indigoAccent,
            width: 8.0, // Clean, extra-wide colored band
          ),
        ),
        image: DecorationImage(
          image: const AssetImage(
              'assets/icons/left_quote.png'), // Register in pubspec.yaml
          alignment:
              const Alignment(-0.95, -0.8), // Custom alignment coordinates
          fit: BoxFit.none,
          scale: 3.0,
          colorFilter: ColorFilter.mode(
            Colors.black
                .withOpacity(0.04), // Faint, elegant watermark background
            BlendMode.dstIn,
          ),
        ),
      ),

      // 4. Adjust the font presentation matching the design theme
      blockquote: baseTheme.textTheme.bodyMedium?.copyWith(
        color: Colors.blueGrey.shade900,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
    );

    return Markdown(
      data: markdownText,
      extensionSet: customExtensionSet,
      styleSheet: professionalStyle,
    );
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
            color: Colors.amber, // Colors.blue,
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
    /*  blockquoteDecoration: BoxDecoration(
      color: Color(0xFFF1F5F9),
      border: Border(
        left: BorderSide(
          color: Colors.blue, // Accent color (e.g., Blue)
          width: 6.0, // Thick left line
        ),
      ),
    ),
    */
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

/// These next two functions are to allow the serialisation of TextStyle
/// The extension adds the method toDataMap to TextStyle()
/// colour, fontWeight, fontSizes and fontStyles are maps held in constants.dart
extension TextStyleSerialization on TextStyle {
  // Convert a single TextStyle to a simple JSON-friendly Map
  Map<String, dynamic> toDataMap() {
    return {
      'color': colour.keys.toList()[colour.values.toList().indexOf(color!)],
      'fontSize':
          fontSizes.keys.toList()[fontSizes.values.toList().indexOf(fontSize!)],
      'fontWeight': fontWeights.keys
          .toList()[fontWeights.values.toList().indexOf(fontWeight!)],
      'fontStyle': fontStyles.keys
          .toList()[fontStyles.values.toList().indexOf(fontStyle!)],
    };
  }
}

/// The textStyleFromMap() creates the TextStyle from the map created
/// by the TextStyle() extension toDataMap()
TextStyle textStyleFromMap(Map<String, dynamic> data) {
  TextStyle textStyle = TextStyle();
  try {
    textStyle = TextStyle(
      color:
          colour.values.toList()[colour.keys.toList().indexOf(data['color'])],
      fontSize: fontSizes.values.toList()[fontSizes.keys.toList().indexOf(
            data['fontSize'],
          )],
      fontWeight: fontWeights.values.toList()[fontWeights.keys.toList().indexOf(
            data['fontWeight'],
          )],
      fontStyle: fontStyles.values.toList()[fontStyles.keys.toList().indexOf(
            data['fontStyle'],
          )],
    );
  } catch (e) {
    developer.log('Error with TextStyle: ${e.toString()}', name: 'error');
  }
  return textStyle;
}

TextAlign textAlignFromMap(String data) {
  if (data == 'end') return TextAlign.end;
  if (data == 'start') return TextAlign.start;
  return TextAlign.center;
}

/* 
'blockquoteDecoration'Attempt to improve the blockquote border style: 
markdownStyleSheet!.blockquoteDecoration ??
    BoxDecoration(
      color: Colors.grey.shade100, // <--- Your custom background color
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(8.0),
        bottomRight: Radius.circular(8.0),
      ),
      border: Border(
        left: BorderSide(
          color: Colors.blueAccent, // <--- Color of the leading strip
          width:
              6.0, // <--- Make the leading strip thicker (e.g., 6px or 8px)
        ),
      ),
    ), 
*/

/*
List<Widget> getActions({
  bool code = true,
  List<String>? buffer,
  int bufferIndex = -1,
  PopupMenuButton? overflow,
  codePressed,
  undoPressed,
  redoPressed,
  onUploadPressed,
}) {
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
        onPressed: () => onUploadPressed,
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
*/

List<IconButton> getActionsButtons({
  bool code = true,
  List<String>? buffer,
  int bufferIndex = -1,
  PopupMenuButton? overflow,
  addPressed,
  removePressed,
  codePressed,
  undoPressed,
  redoPressed,
  uploadPressed,
}) {
  buffer ??= [];
  return [
    /*
    IconButton(
      onPressed: codePressed,
      icon: Icon(
        code ? Icons.code_off : Icons.code,
      ),S
    ),
    */
    if (code == true) ...[
      IconButton(
        onPressed: addPressed,
        icon: Icon(
          Icons.note_add_outlined,
        ),
      ),
      IconButton(
        onPressed: removePressed,
        icon: Icon(
          Icons.delete_outlined,
        ),
      ),
      IconButton(
        onPressed: uploadPressed,
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
      //  if (overflow != null) overflow
    ],
  ];
}
/*
List<Icon> getActionIcons(
    {bool code = true,
    List<String>? buffer,
    int bufferIndex = -1,
    PopupMenuButton? overflow,
    codePressed,
    undoPressed,
    redoPressed}) {
  buffer ??= [];
  return [
    Icon(
      code ? Icons.code_off : Icons.code,
    ),
    if (code == true) ...[
      Icon(
        Icons.upload,
      ),
      Icon(
        Icons.undo_outlined,
        color: buffer.isEmpty || bufferIndex == buffer.length - 1
            ? Colors.grey
            : Colors.white,
      ),
      Icon(
        Icons.redo_outlined,
        color: buffer.isEmpty || bufferIndex <= 0 ? Colors.grey : Colors.white,
      ),
    ],
  ];
}
*/
/*
List<Function()> getActionMethods(
    {bool code = true,
    List<String>? buffer,
    int bufferIndex = -1,
    PopupMenuButton? overflow,
    codePressed,
    undoPressed,
    redoPressed}) {
  return [
    codePressed,
    if (code == true) ...[
      () => (),
      undoPressed,
      redoPressed,
    ]
  ];
}*/

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
