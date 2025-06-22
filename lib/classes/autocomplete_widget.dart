import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';

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

class AutocompleteAsync extends StatefulWidget {
  final String type;
  final int searchLength;
  final Function(String)? onSelect;
  final Function(String)? onChange;
  final Function(String)? onUpdateOptionsRequest;
  final List<String> options;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;

  const AutocompleteAsync(
      {super.key,
      required this.options,
      this.type = 'email',
      this.searchLength = 1,
      this.onSelect,
      this.onChange,
      this.onUpdateOptionsRequest,
      this.decoration,
      this.keyboardType});

  @override
  State<AutocompleteAsync> createState() => _AutocompleteAsyncState();
}

class _AutocompleteAsyncState extends State<AutocompleteAsync> {
  String _lastReadQuery = '';
  final List<String> _options = [];
  final List<String> _allOptions = [];
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
        return TextField(
          controller: fieldTextEditingController,
          keyboardType: widget.keyboardType,
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
      onSelected: (chosen) => widget.onSelect!(chosen),
    );
  }
}

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
            //     debugPrint('$text submitted');
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Place> onSelected, Iterable<Place> options) {
//debugPrint(
//            'optionsViewBuilder run - options.length: ${options.length}');
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
                    //          debugPrint('option:${option.name}');
                    // textEditingValue = option.name;
                    onSelected(option);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
      onSelected: (chosen) {
        try {
          //  fieldTextEditingController.text = chosen.name;
          widget.onSelect!(chosen);
        } catch (e) {
          debugPrint('Error ${e.toString()}');
        }
      },
    );
  }
}
