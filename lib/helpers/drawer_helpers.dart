
/*
import 'dart:math';
import 'package:drives/screens/screens.dart';
import '../routes/messages.dart';
import '../classes/classes.dart';
import '../models/models.dart';
import '../tiles/tiles.dart';
import '../services/services.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:audioplayers/audioplayers.dart';
import 'package:universal_io/universal_io.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class DrawerHelpers {
  List<Widget> shredPointsOfInterest({int type = -1}) {
    bool expanded = false;
    List<Widget> tiles = [];
    int j = 0;
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if ((![12, 14, 17, 18]
                  .contains(CurrentTripItem().pointsOfInterest[i].type) &&
              type == -1) ||
          CurrentTripItem().pointsOfInterest[i].type == type) {
        tiles.add(
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
            key: Key('poi$i'),
            child: PointOfInterestTile(
              key: Key('poi$i'), // UniqueKey(),
              index: i,
              listIndex: j++,
              controller: _pointOfInterestController,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              imageRepository: imageRepository,
              driveId: CurrentTripItem().driveUri,
              onDelete: (index, lIndex) => pointOfInterestDelete(index, lIndex),
              onUpdate: pointOfInterestComplete,
            ),
          ),
        );
      }
    }
    return tiles;
  }
  List<Widget> shredTrips() {
    List<Widget> tiles = [];

    if (_drawerItems!.isNotEmpty) {
      for (int i = 0; i < _drawerItems!.length; i++) {
        tiles.add(
          TripTile(
            index: i,
            tripItem: _drawerItems![i],
            imageRepository: imageRepository,
          ),
        );
      }
    }
    return tiles;
  }

  void messageDetails(index) {
    setState(() {
      _messageIndex = index;
      _tiles = [
        //  SidebarMessages(),

        Messages(
          index: _messageIndex, // <-- debugging
          onSelect: (index) => messageDetails(index),
          onBackClick: () {
            setState(() => _messageIndex = -1);
          },
        ),
      ];
    });
    // widget.onUpdate!(BottomDrawerItems.messages, index);
    // _messageIndex = index;
    // setContent(BottomDrawerItems.messages, []);
  }

  List<Widget> shredFavourites() {
    List<Widget> tiles = [
      Center(
          child: Text('No information',
              style: TextStyle(fontSize: 20, color: Colors.black)))
    ];

    if ((_drawerItems ?? []).isNotEmpty) {
      tiles.clear();
      for (int i = 0; i < _drawerItems!.length; i++) {
        if (_drawerItems![i] != null) {
          try {
            tiles.add(
              MyTripTile(
                index: i,
                myTripItem: _drawerItems![i],
                onDeleteTrip: (index) =>
                    setState(() => _drawerItems!.removeAt(index)),
                imageRepository: imageRepository,
                onExpandChange: (index, expanded) =>
                    getTripDetails(index, expanded),
                mapController: MapService().controller,
                showMethods: true,
              ),
            );
          } catch (e) {
            developer.log(
                'Error adding a TripTile to the side-drawer content: ${e.toString()}',
                name: 'error');
          }
        }
      }
    }

    return tiles;
  }

  List<Widget> shredGroup({List<Follower>? followers}) {
    followers ??= [];
    List<Widget> tiles = [];
    _tiles.clear();
    bool expanded = false;
    for (int i = 0; i < followers.length; i++) {
      tiles.add(Padding(
        key: expanded ? _scrollKey : Key('th1'),
        padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
        child: FollowerTile(
          follower: followers[i],
          index: i,
          onIconClick: followerIconClick,
          onLongPress: followerLongPress,
          distance: 0,
          currentPosition: CurrentTripItem().tripValues.position, // Point(
          //   CurrentTripItem().tripValues.position.x,
          //   CurrentTripItem().tripValues.pos
          //       .tripValues
          //       .position
          //       .x), // ToDo: calculate how far away
        ),
      ));
    }

    return tiles;
  }

  getTripDetails(index, expanded) async {
    if (expanded && widget._mapController != null) {}
  }

  Future<void> followerIconClick(int index) async {
    String message = ''; // await messageGroup(index);
    if (message.isNotEmpty) {}
    return;
  }

  void followerLongPress(int index) {
    // CurrentTripItem().tripValues.showTarget = true;

    CurrentTripItem().mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble(),
          ),
        ),
        duration: Duration(milliseconds: 300));
    return;
  }

  List<Widget> shredManeuvers() {
    List<Widget> tiles = [];
    _tiles.clear();
    for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
      try {
        tiles.add(
          Card(
            key: Key('mc_$i'),
            child: ManeuverTile(
                index: i,
                maneuver: CurrentTripItem().maneuvers[i],
                routes: CurrentTripItem().routes,
                onLongPress: maneuverLongPress),
          ),
        );
      } catch (e) {
        developer.log('Error preparing maneuvers cards: ${e.toString()}',
            name: 'error');
      }
    }
    return tiles;
  }
  List<Widget> shredCurrentTripItemData() {
    ExpandNotifier expandNotifier = ExpandNotifier(1);
    bool expanded = false;
    int index = 0;
    int selected = -1;
    List<Widget> tiles = [];
    int j = 0;
    if (_content == BottomDrawerItems.trip) {
      // developer.log(
      //     'SideDrawer().shredCurrentTripItemData() called CurrentTripItem().tripState:${CurrentTripItem().tripState.toString()} CurrentTripItem().headerComplete():${CurrentTripItem().headerComplete()}',
      //     name: '_expand_');
      expanded = CurrentTripItem().headerComplete() != 7;
      tiles.add(
        Padding(
          key: Key('th1'),
          padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
          child: TripHeaderTile(
            key: Key('tht_1'),
            index: 0,
            controller: _tripHeaderController,
            tripItem: CurrentTripItem(),
            expanded: false, //!headerComplete,
            appState: CurrentTripItem().appState,
            onUpdate: (complete) => headingComplete(complete),
          ),
        ),
      );

      for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
        if (![
          12,
          14,
          17,
          18
        ] // <-- exclude waypoint, great road start, start & end
            .contains(CurrentTripItem().pointsOfInterest[i].type)) {
          bool complete = CurrentTripItem().pointsOfInterest[i].complete() == 3;
          expanded = !complete;
          tiles.add(
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
              key: Key('poi$i'),
              child: PointOfInterestTile(
                key: Key('poit_${j++}'),
                index: i, // ndex,
                listIndex: j++,
                expanded: false, //!complete || selected == i,
                //   controller: expanded ? _pointOfInterestController : null,
                pointOfInterest: CurrentTripItem().pointsOfInterest[i],
                imageRepository: imageRepository,
                onUpdate: pointOfInterestComplete,
                onDelete: (index, lIndex) =>
                    pointOfInterestDelete(index, lIndex),
                driveId: CurrentTripItem().driveUri,
              ),
            ),
          );
        }
      }
    }
    return tiles;
  }

  List<Widget> shredMessages() {
    List<Widget> tiles = [];
    for (int i = 0; i < CurrentTripItem().tripMessages.length; i++) {
      tiles.add(
        TripMessageTile(
          index: i,
          message: CurrentTripItem().tripMessages[i],
          onEdit: (_) {},
          onSelect: (_) {},
        ),
      );
    }
    return tiles;
  }

  List<Widget> shredCurrentTripItemData() {
    ExpandNotifier expandNotifier = ExpandNotifier(1);
    bool expanded = false;
    int index = 0;
    int selected = -1;
    List<Widget> tiles = [];
    int j = 0;
    if (_content == BottomDrawerItems.trip) {
      // developer.log(
      //     'SideDrawer().shredCurrentTripItemData() called CurrentTripItem().tripState:${CurrentTripItem().tripState.toString()} CurrentTripItem().headerComplete():${CurrentTripItem().headerComplete()}',
      //     name: '_expand_');
      expanded = CurrentTripItem().headerComplete() != 7;
      tiles.add(
        Padding(
          key: Key('th1'),
          padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
          child: TripHeaderTile(
            key: Key('tht_1'),
            index: 0,
            controller: _tripHeaderController,
            tripItem: CurrentTripItem(),
            expanded: false, //!headerComplete,
            appState: CurrentTripItem().appState,
            onUpdate: (complete) => headingComplete(complete),
          ),
        ),
      );

      for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
        if (![
          12,
          14,
          17,
          18
        ] // <-- exclude waypoint, great road start, start & end
            .contains(CurrentTripItem().pointsOfInterest[i].type)) {
          bool complete = CurrentTripItem().pointsOfInterest[i].complete() == 3;
          expanded = !complete;
          tiles.add(
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
              key: Key('poi$i'),
              child: PointOfInterestTile(
                key: Key('poit_${j++}'),
                index: i, // ndex,
                listIndex: j++,
                expanded: false, //!complete || selected == i,
                //   controller: expanded ? _pointOfInterestController : null,
                pointOfInterest: CurrentTripItem().pointsOfInterest[i],
                imageRepository: imageRepository,
                onUpdate: pointOfInterestComplete,
                onDelete: (index, lIndex) =>
                    pointOfInterestDelete(index, lIndex),
                driveId: CurrentTripItem().driveUri,
              ),
            ),
          );
        }
      }
    }
    return tiles;
  }

  void maneuverLongPress(int index) async {
    // CurrentTripItem().tripValues.showTarget = true;

    CurrentTripItem().mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble(),
          ),
        ),
        duration: Duration(milliseconds: 300));

    // debugPrint('index: $index moved: ${moved ?? false}');
    final String fileName = await getSpeech(
        text:
            'Stop the car you idiot, I want to get out', //CurrentTripItem().maneuvers[index].modifier,
        fileName: 'text.mp3');
    if (fileName.isNotEmpty) {
      final bool exists = await File(fileName).exists();
      if (exists) {
        debugPrint('File size: ${File(fileName).lengthSync}');
        DeviceFileSource source = DeviceFileSource(fileName);
        try {
          final player = AudioPlayer(); //..setReleaseMode(ReleaseMode.stop);
          // player.setSourceAsset(fileName);
          player.play(source); //(source);
        } catch (e) {
          debugPrint('Error : ${e.toString()}');
        }
      }
    }
    setState(() => _directions.currentIndex = index);
    return;
  }

  void pointOfInterestDelete(int index, int lIndex) {
    CurrentTripItem().pointsOfInterest.removeAt(index);
    setState(() => _tiles.removeAt(lIndex));
  }

  void headingComplete(bool complete) {
    close();
  }

  void pointOfInterestComplete(bool complete) async {
    CurrentTripItem()
        .refreshMap(change: MapUpdates.pointsOfInterest)
        .then((_) => close());
  }
}
*/