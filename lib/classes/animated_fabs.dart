import 'package:flutter/material.dart';
//import 'package:drives/classes/classes.dart';
//import ''

class FloatingChecklist extends StatefulWidget {
  // final Function(int) onMenuTap;
  final Function(Map<String, bool>)? onCheck;
  final Function(bool)? onClose;

  List<Map<String, bool>> choices;
  double maxWidth;
  double maxHeight;
  double width;
  double height;
  Color backgoundColor;
  IconData closedIcon;
  IconData openIcon;
  double closedIconSize;
  Color closedIconColor;
  double openIconSize;
  Color openIconColor;

  FloatingChecklist(
      {super.key,
      required this.choices,
      this.height = 56,
      this.maxHeight = 150,
      this.width = 56,
      this.maxWidth = 200,
      this.backgoundColor = Colors.blue,
      this.closedIcon = Icons.check_circle_outlined,
      this.closedIconSize = 30,
      this.closedIconColor = Colors.white,
      this.openIcon = Icons.settings,
      this.openIconSize = 30,
      this.openIconColor = Colors.white,
      this.onCheck,
      this.onClose});
  @override
  State<FloatingChecklist> createState() => _FloatingChecklistState();
}

class _FloatingChecklistState extends State<FloatingChecklist> {
  late double _width;
  late double _maxWidth;
  late double _height;
  late double _maxHeight;
  late bool _expanded;
  late List _choices;

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _maxWidth = widget.maxWidth;
    _height = widget.height;
    _maxHeight = widget.maxHeight;
    _choices = widget.choices;
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      // color: Colors.blueAccent,
      width: _width,
      height: _height,
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(30)),
      curve: Curves.fastOutSlowIn,
      onEnd: () => setState(() {
        _expanded = _width > widget.width && _height > widget.height;

        _height = _width == widget.width ? widget.height : _maxHeight;
      }),
      child: _expanded
          ? Row(children: [
              SizedBox(
                width: _width - widget.height,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                  child: Card(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          widget.choices.length,
                          (index) => Card(
                            child: CheckboxListTile(
                              value: _choices[index].values.toList()[0],
                              onChanged: (value) {
                                setState(() {
                                  _choices[index]
                                          [_choices[index].keys.toList()[0]] =
                                      value;
                                  if (widget.onCheck != null) {
                                    widget.onCheck!;
                                  }
                                });
                              },
                              title: Text(_choices[index].keys.toList()[0],
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _width = widget.height;
                        _height = widget.height;
                        if (widget.onClose != null) {
                          widget.onClose!(true);
                        }
                      });
                      _expanded = false;
                    },
                    icon: Icon(
                        _width > widget.width
                            ? widget.closedIcon // Icons.settings_outlined
                            : widget.openIcon, //Icons.settings,
                        size: widget.openIconSize, //_height / 2,
                        color: widget.openIconColor // Colors.white),
                        ),
                  ),
                ),
              ),
            ])
          : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 4, 4, 0),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = false;
                      _width = _maxWidth;
                    });
                  },
                  icon: Icon(
                      _height == widget.height
                          ? widget.openIcon
                          : widget.closedIcon,
                      size: widget.closedIconSize,
                      color: widget.closedIconColor),
                ),
              ),
            ),
    );
  }
}

class FloatingTextEdit extends StatefulWidget {
  double maxWidth;
  double maxHeight;
  double width;
  double height;
  Color backgoundColor;
  IconData closedIcon;
  IconData openIcon;
  double closedIconSize;
  Color closedIconColor;
  double openIconSize;
  Color openIconColor;
  FocusNode? focusNode;
  InputDecoration? decoration;
  TextInputType? keyboardType;

  final Function(String)? onChange;
  final Function(String)? onClose;
  FloatingTextEdit(
      {super.key,
      this.height = 56,
      this.maxHeight = 150,
      this.width = 56,
      this.maxWidth = 200,
      this.backgoundColor = Colors.blue,
      this.closedIcon = Icons.check_circle_outline,
      this.closedIconSize = 30,
      this.closedIconColor = Colors.white,
      this.openIcon = Icons.edit,
      this.openIconSize = 30,
      this.openIconColor = Colors.white,
      this.focusNode,
      this.decoration,
      this.keyboardType,
      this.onChange,
      this.onClose});
  @override
  State<FloatingTextEdit> createState() => _FloatingTextEdit();
}

class _FloatingTextEdit extends State<FloatingTextEdit> {
  late double _width;
  late double _height;
  late bool _expanded;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _height = widget.height;
    _expanded = false;
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: _width,
      height: _height,
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(_height / 2)),
      curve: Curves.fastOutSlowIn,
      onEnd: () => setState(() => _expanded = _width > _height),
      child: _expanded
          ? Row(
              children: [
                SizedBox(
                  width: _width - _height,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                    child: TextField(
                      autofocus: true,
                      controller: _controller,
                      keyboardType: widget.keyboardType,
                      focusNode: widget.focusNode,
                      decoration: widget.decoration,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (text) => widget.onChange!(text),
                      onSubmitted: (text) {
                        debugPrint('$text submitted');
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (widget.onClose != null) {
                            widget.onClose!(_controller.text);
                          }
                          _width = _height;
                        });
                        _expanded = false;
                      },
                      icon: Icon(
                        _width > _height ? widget.openIcon : widget.closedIcon,
                        size: _height / 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = false;
                      _width = MediaQuery.of(context).size.width - 40;
                    });
                  },
                  icon: Icon(widget.closedIcon,
                      size: _height / 2, color: Colors.white),
                ),
              ),
            ),
    );
  }
}
/*
class FloatingAutocomplete extends StatefulWidget {
  // final Function(int) onMenuTap;
  final Function(Map<String, bool>)? onCheck;
  final Function(bool)? onClose;

  List<Map<String, bool>> choices;
  double maxWidth;
  double maxHeight;
  double width;
  double height;
  Color backgoundColor;
  IconData closedIcon;
  IconData openIcon;
  double closedIconSize;
  Color closedIconColor;
  double openIconSize;
  Color openIconColor;

  FloatingAutocomplete(
      {super.key,
      required this.choices,
      this.height = 56,
      this.maxHeight = 150,
      this.width = 56,
      this.maxWidth = 200,
      this.backgoundColor = Colors.blue,
      this.closedIcon = Icons.settings,
      this.closedIconSize = 30,
      this.closedIconColor = Colors.white,
      this.openIcon = Icons.settings,
      this.openIconSize = 30,
      this.openIconColor = Colors.white,
      this.onCheck,
      this.onClose});
  @override
  State<FloatingAutocomplete> createState() => _FloatingAutocompleteState();
}

class _FloatingAutocompleteState extends State<FloatingAutocomplete> {
  late double _width;
  late double _maxWidth;
  late double _height;
  late double _maxHeight;
  late bool _expanded;
  late List _choices;
  List _places = [];

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _maxWidth = widget.maxWidth;
    _height = widget.height;
    _maxHeight = widget.maxHeight;
    _choices = widget.choices;
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return         AnimatedContainer(
          duration: const Duration(seconds: 1),
          // color: Colors.blueAccent,
          width: _width,
          height: _height,
          decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(_height / 2)),
          curve: Curves.fastOutSlowIn,
          onEnd: () => setState(() => _expanded = _width > _height),
          child: _expanded
              ? Row(
                  children: [
                    SizedBox(
                      width: _width - _height,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                          child: AutocompletePlace(
                            options: _places,
                            searchLength: 3,
                            decoration: InputDecoration(
                              filled: true,

                              fillColor: Colors.white,
                              //     enabledBorder: OutlineInputBorder(),
                              border: _width > _height
                                  ? OutlineInputBorder()
                                  : null,
                              //     enabled: _width > _height,
                              hintText: 'Enter place name...',
                            ),
                            keyboardType: TextInputType.text,
                            onSelect: (chosen) => (),
                            onChange: (text) => (debugPrint('onChange: $text')),
                            onUpdateOptionsRequest: (query) {
                              debugPrint('Query: $query');
                              getDropdownItems(query);
                            },
                          )),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _width = _height);
                            _expanded = false;
                          },
                          icon: Icon(
                              _width > _height
                                  ? Icons.search_off_outlined
                                  : Icons.search_outlined,
                              size: _height / 2,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _expanded = false;
                          _width = MediaQuery.of(context).size.width - 40;
                        });
                      },
                      icon: Icon(Icons.search,
                          size: _height / 2, color: Colors.white),
                    ),
                  ),
                ),
        ),
  }
}
*/
