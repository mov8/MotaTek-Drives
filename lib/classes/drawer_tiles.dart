import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/tiles/tiles.dart';

/// The trip being planned, as tiles - the same in the BottomDrawer (phone)
/// and the SideDrawer (web): the trip's details, then its points of
/// interest, great road descriptions among them.
///
/// Everything starts closed except what the user has to fill in: the point
/// of interest just added ([openPointOfInterest] - its index in
/// pointsOfInterest - from the Point of interest chip, or the description of
/// a great road just ended), or the trip's details ([openHeader]) when a
/// save needs them. The open tile gets [openKey], so the drawer can scroll
/// to it, and the controller, so the keyboard can be dismissed.
List<Widget> tripPlanTiles({
  int openPointOfInterest = -1,
  bool openHeader = false,
  required GlobalKey openKey,
  required TripHeaderController headerController,
  required PointOfInterestController pointOfInterestController,
  required ImageRepository imageRepository,
  required void Function(bool) onHeaderUpdate,
  required void Function(bool) onPointOfInterestUpdate,
  required void Function(int, int) onDelete,
}) {
  CurrentTripItem trip = CurrentTripItem();
  List<Widget> tiles = [
    Padding(
      key: openHeader ? openKey : const Key('th1'),
      padding: const EdgeInsets.all(5),
      child: TripHeaderTile(
        // A new tile when it opens - expanded only takes effect then
        key: Key('tht_$openHeader'),
        index: 0,
        controller: headerController,
        tripItem: trip,
        expanded: openHeader,
        appState: trip.appState,
        onUpdate: onHeaderUpdate,
      ),
    ),
  ];
  int listIndex = 1;
  for (int i = 0; i < trip.pointsOfInterest.length; i++) {
    // Waypoints, great road starts, the start and end aren't listed
    if ([12, 14, 17, 18].contains(trip.pointsOfInterest[i].type)) continue;
    bool open = i == openPointOfInterest;
    tiles.add(
      Padding(
        key: open ? openKey : Key('poi$i'),
        padding: const EdgeInsets.all(5),
        child: PointOfInterestTile(
          key: Key('poit_${i}_$open'),
          index: i,
          listIndex: listIndex++,
          expanded: open,
          controller: open ? pointOfInterestController : null,
          pointOfInterest: trip.pointsOfInterest[i],
          imageRepository: imageRepository,
          onUpdate: onPointOfInterestUpdate,
          driveId: trip.uri,
          onDelete: onDelete,
        ),
      ),
    );
  }
  return tiles;
}

/// Where [tripPlanTiles] puts a point of interest's tile in the list
int tripPlanTileIndex(int pointOfInterest) {
  int index = 1; // after the trip's details
  List pointsOfInterest = CurrentTripItem().pointsOfInterest;
  for (int i = 0; i < pointOfInterest && i < pointsOfInterest.length; i++) {
    if (![12, 14, 17, 18].contains(pointsOfInterest[i].type)) index++;
  }
  return index;
}
