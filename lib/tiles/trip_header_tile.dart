import 'package:flutter/material.dart';
import '/classes/my_trip_item.dart';
import '/constants.dart';
import '/helpers/edit_helpers.dart';
import 'dart:developer' as developer;

class TripHeaderController {
  _TripHeaderTileState? _tripHeaderTileState;

  void _addState(_TripHeaderTileState tripHeaderTileState) {
    _tripHeaderTileState = tripHeaderTileState;
  }

  bool get isAttached => _tripHeaderTileState != null;

  void edit() {
    try {
      _tripHeaderTileState?.f_edit();
    } catch (e) {
      developer.log('tripHeaderController.edit() error: ${e.toString()}',
          name: 'h_eading');
    }
  }
}

class TripHeaderTile extends StatefulWidget {
  final CurrentTripItem tripItem;
  final TripHeaderController? controller;
  final Function(int) onUpdate;
  final int index;
  final AppState appState;

  const TripHeaderTile({
    super.key,
    this.controller,
    required this.index,
    required this.tripItem,
    required this.appState,
    required this.onUpdate,
  });

  @override
  State<TripHeaderTile> createState() => _TripHeaderTileState();
}

class _TripHeaderTileState extends State<TripHeaderTile> {
  late final FocusNode fn1;
  late final FocusNode fn2;
  late final FocusNode fn3;
  bool setFocus = false;

  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    fn1 = FocusNode();
    fn2 = FocusNode();
    fn3 = FocusNode();
    fn1.requestFocus();
  }

  @override
  void dispose() {
    fn1.dispose();
    fn2.dispose();
    fn3.dispose();
    super.dispose();
  }

  /// Controller.edit() sets the setFocus flag and calls a setState()
  /// which rebuilds the Widget. With the setFocus flag to true the
  /// rebuild calls fn1.requestFocus();
  void f_edit() async {
    /// developer.log('f_edit() => fn1.requestFocus()', name: '_focus');
    if (mounted) {
      setState(() => setFocus = true);
    }
  }

  /// Problem with TextFormField change focus with the keyboard next / done
  /// For some reason entering the 3rd field would cause the keyboard to
  /// disappear. The only way round it according to Gemini is to explicitly
  /// set the focus for the next TextFormField using RequestFocus()
  /// According to Gemini TextAction.Next / Done is "fragile"

  @override
  Widget build(BuildContext context) {
    developer.log('build TripHeaderTile setFocus: $setFocus', name: '_focus');
    if (setFocus) {
      fn1.requestFocus();
      setFocus = false;
    }

    return Container(
      color: Colors.blue,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextFormField(
              key: Key('tff1'),
              readOnly: widget.appState == AppState.driveTrip,
              focusNode: fn1,
              autofocus: true,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Give your trip a name...',
                labelText: 'Trip name',
                hintStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
              ),
              style: textStyle(context: context, color: Colors.white, size: 2),
              initialValue: widget.tripItem.title,
              onFieldSubmitted: (text) {
                widget.tripItem.title = text;
                widget.onUpdate(widget.tripItem.headerComplete());
                FocusScope.of(context).requestFocus(fn2);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextFormField(
              focusNode: fn2,
              key: Key('tff2'),
              // autofocus: true,
              readOnly: widget.appState == AppState.driveTrip,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a short summary of your trip...',
                labelText: 'Trip summary',
                hintStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
              ),
              style: textStyle(context: context, color: Colors.white, size: 2),
              initialValue: widget.tripItem.subTitle,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (text) {
                widget.tripItem.subTitle = text;
                widget.onUpdate(widget.tripItem.headerComplete());
                FocusScope.of(context).requestFocus(fn3);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextFormField(
              key: Key('tff3'),
              readOnly: widget.appState == AppState.driveTrip,
              focusNode: fn3,
              textAlign: TextAlign.start,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe details of your trip...',
                labelText: 'Trip details',
                hintStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.white, size: 2),
              ),
              style: textStyle(context: context, color: Colors.white, size: 2),
              initialValue: widget.tripItem.body,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (text) {
                widget.tripItem.body = text;
                widget.onUpdate(widget.tripItem.headerComplete());
              },
            ),
          ),
        ],
      ),
    );
  }
}
