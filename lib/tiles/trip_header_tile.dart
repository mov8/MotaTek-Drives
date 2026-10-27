import 'package:flutter/material.dart';
import '/classes/classes.dart'; //   my_trip_item.dart';
import '/constants.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import '/services/services.dart';

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

/// The trip being planned or followed: its name, and to read, its summary
/// and details. They're written in AI assist's TripDetailsPanel - Edit
/// details opens it, as Save trip does.
class _TripHeaderTileState extends State<TripHeaderTile> {
  final ExpansibleController _expandController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void refresh() => setState(() {});

  void clear() => setState(() {});

  void collapse() => _expandController.collapse();

  void expand() => _expandController.expand();

  void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  void _showStart() {
    var routes = widget.tripItem.routes;
    if (routes.isNotEmpty && routes.first.lines.isNotEmpty) {
      List start = routes.first.lines.first;
      MapService().showInView(LatLng(start[1].toDouble(), start[0].toDouble()));
    }
  }

  /// AI assist's panel, to write or change the details
  void _editDetails() {
    PlannerService().saving = null; // Done, not Save trip
    BottomDrawerItems details = BottomDrawerItems.tripDetails;
    kIsWeb
        ? MapService().sideDrawerController?.setContent(content: details)
        : MapService().bottomDrawerController?.setContent(content: details);
  }

  @override
  Widget build(BuildContext context) {
    CurrentTripItem trip = CurrentTripItem();
    TextStyle? small = Theme.of(context).textTheme.bodyMedium;
    return RrExpansionTile(
        context: context,
        child: ExpansionTile(
          leading: const Icon(Icons.directions_car_filled_outlined,
              size: 30, color: Colors.black),
          collapsedBackgroundColor: Colors.white,
          controller: _expandController,
          backgroundColor: Colors.white,
          title: Text(trip.title.isEmpty ? 'Trip details' : trip.title),
          subtitle: trip.subTitle.isEmpty
              ? null
              : Text(trip.subTitle,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
          initiallyExpanded: widget.expanded,
          // Shows the start of the trip being planned
          onExpansionChanged: (expanded) {
            if (expanded) _showStart();
          },
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          children: [
            if (trip.body.isNotEmpty) Text(trip.body, style: small),
            if (trip.headerComplete() == 0)
              Text('Not named or described yet - Save trip will ask for them.',
                  style: small),
            if (widget.appState != AppState.driveTrip)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Edit details'),
                  onPressed: _editDetails,
                ),
              ),
          ],
        ));
  }
}
