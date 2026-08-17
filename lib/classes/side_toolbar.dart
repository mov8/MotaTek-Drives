import 'package:flutter/material.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import '/helpers/helpers.dart';

class SideToolbarController {
  _SideToolbarState? _sideToolbarState;
  void _addState(_SideToolbarState sideToolbarState) {
    _sideToolbarState = sideToolbarState;
  }

  void close() {
    if (isAttached) {
      _sideToolbarState!.close();
    }
  }

  void open() {
    if (isAttached) {
      _sideToolbarState!.open();
    }
  }

  bool get isAttached => _sideToolbarState != null;
}

class SideToolbar extends StatefulWidget {
  // List<IconButton> buttons = [];
  List<FormatEditor> buttons = [];
  SideToolbarController? controller;
  List<String>? captions;
  Function(int, int) onClick;
  double width;
  SideToolbar(
      {super.key,
      required this.buttons,
      required this.onClick,
      this.captions,
      this.width = 50,
      this.controller});
  @override
  State<SideToolbar> createState() => _SideToolbarState();
}

class _SideToolbarState extends State<SideToolbar>
    with TickerProviderStateMixin {
  double width = 0;
  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  @override
  build(BuildContext context) {
    double height = width * widget.buttons.length + 40;
    height = MediaQuery.of(context).size.height - 100;
    return Material(
      child: Column(
        children: [
          for (int i = 0; i < widget.buttons.length; i++)
            Row(children: [
              Expanded(child: SizedBox(width: double.infinity)),
              widget.buttons[i]
            ]),
        ],
      ),
    );
  }

  open() {
    setState(() => width = widget.width);
  }

  close() {
    setState(() => width = 0);
  }
}

List<double> heights = [20, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60];
List<double> iconSizes = [15, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30];
List<Function> dropdownTools = [
  () => {},
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
  dropdownsTextStyle,
];
List<IconData> icons = [
  Icons.close_outlined,
  Icons.article_outlined,
  Icons.looks_one_outlined,
  Icons.looks_two_outlined,
  Icons.looks_3_outlined,
  Icons.looks_4_outlined,
  Icons.border_top_outlined,
  Icons.align_horizontal_left_outlined,
  Icons.dataset_outlined,
  Icons.format_quote_outlined,
  Icons.code,
];
List<Function(int)> onSelects = [
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
  (val) => {},
];
List<String> styleKeys = [
  '',
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'tableHead',
  'tableAlign',
  'tableBody',
  'blockquote',
  'code'
];
List<String> titles = [
  '',
  'page body text -p',
  'heading 1 - #',
  'heading 2 - ##',
  'heading 3 - ###',
  'heading 4 - ####',
  'table column headings',
  'align column headings',
  'table body text',
  'bock quote text',
  'code text'
];
/*
  @override
  build(BuildContext context) {
    return getFormatEditors(
        heights: heights,
        iconSizes: iconSizes,
        dropdownTools: dropdownTools,
        icons: icons,
        onSelects: onSelects,
        styleKeys: styleKeys,
        titles: titles);
  }
*/
List<Widget> getFormatEditors(
    {double top = 10,
    double right = 5,
    required List<double> heights,
    required List<double> iconSizes,
    // required List<Function> dropdownTools,
    required List dropdownTools,
    required List<IconData> icons,
    required List<Function(dynamic)> onSelects,
    required List<String> styleKeys,
    required List<String> titles}) {
  List<Widget> editors = [];
  for (int i = 0; i < heights.length; i++) {
    if (i > 0) {
      top += heights[i - 1];
    }

    editors.add(
      Positioned(
        top: top,
        right: 5,
        child: FormatEditor(
          index: i,
          height: heights[i],
          width: 30,
          title: titles[i],
          styleKey: styleKeys[i],
          onSelect: onSelects[i],
          tools: dropdownTools[i],
          buttonIcon: Icon(icons[i], size: iconSizes[i]),
        ),
      ),
    );
  }
  return editors;
}

/// The FormatEditor class creates the animated tool bar that displays
/// a series of CompactDropdowns along the bar

class FormatEditor<T> extends StatefulWidget {
  int index;
  bool hidden;
  final double height;
  final double width;
  final double expandedWidth;
  final Icon buttonIcon;
  final String styleKey;
  final String? title;
  List<T> tools;
  final Function(dynamic)? onSelect;
  FormatEditor({
    super.key,
    required this.index,
    required this.buttonIcon,
    this.title,
    required this.tools,
    this.hidden = true,
    this.styleKey = '',
    this.onSelect,
    this.expandedWidth = 0,
    this.height = 50,
    this.width = 50,
  });
  @override
  State<FormatEditor> createState() => _FormatEditorState();
}

class _FormatEditorState extends State<FormatEditor>
    with TickerProviderStateMixin {
  double _expandedWidth = 0;
  double _width = 45;
  double _height = 40;
  double _collapsedWidth = 40;
  bool _end = true;
  // bool _hidden = true;
  @override
  void initState() {
    super.initState();
    _width = widget.width; // <-- Button size + 20 works
    _height = widget.height; // widget.index == 0 ? 10 : _width;
    _collapsedWidth = _width;
    // _hidden = widget.hidden;
  }

  @override
  Widget build(BuildContext context) {
    _expandedWidth = MediaQuery.of(context).size.width - 25;
    return AnimatedContainer(
      color: Colors.blue,
      duration: const Duration(seconds: 1),
      width: widget.hidden ? 0 : _width, //_collapsedWidth,
      height: _height,
      onEnd: (() => setState(() => _end = true)),
      curve: Curves.fastOutSlowIn,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: Container(
          color: Colors.red,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      children: [
                        if (_end == true && _width == _expandedWidth) ...[
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              widget.title ?? 'Attribute',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                for (int i = 0;
                                    i < widget.tools.length;
                                    i++) ...[
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      // 'heading?',
                                      widget.tools[i].heading,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                for (int i = 0;
                                    i < widget.tools.length;
                                    i++) ...[
                                  Expanded(
                                    flex: 2,
                                    child: widget.tools[i],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    setState(
                      () {
                        if (widget.onSelect != null && widget.index < 0) {
                          widget.onSelect!('close');
                        } else {
                          _end = false;
                          _width = _width == _collapsedWidth
                              ? _expandedWidth
                              : _collapsedWidth;
                          if (widget.onSelect != null &&
                              _width == _collapsedWidth) {
                            widget.onSelect!(widget.styleKey);
                          }
                        }
                      },
                    );
                  },
                  icon: widget.buttonIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<FormatEditor> getButtons(
    {required MdStyleSheet styleSheet, onUpdate, bool hidden = false}) {
  developer.log('getButtons() called _hidden: $hidden', name: '_tools_');

  return [
    FormatEditor(
      index: -1,
      height: 20,
      hidden: hidden,
      width: 50,
      title: '',
      buttonIcon: Icon(Icons.close_outlined, size: 15, color: Colors.white),
      tools: [],
      onSelect: onUpdate, //,
    ),
    FormatEditor(
      index: 0,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'page body text - p',
      styleKey: 'p',
      tools: dropdownsTextStyle('p', styleSheet),
      buttonIcon: Icon(Icons.article_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 1,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'heading 1 - #',
      styleKey: 'h1',
      tools: dropdownsTextStyle('h1', styleSheet),
      buttonIcon: Icon(Icons.looks_one_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 2,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'heading 2 - ##',
      styleKey: 'h2',
      tools: dropdownsTextStyle('h2', styleSheet),
      buttonIcon: Icon(Icons.looks_two_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 3,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'heading 3 - ###',
      styleKey: 'h3',
      tools: dropdownsTextStyle('h3', styleSheet),
      buttonIcon: Icon(Icons.looks_3_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 4,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'heading 4 - ####',
      styleKey: 'h4',
      tools: dropdownsTextStyle('h4', styleSheet),
      buttonIcon: Icon(Icons.looks_4_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 5,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'table heading',
      styleKey: 'tableHead',
      tools: dropdownsTextStyle('tableHead', styleSheet),
      buttonIcon:
          Icon(Icons.border_top_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 6,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'align heading',
      styleKey: 'tableHeadAlign',
      tools: [],
      buttonIcon: Icon(Icons.align_horizontal_left_outlined,
          size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 7,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'table body',
      styleKey: 'tableBody',
      tools: dropdownsTextStyle('tableBody', styleSheet),
      buttonIcon: Icon(Icons.dataset_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 8,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'block quote',
      styleKey: 'blockquote',
      tools: dropdownsTextStyle('blockquote', styleSheet),
      buttonIcon:
          Icon(Icons.format_quote_outlined, size: 30, color: Colors.white),
    ),
    FormatEditor(
      index: 9,
      height: 60,
      hidden: hidden,
      width: 50,
      title: 'code',
      styleKey: 'code',
      tools: dropdownsTextStyle('code', styleSheet),
      buttonIcon: Icon(Icons.code, size: 30, color: Colors.white),
    ),
  ];
}
