import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/navigation_service.dart';
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
              //    Expanded(child: SizedBox(width: double.infinity)),
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
/*
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
*/

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
  double _width = 50;
  double _height = 40;
  double _collapsedWidth = 40;
  bool _end = true;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();

    // <-- Button size + 20 works
    _height = widget.height; // widget.index == 0 ? 10 : _width;
    _collapsedWidth = widget.width; //- 20;
    _hidden = widget.hidden;
    _width = 0;
  }

  @override
  Widget build(BuildContext context) {
    _expandedWidth = kIsWeb
        ? (MediaQuery.of(context).size.width / 3) + 30
        : MediaQuery.of(context).size.width - 25;
    return widget.hidden
        ? SizedBox()
        : AnimatedContainer(
            color: Colors.blue,
            duration: const Duration(seconds: 1),
            width: _width < _expandedWidth
                ? _collapsedWidth
                : _width, //_collapsedWidth,
            height: _height,
            onEnd: (() => setState(() => _end = true)),
            curve: Curves.fastOutSlowIn,
            child: SizedBox(
              width: _width > 70 ? _width + 20 : _width, //double.infinity,
              height: _height,
              child: Container(
                color: Colors.blue,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_width > 70) ...[
                      Expanded(
                        child: SizedBox(
                          width: _width, //double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(widget.title ?? 'Title',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      if (_width == _expandedWidth && _end) ...[
                                        for (int i = 0;
                                            i < widget.tools.length;
                                            i++) ...[
                                          SizedBox(width: i == 0 ? 15 : 3),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              // 'heading?',
                                              widget.tools[i].heading,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          SizedBox(
                                            width: i == widget.tools.length - 1
                                                ? 15
                                                : 5,
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      if (_width == _expandedWidth && _end) ...[
                                        for (int i = 0;
                                            i < widget.tools.length;
                                            i++) ...[
                                          Expanded(
                                            flex: 2,
                                            child: SizedBox(
                                              width: i == 0 ? 15 : 3,
                                            ),
                                          ),
                                          widget.tools[i],
                                          SizedBox(
                                            width: i == widget.tools.length - 1
                                                ? 15
                                                : 5,
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          setState(
                            () {
                              /// index -1 = close button
                              if (widget.onSelect != null && widget.index < 0) {
                                widget.onSelect!('close');
                              } else {
                                _end = false;
                                _width = _width < _expandedWidth
                                    ? _expandedWidth
                                    : _collapsedWidth;
                                if (widget.onSelect != null &&
                                    _width == _collapsedWidth) {
                                  widget.onSelect!(widget.styleKey);
                                }
                              }
                              // _end = !_end;
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

/// getButtons gets the contents of the SideToolbar that lets users change fonts etc
List<FormatEditor> getButtons(
    {required MdStyleSheet styleSheet, onUpdate, bool hidden = true}) {
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
