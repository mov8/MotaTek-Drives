import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/classes/classes.dart' hide Route;
import '/services/services.dart';
import '/helpers/helpers.dart';
import '/screens/screens.dart';
import 'point_of_interest_tile.dart';
import '/constants.dart';
import '/models/models.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:go_router/go_router.dart';

class MyTripTile extends StatefulWidget {
  final MyTripItem myTripItem;
  final Function(int) onDeleteTrip;
  final void Function(int, bool)? onExpandChange;
  final int index;
  final bool showMethods;
  final ImageRepository? imageRepository;
  final MapLibreMapController? mapController;
  const MyTripTile({
    super.key,
    required this.index,
    required this.myTripItem,
    required this.onDeleteTrip,
    this.onExpandChange,
    this.showMethods = false,
    this.mapController,
    this.imageRepository,
  });

  @override
  State<MyTripTile> createState() => _MyTripTileState();
}

class _MyTripTileState extends State<MyTripTile> {
  Uint8List imageBytes = Uint8List(0);
  @override
  void initState() {
    super.initState();
    if (MapService().controller == null) {}
  }

  @override
  Widget build(BuildContext context) {
    // List<PointOfInterest> pointsOfInterest;
    double webPadding = kIsWeb ? 25 : 0;
    return RrExpansionTile(
      context: context,
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: null,
        title: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Text(
                    widget.myTripItem.title,
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.route),
                        Text(
                          'Distance',
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        ),
                        Text(
                          '${widget.myTripItem.distance.toStringAsFixed(1)} miles',
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.landscape),
                        Text(
                          '${widget.myTripItem.pointsOfInterestCount}',
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        ),
                        Text(
                          'highlights',
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.social_distance),
                        Text(
                          (widget.myTripItem.distanceAway * metersToMiles)
                              .toStringAsFixed(1),
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        ),
                        Text(
                          'miles away',
                          style: labelStyle(
                              context: context, color: Colors.black, size: 3),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(children: [
              Expanded(
                flex: 8,
                child: Text('Saved on ${widget.myTripItem.added}',
                    style: textStyle(
                        context: context, color: Colors.blueGrey, size: 3)),
              ),
            ]),
          ],
        ),
        onExpansionChanged: (expanded) =>
            expandChange(widget.index, expanded), //{
        //   if (widget.onExpandChange != null) {
        //     widget.onExpandChange!(widget.index, expanded);
        //   }
        // },
        children: [
          SizedBox(
            // height: 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.myTripItem.subTitle,
                            style: titleStyle(
                                context: context, color: Colors.black),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if ((widget.myTripItem.photos ?? []).isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: SizedBox(
                              height: kIsWeb ? 450 : 250,
                              child: PhotoCarousel(
                                height: kIsWeb ? 400 : 250,
                                width: kIsWeb ? 500 : 250,
                                photos: widget.myTripItem.photos!,
                                imageRepository: widget.imageRepository!,
                                showCaptions: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.myTripItem.body,
                            style: textStyle(
                                context: context, color: Colors.black),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    if (widget.myTripItem.pointsOfInterest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Points of interest:',
                            textAlign: TextAlign.left,
                            style: titleStyle(
                                context: context, color: Colors.black, size: 2),
                          ),
                        ),
                      ),
                    for (int i = 0;
                        i < widget.myTripItem.pointsOfInterest.length;
                        i++) ...[
                      if (![12, 14, 17, 18]
                          .contains(widget.myTripItem.pointsOfInterest[i].type))
                        Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
                          // Unique per point of interest - siblings can't
                          // share a key (all were 'poit', which failed once a
                          // trip showed two, e.g. a great road description)
                          key: Key('poi_$i'),
                          child: PointOfInterestTile(
                            key: Key('poit_$i'), // UniqueKey(),
                            index: i + 1,
                            pointOfInterest:
                                widget.myTripItem.pointsOfInterest[i],
                            imageRepository:
                                widget.imageRepository ?? ImageRepository(),
                            driveId: widget.myTripItem.uri, //    driveUri,
                            canEdit: false,
                            mapController: widget.mapController,
                            backgroundColor:
                                const Color.fromRGBO(10, 169, 243, 0.158),
                          ),
                        ),
                    ],
                    SizedBox(height: 20),
                    if (imageBytes.isNotEmpty) ...[
                      Text('ImageBytes is not empty.. ${imageBytes.length}'),
                      SizedBox(height: 450, child: Image.memory(imageBytes)),
                      Text('image end'),
                    ],
                    if (widget.myTripItem.showMethods ||
                        widget.showMethods) ...[
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 20),
                          child: Row(children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(webPadding, 0, 5, 10),
                                child: TextButton(
                                  onPressed: () async => loadTrip(widget.index),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.file_open_outlined,
                                        size: 30,
                                      ),
                                      Text(
                                        'Load Trip',
                                        style: textStyle(
                                          context: context,
                                          color: Colors.black,
                                          size: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(webPadding, 0, 5, 10),
                                child: Setup().jwt.isNotEmpty
                                    ? TextButton(
                                        onPressed: () async => publishTrip(),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 30,
                                            ),
                                            Text(
                                              'Publish Trip',
                                              style: labelStyle(
                                                context: context,
                                                color: Colors.black,
                                                size: 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: () async =>
                                            synchroniseTrip(),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.import_export_outlined,
                                              size: 30,
                                            ),
                                            Text(
                                              'Synchronise Trip',
                                              style: labelStyle(
                                                context: context,
                                                color: Colors.black,
                                                size: 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(webPadding, 0, 5, 10),
                                child: TextButton(
                                  onPressed: () => deleteTrip(widget.index),
                                  child: Column(
                                    children: [
                                      Icon(Icons.delete_forever, size: 30),
                                      Text(
                                        'Delete Trip',
                                        style: labelStyle(
                                            context: context,
                                            color: Colors.black,
                                            size: 3),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      // ),
    );
  }

  /// expandChange() updates the map in the web version if the tile is expanded
  Future<void> expandChange(int index, bool expanded) async {
    if (expanded) {
      try {
        if (MapService().controller != null &&
            widget.myTripItem.routes.isNotEmpty) {
          try {
            List<Map<String, dynamic>> jsonRoutes =
                routesToGeoJson(routes: widget.myTripItem.routes);
            await MapService().controller?.setGeoJsonSource("route-data", {
              "type": "FeatureCollection",
              "features": jsonRoutes,
            });
            List<Map<String, dynamic>> jsonEnds =
                routeEndsToGeoJson(routes: widget.myTripItem.routes);
            List coordinates = widget.myTripItem.routes.first.lines.first;
            LatLng start = LatLng(coordinates[1], coordinates[0]);
            await MapService().controller!.setGeoJsonSource("waypoint-data", {
              "type": "FeatureCollection",
              "features": jsonEnds,
            });
            if (kIsWeb) {
              MapService().controller!.animateCamera(
                  CameraUpdate.newLatLng(start),
                  duration: Duration(seconds: 1));
            }
          } catch (e) {
            developer.log('Error showing routes: ${e.toString()}',
                name: 'error');
          }
        }
      } catch (e) {
        developer.log(
            'Error in my_trip_tile.dart expandChange(): ${e.toString()}',
            name: 'error');
      }
    }
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }

  /// Warns the user before an unsaved trip in CurrentTripItem() is replaced
  /// by the saved one.
  Future<void> loadTrip(int index) async {
    if (CurrentTripItem().hasUnsavedChanges) {
      String current = CurrentTripItem().title.isEmpty
          ? 'The trip you are working on'
          : '"${CurrentTripItem().title}"';
      Utility().showOkCancelDialog(
          context: context,
          alertTitle: 'Discard unsaved trip?',
          alertMessage:
              "$current hasn't been saved. Loading \"${widget.myTripItem.title}\" will clear it.",
          okValue: index,
          callback: (value) {
            if (value > -1) _loadTrip();
          });
    } else {
      await _loadTrip();
    }
  }

  Future<void> _loadTrip() async {
    // Clear everything left from the previous trip before loading
    CurrentTripItem().clearAll();
    CurrentTripItem().id = widget.myTripItem.id;
    CurrentTripItem().uri = widget.myTripItem.uri;
    CurrentTripItem().title = widget.myTripItem.title;
    CurrentTripItem().subTitle = widget.myTripItem.subTitle;
    CurrentTripItem().author = widget.myTripItem.author;
    CurrentTripItem().authorUri = widget.myTripItem.authorUri;
    CurrentTripItem().images = widget.myTripItem.images;
    CurrentTripItem().imageUrls = widget.myTripItem.imageUrls;
    CurrentTripItem().body = widget.myTripItem.body;
    CurrentTripItem().pointsOfInterest = widget.myTripItem.pointsOfInterest;
    CurrentTripItem().maneuvers = widget.myTripItem.maneuvers;
    CurrentTripItem().routes = widget.myTripItem.routes;
    CurrentTripItem().goodRoads = widget.myTripItem.goodRoads;
    CurrentTripItem().score = widget.myTripItem.score;

    // Loaded, not editing - the chips offer Follow drive and Edit route
    CurrentTripItem().tripState = TripState.loaded;
    // Undo should only apply to changes made after the trip is loaded
    CurrentTripItem().loadBackBuffer();
    CurrentTripItem().markSaved();
    // CurrentTripItem().tripValues.showTarget = true;
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
      developer.log('Error MyTripTile().loadTrip(): ${e.toString()}',
          name: 'error');
    }
    // Switch to the existing map page (Explore). context.push('/map') built a
    // second CreateTrip, duplicating the map's GlobalKey.
    MapService().baseShellController?.selectPage(2);
    // Draw the loaded trip. _onIdle only redraws everything while editing, so
    // a loaded trip has to be drawn here. The nudge's onIdle then applies the
    // loaded waypoint filter.
    await CurrentTripItem().refreshMap(change: MapUpdates.updateAll);
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: ' ', // _myTripItems[index].heading,
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  /// Trips are stored in Hive - the old SQLite deleteDriveLocal() left them
  /// there, so they came back the next time My Trips loaded
  void onConfirmDeleteTrip(int value) async {
    if (value > -1) {
      // Don't leave the deleted trip on the map, where saving would bring
      // it back without its media
      if (CurrentTripItem().uri.isNotEmpty &&
          CurrentTripItem().uri == widget.myTripItem.uri) {
        await CurrentTripItem().requestClear();
      }
      await TripRepository().deleteTrip(widget.myTripItem);
      if (mounted) {
        setState(() => widget.onDeleteTrip(value));
      }
    }
  }

  Future<void> testSImage() async {
    /* 
   String? base64Image = await js.context.callMethod('getMapSnapshot');
   this little stub executes a js function in Index.html. Keep for further use
  */
  }

/*
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/rng.dart';
*/

  /// May have a problem having a single method for publishing a drive on
  /// both the Web and Android version. The issue is likely to be how to
  /// handle images - Android is simple but the Web may be problematic.

  Future<void> publishTrip() async {
    try {
      // await publish(widget.myTripItem);
      await publish(widget.myTripItem);
    } catch (e) {
      developer.log('Error in my_trip_tile.dart publishTrip()', name: 'error');
    }
    return;
  }

  Future<void> synchroniseTrip() async {
    context.push('/transfer', extra: widget.myTripItem);
    return;
  }
}
