import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '/classes/classes.dart';
import 'package:flutter/services.dart';
import '/constants.dart' show materialIcon;

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

  void setNextAction({TextInputAction nextAction = TextInputAction.next}) {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _autocompleteAsyncState?.setNextAction(nextAction: nextAction);
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
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;

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
      this.inputFormatters,
      this.onUpdateOptionsRequest,
      this.decoration,
      this.keyboardType,
      this.style,
      this.textInputAction});

  @override
  State<AutocompleteAsync> createState() => _AutocompleteAsyncState();
}

class _AutocompleteAsyncState extends State<AutocompleteAsync> {
  String _lastReadQuery = '';
  List<String> _options = [];
  final List<String> _allOptions = [];
  late TextEditingController _controller;
  late TextInputAction _nextAction;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _nextAction = widget.textInputAction ?? TextInputAction.next;
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
          textInputAction: _nextAction,
          inputFormatters: widget.inputFormatters,
          focusNode: fieldFocusNode,
          decoration: widget.decoration,
          style: widget.style,
          onChanged: (text) {
            if (text.isEmpty) {
              _options.clear();
            } else {
              if (_options.isEmpty) {
                _options.addAll(_allOptions);
              }
              _options.retainWhere((str) => str.startsWith(text));
              _options = _options.toSet().toList();
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
          onSubmitted: (text) {},
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
                    title: Text(
                      option,
                      style: widget.style,
                    ),
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

  void setNextAction({TextInputAction nextAction = TextInputAction.next}) {
    _nextAction = nextAction;
  }

  void clear() {
    widget.controller.clear();
  }

  void disposeController() {
    _controller.dispose();
  }

  void setFocus() {
    _focusNode.requestFocus();
  }
}

class AutocompletePlace extends StatefulWidget {
  final String type;
  final int searchLength;
  final Function(Place)? onSelect;
  final Function(String)? onChange;

  /// Fetches the places for the text typed - the server matches the start
  /// of the name, ignoring case
  final Future<List<Place>> Function(String)? onUpdateOptionsRequest;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final TextStyle? style;
  final double optionsMaxHeight;
  const AutocompletePlace(
      {super.key,
      this.type = 'email',
      this.searchLength = 1,
      this.onSelect,
      this.onChange,
      this.onUpdateOptionsRequest,
      this.style,
      this.optionsMaxHeight = 200,
      this.decoration,
      this.keyboardType});

  @override
  State<AutocompletePlace> createState() => _AutocompletePlace();
}

class _AutocompletePlace extends State<AutocompletePlace> {
  /// The text last typed - an answer for older text arriving after it is
  /// cut down to the places that still match
  String _latestText = '';

  /// Each change asks the server again rather than filtering the last answer
  /// here: the server returns at most 100 places, so a longer name could be
  /// missing from a shorter one's answer. Filtering here also matched case,
  /// and a desktop browser doesn't capitalise like a phone's keyboard, so
  /// 'london' found nothing.
  Future<Iterable<Place>> _getOptions(String text) async {
    _latestText = text;
    if (text.length < widget.searchLength ||
        widget.onUpdateOptionsRequest == null) {
      return const [];
    }
    List<Place> places = await widget.onUpdateOptionsRequest!(text);
    if (text == _latestText) return places;
    String latest = _latestText.toLowerCase();
    return places.where((place) => place.name.toLowerCase().startsWith(latest));
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Place>(
      optionsMaxHeight: widget.optionsMaxHeight,
      optionsBuilder: (TextEditingValue textEditingValue) =>
          _getOptions(textEditingValue.text),
      displayStringForOption: (option) => option.name,
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          style: widget.style,
          autofocus: true,
          controller: fieldTextEditingController,
          keyboardType: widget.keyboardType,
          focusNode: fieldFocusNode,
          decoration: widget.decoration,
          textCapitalization: TextCapitalization.words,
          onChanged: (text) => widget.onChange?.call(text),
          onSubmitted: (text) {
            debugPrint('$text submitted');
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Place> onSelected, Iterable<Place> options) {
        // Over the map, the list takes the mouse - on the web a click on a
        // place went to the map underneath, so the map never moved to it
        return PointerInterceptor(
            child: Material(
          color: Colors.white60,
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
                  leading: Icon(materialIcon(option.iconData), size: 30),
                  onTap: () {
                    onSelected(option);
                  },
                ),
              );
            }).toList(),
          ),
        ));
      },
      onSelected: (chosen) {
        if (widget.onSelect != null) {
          try {
            widget.onSelect!(chosen);
          } catch (e) {
            debugPrint('Error ${e.toString()}');
          }
        }
      },
    );
  }
}
