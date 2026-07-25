import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

TextStyle hintStyle({required BuildContext context, color = Colors.blueGrey}) {
  return Theme.of(context).textTheme.bodySmall!.copyWith(color: color);
}

TextStyle titleStyle(
    {required BuildContext context, color = Colors.white, size = 2}) {
  switch (size) {
    case 1:
      return Theme.of(context).textTheme.titleLarge!.copyWith(color: color);
    case 3:
      return Theme.of(context).textTheme.titleSmall!.copyWith(color: color);
    default:
      return Theme.of(context).textTheme.titleMedium!.copyWith(color: color);
  }
}

TextStyle headlineStyle(
    {required BuildContext context, color = Colors.white, size = 2}) {
  switch (size) {
    case 1:
      return Theme.of(context).textTheme.headlineLarge!.copyWith(color: color);
    case 3:
      return Theme.of(context).textTheme.headlineSmall!.copyWith(color: color);
    default:
      return Theme.of(context).textTheme.headlineMedium!.copyWith(color: color);
  }
}

/* overflow: TextOverflow.ellipsis*/

TextStyle textStyle({
  required BuildContext context,
  color = Colors.white,
  int size = 2,
}) {
  switch (size) {
    case 1:
      return Theme.of(context).textTheme.bodyLarge!.copyWith(color: color);
    case 3:
      return Theme.of(context).textTheme.bodySmall!.copyWith(color: color);
    default:
      return Theme.of(context).textTheme.bodyMedium!.copyWith(color: color);
  }
}

TextStyle labelStyle(
    {required BuildContext context, color = Colors.deepPurple, size = 3}) {
  switch (size) {
    case 1:
      return Theme.of(context).textTheme.bodyLarge!.copyWith(color: color);
    case 2:
      return Theme.of(context).textTheme.bodyMedium!.copyWith(color: color);
    default:
      return Theme.of(context).textTheme.bodySmall!.copyWith(color: color);
  }
}

/// LoweCaseTextFormatter sorts the strange problem the Android keyboard
/// has of returning a first letter capitalised string for an email address
/// It's a known issue, and this works well - see login dialog

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      // This preserves the cursor position correctly
      selection: newValue.selection,
    );
  }
}

extension StringOccurrencesExtension on String {
  int countOccurrences(String substring) {
    return split(substring).length - 1;
  }
}

extension StringInsertExtensions on String {
  String insertString(
      {String stringBefore = '', String toInsert = '', bool first = false}) {
    int pos = indexOf(stringBefore);
    if (pos >= 0) {
      return '${substring(0, pos + 1)}$toInsert${substring(pos + 1)}';
    } else {
      return this;
    }
  }
}

extension KeepAfterNthCharacter on String {
  String keepAfter({String delim = ' ', int position = 1}) {
    List elements = split(delim);
    if (position.abs() < elements.length) {
      // if n < 0 then want to return string to include n.abs() delimiters
      position = position < 0 ? elements.length + position : position;
      // removeRange removes elements starting at param 1 and LESS THAN param 2
      elements.removeRange(0, position);
    }
    return elements.join(delim);
  }
}

extension FlutterStateExt on State {
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}

class TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Use a RegEx to find the first letter of every word
    final String transformed = newValue.text.replaceAllMapped(
      RegExp(r'\b(\w)'),
      (match) => match.group(1)!.toUpperCase(),
    );

    // We must return the new value with the selection (cursor) preserved
    return newValue.copyWith(
      text: transformed,
      selection: newValue.selection,
    );
  }
}

class SentenceCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final String text = newValue.text;

    // Logic:
    // 1. (^|\.|\?|\!): Look for start of string OR . ? !
    // 2. \s*: Look for any following whitespace (including newlines)
    // 3. ([a-z]): Capture the first lowercase letter found
    final String transformed = text.replaceAllMapped(
      RegExp(r'(^|[.!?]\s+)([a-z])'),
      (match) {
        // match.group(1) is the punctuation and whitespace
        // match.group(2) is the letter to capitalize
        return '${match.group(1)}${match.group(2)!.toUpperCase()}';
      },
    );

    return newValue.copyWith(
      text: transformed,
      selection: newValue.selection,
    );
  }
}
