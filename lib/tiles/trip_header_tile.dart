import 'package:flutter/material.dart';
import '/classes/classes.dart'; //   my_trip_item.dart';

import '/constants.dart';
import '/helpers/edit_helpers.dart';
import 'dart:developer' as developer;

class TripHeaderController {
  _TripHeaderTileState? _tripHeaderTileState;

  void _addState(_TripHeaderTileState tripHeaderTileState) {
    _tripHeaderTileState = tripHeaderTileState;
  }

  bool get isAttached => _tripHeaderTileState != null;

  void edit() {}

  void refresh() {
    try {
      _tripHeaderTileState?.refresh();
    } catch (e) {
      developer.log(
          'Error TripHeaderController().refresh() error: ${e.toString()}',
          name: 'error');
    }
  }

  void clear() {
    try {
      _tripHeaderTileState?.clear();
    } catch (e) {
      developer.log(
          'Error TripHeaderController().refresh() error: ${e.toString()}',
          name: 'error');
    }
  }

  void collapse() {
    try {
      _tripHeaderTileState?.collapse();
    } catch (e) {
      developer.log('Error TripHeaderTile().collapse() error: ${e.toString()}',
          name: 'error');
    }
  }

  void dismissKeyboard() {
    try {
      _tripHeaderTileState?.dismissKeyboard();
    } catch (e) {
      developer.log(
          'Error TripHeaderTile().dismissKeyboard() error: ${e.toString()}',
          name: 'error');
    }
  }

  void expand() {
    try {
      _tripHeaderTileState?.expand();
    } catch (e) {
      developer.log('Error TripHeaderTile().collapse() error: ${e.toString()}',
          name: 'error');
    }
  }
}

class TripHeaderTile extends StatefulWidget {
  final CurrentTripItem tripItem;
  final TripHeaderController? controller;
  final Function(bool) onUpdate;
  final int index;
  final AppState appState;
  bool expanded;

  TripHeaderTile({
    super.key,
    this.controller,
    required this.index,
    required this.tripItem,
    required this.appState,
    required this.onUpdate,
    this.expanded = false,
  });

  @override
  State<TripHeaderTile> createState() => _TripHeaderTileState();
}

class _TripHeaderTileState extends State<TripHeaderTile> {
  late final FocusNode fn1;
  late final FocusNode fn2;
  late final FocusNode fn3;
  bool setFocus = false;
  ExpansibleController _expandController = ExpansibleController();
  final TextEditingController _textEditingControllerTitle =
      TextEditingController();
  final TextEditingController _textEditingControllerSubTitle =
      TextEditingController();
  final TextEditingController _textEditingControllerBody =
      TextEditingController();
  bool _initiallyExpanded = false;

  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    fn1 = FocusNode();
    fn2 = FocusNode();
    fn3 = FocusNode();

    _textEditingControllerTitle.text = CurrentTripItem().title;
    _textEditingControllerSubTitle.text = CurrentTripItem().subTitle;
    _textEditingControllerBody.text = CurrentTripItem().body;

    _initiallyExpanded = _textEditingControllerTitle.text.isEmpty ||
        _textEditingControllerSubTitle.text.isEmpty ||
        _textEditingControllerBody.text.isEmpty;

    // developer.log(
    //     'TripHeaderTile().initState _initiallyExpanded: $_initiallyExpanded',
    //     name: '_expand_');
    // fn1.requestFocus();
  }

  @override
  void dispose() {
    fn1.dispose();
    fn2.dispose();
    fn3.dispose();
    _expandController.dispose();
    _textEditingControllerTitle.dispose();
    _textEditingControllerSubTitle.dispose();
    _textEditingControllerBody.dispose();
    super.dispose();
  }

  /// Controller.edit() sets the setFocus flag and calls a setState()
  /// which rebuilds the Widget. With the setFocus flag to true the
  /// rebuild calls fn1.requestFocus();

  void refresh() {
    setState(() {});
  }

  void clear() {
    setState(() {
      _textEditingControllerTitle.text = '';
      _textEditingControllerSubTitle.text = '';
      _textEditingControllerBody.text = '';
    });
  }

  void collapse() {
    _expandController.collapse();
    // setState(() => widget.expanded = false);
  }

  void expand() {
    _expandController.expand();
    //  setState(() => widget.expanded = false);
  }

  void dismissKeyboard() {
    if (mounted) {
      try {
        setState(() {
          fn1.unfocus();
          fn2.unfocus();
          fn3.unfocus();
          collapse();
          FocusManager().primaryFocus?.unfocus();
          // FocusScope.of(context).unfocus();
        });
      } catch (e) {
        developer.log(
            'Error trip_header_tile.dart dismissKeyboard(): ${e.toString}',
            name: 'error');
      }
    }
  }

  void checkComplete() async {
    if (_textEditingControllerTitle.text.isNotEmpty &&
        _textEditingControllerSubTitle.text.isNotEmpty &&
        _textEditingControllerBody.text.isNotEmpty) {
      widget.onUpdate(true);
    }
  }

  /// Problem with TextFormField change focus with the keyboard next / done
  /// For some reason entering the 3rd field would cause the keyboard to
  /// disappear. The only way round it according to Gemini is to explicitly
  /// set the focus for the next TextFormField using RequestFocus()
  /// According to Gemini TextAction.Next / Done is "fragile"

  @override
  Widget build(BuildContext context) {
    if (CurrentTripItem().title.isEmpty || CurrentTripItem().subTitle.isEmpty) {
      _expandController.expand();
    }
    fn1.requestFocus();
    _initiallyExpanded = _textEditingControllerTitle.text.isEmpty ||
        _textEditingControllerSubTitle.text.isEmpty ||
        _textEditingControllerBody.text.isEmpty;
    return RrExpansionTile(
        context: context,
        child: ExpansionTile(
          leading: Icon(Icons.directions_car_filled_outlined,
              size: 30, color: Colors.black),
          collapsedBackgroundColor: Colors.white,
          controller: _expandController,
          backgroundColor: Colors.white,
          title: Text('Trip details'),
          initiallyExpanded: widget.expanded, //_initiallyExpanded,
          children: /*[Text('Test body')]*/
              [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                key: Key('tff1'),
                readOnly: widget.appState == AppState.driveTrip,
                focusNode: fn1,
                controller: _textEditingControllerTitle,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  TitleCaseFormatter()
                ], // <-- Custom extension for Web
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Give your trip a name...',
                  labelText: 'Trip name',
                  hintStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                  labelStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                ),
                style:
                    textStyle(context: context, color: Colors.black, size: 2),
                onChanged: (text) {
                  CurrentTripItem().title = text;
                }, //widget.tripItem.title = text,
                onFieldSubmitted: (text) {
                  CurrentTripItem().title = _textEditingControllerTitle.text;
                  checkComplete();
                  FocusScope.of(context).requestFocus(fn2);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                focusNode: fn2,
                key: Key('tff2'),
                controller: _textEditingControllerSubTitle,
                // autofocus: true,
                readOnly: widget.appState == AppState.driveTrip,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                inputFormatters: [SentenceCaseFormatter()],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a short summary of your trip...',
                  labelText: 'Trip summary',
                  hintStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                  labelStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                ),
                style:
                    textStyle(context: context, color: Colors.black, size: 2),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (text) => CurrentTripItem().subTitle = text,
                onFieldSubmitted: (text) {
                  CurrentTripItem().subTitle =
                      _textEditingControllerSubTitle.text;
                  checkComplete();
                  FocusScope.of(context).requestFocus(fn3);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                key: Key('tff3'),
                readOnly: widget.appState == AppState.driveTrip,
                controller: _textEditingControllerBody,
                focusNode: fn3,
                textAlign: TextAlign.start,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [SentenceCaseFormatter()],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe details of your trip...',
                  labelText: 'Trip details',
                  hintStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                  labelStyle:
                      textStyle(context: context, color: Colors.black, size: 2),
                ),
                style:
                    textStyle(context: context, color: Colors.black, size: 2),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (text) => CurrentTripItem().body =
                    text, //widget.tripItem.body = text,
                onFieldSubmitted: (text) {
                  CurrentTripItem().body = _textEditingControllerBody.text;
                  checkComplete();
                },
              ),
            ),
          ],
        ));
    /*  return RrExpansionTile(
      context: context,
      child: ExpansionTile(
        key: UniqueKey(), // PageStorageKey(widget.index),
        controller: _expandController,
        shape: Border(),
        collapsedBackgroundColor: Colors.white,
        onExpansionChanged: (value) => onExpandChanged(value),
        backgroundColor: Colors.white,
        title: Text(
            widget.tripItem.title.isEmpty
                ? "Enter your trip details"
                : 'Route: ${widget.tripItem.title} details',
            style: titleStyle(context: context, color: Colors.black, size: 2)),
        initiallyExpanded: widget.expanded,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextFormField(
              key: Key('tff1'),
              readOnly: widget.appState == AppState.driveTrip,
              focusNode: fn1,
              controller: _textEditingControllerTitle,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                TitleCaseFormatter()
              ], // <-- Custom extension for Web
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Give your trip a name...',
                labelText: 'Trip name',
                hintStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
              ),
              style: textStyle(context: context, color: Colors.black, size: 2),
              onChanged: (text) {
                CurrentTripItem().title = text;
              }, //widget.tripItem.title = text,
              onFieldSubmitted: (text) {
                checkComplete();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextFormField(
              focusNode: fn2,
              key: Key('tff2'),
              controller: _textEditingControllerSubTitle,
              // autofocus: true,
              readOnly: widget.appState == AppState.driveTrip,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              inputFormatters: [SentenceCaseFormatter()],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a short summary of your trip...',
                labelText: 'Trip summary',
                hintStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
              ),
              style: textStyle(context: context, color: Colors.black, size: 2),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) => CurrentTripItem().subTitle = text,
              onFieldSubmitted: (text) {
                checkComplete();
                FocusScope.of(context).requestFocus(fn3);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextFormField(
              key: Key('tff3'),
              readOnly: widget.appState == AppState.driveTrip,
              controller: _textEditingControllerBody,
              focusNode: fn3,
              textAlign: TextAlign.start,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [SentenceCaseFormatter()],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe details of your trip...',
                labelText: 'Trip details',
                hintStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
                labelStyle:
                    textStyle(context: context, color: Colors.black, size: 2),
              ),
              style: textStyle(context: context, color: Colors.black, size: 2),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) =>
                  CurrentTripItem().body = text, //widget.tripItem.body = text,
              onFieldSubmitted: (text) {
                checkComplete();
              },
            ),
          ),
        ],
      ),
    ); */
  }

  onExpandChanged(value) {
    if (value == true) {
      _expandController.expand();
    } else {
      _expandController.collapse();
    }
  }
}
