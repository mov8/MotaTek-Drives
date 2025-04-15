import 'package:flutter/material.dart';

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
        debugPrint('You just selected $selection');
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
              if (_lastReadQuery.isEmpty ||
                  (text.length >= widget.searchLength &&
                      !text.startsWith(_lastReadQuery))) {
                widget.onUpdateOptionsRequest!(text);
                _lastReadQuery = text;
              }
            }
          },
          onSubmitted: (text) {
            debugPrint('$text submitted');
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
