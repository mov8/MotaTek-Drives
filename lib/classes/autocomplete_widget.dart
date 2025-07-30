import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';
import 'dart:developer' as developer;

class AutocompleteWidget extends StatelessWidget {
  final List<String> options;
  const AutocompleteWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return options.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        //      debugPrint('You just selected $selection');
      },
    );
  }
}

class AutoCompleteAsyncController {
  _AutocompleteAsyncState? _autocompleteAsyncState;

  void _addState(_AutocompleteAsyncState autocompleteAsyncState) {
    _autocompleteAsyncState = autocompleteAsyncState;
  }

  bool get isAttached => _autocompleteAsyncState != null;

  void dispose() {
    assert(isAttached, 'Controller must be attached to widget to dispose');
    try {
      _autocompleteAsyncState?.disposeController();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error disposing of AutocompleteController: $err');
    }
  }

  void setFocus() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _autocompleteAsyncState?.setFocus();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void clear() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _autocompleteAsyncState?.clear();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }
}

class AutocompleteAsync extends StatefulWidget {
  final String type;
  final int searchLength;
  final double optionsMinHeight;
  final double optionsMaxHeight;
  final Function(String)? onSelect;
  final Function(String)? onChange;
  final Function(String)? onUpdateOptionsRequest;
  final AutoCompleteAsyncController controller;
  final List<String> options;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;

  const AutocompleteAsync(
      {super.key,
      required this.options,
      required this.controller,
      this.type = 'email',
      this.searchLength = 1,
      this.optionsMinHeight = 50,
      this.optionsMaxHeight = 150,
      this.onSelect,
      this.onChange,
      this.onUpdateOptionsRequest,
      this.decoration,
      this.keyboardType,
      this.textInputAction});

  @override
  State<AutocompleteAsync> createState() => _AutocompleteAsyncState();
}

class _AutocompleteAsyncState extends State<AutocompleteAsync> {
  String _lastReadQuery = '';
  final List<String> _options = [];
  final List<String> _allOptions = [];
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // bool changeId = _widgetId != widget.initialValue;
    widget.controller._addState(this);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        _allOptions.addAll(widget.options);
        return _options;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        // This next line allows the late widget.controller; to have control
        _controller = fieldTextEditingController;
        _focusNode = fieldFocusNode;
        return TextField(
          controller: fieldTextEditingController,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          focusNode: fieldFocusNode,
          decoration: widget.decoration,
          onChanged: (text) {
            if (text.isEmpty) {
              _options.clear();
            } else {
              if (_options.isEmpty) {
                _options.addAll(_allOptions);
              }
              _options.retainWhere((str) => str.startsWith(text));
              widget.onChange!(text);
              if ((_lastReadQuery.isEmpty &&
                      text.length >= widget.searchLength) ||
                  (text.length >= widget.searchLength &&
                      !text.startsWith(_lastReadQuery))) {
                widget.onUpdateOptionsRequest!(text);
                _lastReadQuery = text;
              }
            }
          },
          onSubmitted: (text) {
            //     debugPrint('$text submitted');
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: widget.optionsMinHeight,
                maxHeight: widget.optionsMaxHeight),
            child: Material(
              elevation: 4.0,
              child: ListView(
                children: options.map((String option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      onSelected: (chosen) => widget.onSelect!(chosen),
    );
  }

  clear() {
    widget.controller.clear();
  }

  disposeController() {
    _controller.dispose();
  }

  setFocus() {
    _focusNode.requestFocus();
  }
}

/*
class AutoCompleteAsyncController {
  _AutocompleteAsyncState? _autocompleteAsyncState;

  void _addState(_AutocompleteAsyncState autocompleteAsyncState) {
    _autocompleteAsyncState = autocompleteAsyncState;
  }

  bool get isAttached => _autocompleteAsyncState != null;

  void dispose() {
    assert(isAttached, 'Controller must be attached to widget to dispose');
    try {
      _autocompleteAsyncState?.disposeController();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error disposing of AutocompleteController: $err');
    }
  }

  void clear() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _autocompleteAsyncState?.clear();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }
}

class AutocompleteAsync extends StatefulWidget {
  final String type;
  final int searchLength;
  final bool autofocus;
  final Function(String)? onSelect;
  final Function(String)? onChange;
  final Function(String)? onUpdateOptionsRequest;
  final Function()? clear;
  final List<String> options;
  final FocusNode? focusNode;
  final AutoCompleteAsyncController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;

  const AutocompleteAsync(
      {super.key,
      required this.options,
      required this.controller,
      this.type = 'email',
      this.autofocus = false,
      this.searchLength = 1,
      this.onSelect,
      this.onChange,
      this.clear,
      this.onUpdateOptionsRequest,
      this.decoration,
      this.focusNode,
      this.keyboardType,
      this.textInputAction});

  @override
  State<AutocompleteAsync> createState() => _AutocompleteAsyncState();
}

class _AutocompleteAsyncState extends State<AutocompleteAsync> {
  String _lastReadQuery = '';
  final List<String> _options = [];
  final List<String> _allOptions = [];
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    // bool changeId = _widgetId != widget.initialValue;
    widget.controller._addState(this);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        _allOptions.clear();
        _allOptions.addAll(widget.options);
        return _options;
      },
      displayStringForOption: (option) => 'email: $option',
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        // This next line allows the late widget.controller; to have control
        // _controller = fieldTextEditingController;
        return TextField(
          autofocus: widget.autofocus,
          controller: fieldTextEditingController,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode, // fieldFocusNode,
          decoration: widget.decoration,
          textCapitalization: TextCapitalization.none,
          onChanged: (text) {
            developer.log('onchange: $text', name: '_dropdown');
            if (text.length < widget.searchLength) {
              _options.clear();
            } else {
              if (_options.isEmpty) {
                _options.addAll(_allOptions);
              }

              widget.onChange!(text);
              if (_options.isNotEmpty) {
                developer.log('options not empty: $text', name: '_dropdown');
                _options.retainWhere((str) => str.startsWith(text));
                if (_options.isEmpty) {
                  developer.log('update request: $text', name: '_dropdown');
                  widget.onUpdateOptionsRequest!('');
                }
              }
              if (_lastReadQuery.isEmpty || !text.startsWith(_lastReadQuery)) {
                developer.log(' empty: $text', name: '_dropdown');
                widget.onUpdateOptionsRequest!(text);
                developer.log('update request 2: $text', name: '_dropdown');
                _lastReadQuery = text;
              }
            }
          },
          onSubmitted: (text) {},
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        developer.log('opptionsViewBuilder options.length: ${options.length}',
            name: '_dropdown');
        return Material(
          elevation: 4.0,
          child: ListView(
            children: options.map((String option) {
              return ListTile(
                title: Text(option),
                onTap: () {
                  onSelected(option);
                },
              );
            }).toList(),
          ),
        );
      },
      onSelected: (chosen) {
        if (widget.onSelect != null) {
          widget.onSelect!(chosen);
        }
      },
    );
  }

  disposeController() {
    _controller.dispose();
  }

  clear() {
    _controller.clear();
  }
}

*/

class AutocompletePlace extends StatefulWidget {
  final String type;
  final int searchLength;
  final Function(Place)? onSelect;
  final Function(String)? onChange;
  final Function(String)? onUpdateOptionsRequest;
  final List<Place> options;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final double optionsMaxHeight;
  const AutocompletePlace(
      {super.key,
      required this.options,
      this.type = 'email',
      this.searchLength = 1,
      this.onSelect,
      this.onChange,
      this.onUpdateOptionsRequest,
      this.optionsMaxHeight = 200,
      this.decoration,
      this.keyboardType});

  @override
  State<AutocompletePlace> createState() => _AutocompletePlace();
}

class _AutocompletePlace extends State<AutocompletePlace> {
  String _lastReadQuery = '**_|_**';
  final String _lastFilter = '**__|__**';
  final List<Place> _options = [];
  final List<Place> _allOptions = [];
  TextEditingController fieldTextEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Autocomplete<Place>(
      optionsMaxHeight: widget.optionsMaxHeight,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        _allOptions.addAll(widget.options);
        return _options;
      },
      displayStringForOption: (option) => option.name,
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          autofocus: true,
          controller: fieldTextEditingController,
          keyboardType: widget.keyboardType,
          focusNode: fieldFocusNode,
          decoration: widget.decoration,
          textCapitalization: TextCapitalization.words,
          onChanged: (text) {
            if (text.length < widget.searchLength) {
              _options.clear();
            } else {
              if (_options.isEmpty) {
                _options.addAll(_allOptions);
              }
              _options.retainWhere((place) => place.name.startsWith(text));
              widget.onChange!(text);
              if (_lastReadQuery.isEmpty || !text.startsWith(_lastReadQuery)) {
                widget.onUpdateOptionsRequest!(text);
                _lastReadQuery = text;
              } else if (!text.startsWith(_lastFilter)) {
                _options.clear();
                _options.addAll(_allOptions);
                _options.retainWhere((place) => place.name.startsWith(text));
                widget.onChange!(text);
              }
            }
          },
          onSubmitted: (text) {
            debugPrint('$text submitted');
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Place> onSelected, Iterable<Place> options) {
        return Material(
          color: Colors.white60,
          //  elevation: 4.0,
          child: ListView(
            children: options.map((Place option) {
              return Card(
                elevation: 4,
                color: const Color.fromRGBO(215, 234, 243, 1),
                child: ListTile(
                  tileColor: Colors.transparent,
                  title: Text('${option.name} (${option.tag})',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('${option.street} ${option.town}'),
                  leading: Icon(
                      IconData(option.iconData, //option.iconData,
                          fontFamily: 'MaterialIcons'),
                      size: 30), // Icon(Icons
                  onTap: () {
                    onSelected(option);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
      onSelected: (chosen) {
        if (widget.onSelect != null) {
          try {
            //  fieldTextEditingController.text = chosen.name;
            widget.onSelect!(chosen);
          } catch (e) {
            debugPrint('Error ${e.toString()}');
          }
        }
      },
    );
  }
}
