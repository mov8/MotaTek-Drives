import 'package:flutter/material.dart';

/// Expand notifier is used to expand a ExpansionTile in a list based on a value
/// The expandNotier has one method targetValue(int)
/// A listener can be attached to the notifier in the widget with the expansion
/// tiles initState()
///
///     _expandNotifier.addListener(() {
///      _setExpanded(index: widget.index, target: _expandNotifier.value);
///
/// It is used in PointOfInterestTile to display the content of a point
/// of interest if the user taps the pin on the map.
///
/// The listeners only work once and the calling object has to call
///  _expandNotifier.notifyListeners(); to reset all the listeners

class ExpandNotifier extends ValueNotifier<int> {
  ExpandNotifier(super.value);
  void targetValue({int target = -1}) {
    //   debugPrint('~~~~~ ExpandNotifier.targetValue notifying target: $target');
    value = target;
  }
}
