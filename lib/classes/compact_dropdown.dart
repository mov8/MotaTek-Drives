import 'package:flutter/material.dart';
import 'dart:developer' as developer;

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
          dropdownColor: const Color.fromRGBO(3, 1, 109, 0.337),
          // mouseCursor: MouseCursor.uncontrolled,
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white), // Smaller font for web/dialogs
          items: widget.items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: widget.renderChild != null
                  ? widget.renderChild!(item)
                  : Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                          "${item.toString().split('.').last}${widget.suffix}")),
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
