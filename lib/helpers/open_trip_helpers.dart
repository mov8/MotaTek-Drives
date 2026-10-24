import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '../constants.dart';

/// Loads [trip] as the current trip and shows it on the Explore map, ready
/// to follow - from Favourites' Load Trip, and when a group drive starts.
/// A group drive in progress ends: it was for the trip being replaced.
Future<void> openTripOnMap(MyTripItem trip) async {
  GroupDriveService().stop();
  // Clear everything left from the previous trip before loading
  CurrentTripItem().clearAll();
  CurrentTripItem().id = trip.id;
  CurrentTripItem().uri = trip.uri;
  CurrentTripItem().title = trip.title;
  CurrentTripItem().subTitle = trip.subTitle;
  CurrentTripItem().author = trip.author;
  CurrentTripItem().authorUri = trip.authorUri;
  CurrentTripItem().images = trip.images;
  CurrentTripItem().imageUrls = trip.imageUrls;
  CurrentTripItem().body = trip.body;
  CurrentTripItem().pointsOfInterest = trip.pointsOfInterest;
  CurrentTripItem().maneuvers = trip.maneuvers;
  CurrentTripItem().routes = trip.routes;
  CurrentTripItem().goodRoads = trip.goodRoads;
  CurrentTripItem().score = trip.score;

  // Loaded, not editing - the chips offer Follow drive and Edit route
  CurrentTripItem().tripState = TripState.loaded;
  // Undo should only apply to changes made after the trip is loaded
  CurrentTripItem().loadBackBuffer();
  CurrentTripItem().markSaved();
  CurrentTripItem().tripType = TripType.none;
  CurrentTripItem().updateMap = true;
  CurrentTripItem().mapUpdates = MapUpdates.updateAll;

  try {
    LatLng position = LatLng(
        CurrentTripItem().pointsOfInterest.first.point.y.toDouble(),
        CurrentTripItem().pointsOfInterest.first.point.x.toDouble());
    MapService().controller?.moveCamera(CameraUpdate.newLatLng(position));
    CurrentTripItem().tripValues.editing();
    // No crosshair until the user taps Edit route
    CurrentTripItem().tripValues.showTarget = false;
    // The map's onIdle works out what's under the crosshair
    CurrentTripItem().waypointIndex = -1;
    CurrentTripItem().waypointState = WaypointState.none;
  } catch (e) {
    developer.log('Error openTripOnMap(): ${e.toString()}', name: 'error');
  }
  // Switch to the existing map page (Explore). context.push('/map') built a
  // second CreateTrip, duplicating the map's GlobalKey.
  MapService().baseShellController?.selectPage(2);
  // Draw the loaded trip. _onIdle only redraws everything while editing, so
  // a loaded trip has to be drawn here. The nudge's onIdle then applies the
  // loaded waypoint filter.
  await CurrentTripItem().refreshMap(change: MapUpdates.updateAll);
}
