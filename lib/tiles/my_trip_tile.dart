//import 'package:universal_io/universal_io.dart';
// import 'dart:js' as js; //_interop' as js1;
// import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/classes/classes.dart' hide Route;
// import '/models/other_models.dart';
import '/services/services.dart';
import '/helpers/helpers.dart';
import '/screens/screens.dart';
import 'point_of_interest_tile.dart';
import '/constants.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
            Row(children: [
              Expanded(
                flex: 8,
                child: Text(widget.myTripItem.title,
                    style: headlineStyle(
                        context: context, color: Colors.black, size: 2)),
              ),
            ]),
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
                          key: Key('poit'),
                          child: PointOfInterestTile(
                            key: Key('poit_$i'), // UniqueKey(),
                            index: i + 1,
                            pointOfInterest:
                                widget.myTripItem.pointsOfInterest[i],
                            imageRepository:
                                widget.imageRepository ?? ImageRepository(),
                            driveId: widget.myTripItem.uri, //    driveUri,
                            canEdit: true, //false,
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
                                child: TextButton(
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

  expandChange(index, expanded) async {
    if (expanded) {
      try {
        if (widget.myTripItem.pointsOfInterest.isEmpty) {
          MyTripItem? fullTrip = await getPrivateRepository()
              .loadMyTripItem(uri: widget.myTripItem.uri);
          if (fullTrip != null) {
            setState(() {
              widget.myTripItem.routes = fullTrip.routes;
              widget.myTripItem.goodRoads = fullTrip.goodRoads;
              widget.myTripItem.pointsOfInterest = fullTrip.pointsOfInterest;
            });
          }
        }
        if (MapService().controller != null &&
            widget.myTripItem.routes.isNotEmpty) {
          try {
            List<Map<String, dynamic>> jsonRoutes =
                routesToGeoJson(routes: widget.myTripItem.routes);
            await MapService().controller!.setGeoJsonSource("route-data", {
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
            MapService().controller!.animateCamera(
                CameraUpdate.newLatLng(start),
                duration: Duration(seconds: 1));
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
  Future<void> loadTrip(int index) async {
    // CurrentTripItem.reset();
    // CurrentTripItem().clearAll(newTripState: TripState.loaded);
    // fromMyTripItem({required MyTripItem myTripItem})
    // /load_private/<uri>

    // MyTripItem? myTripItem = await PrivateStorageLocal()
    //     .loadMyTripItem(uri: _myTripItems[index].uri);

    widget.myTripItem; // _myTripItems[index];

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
    CurrentTripItem().tripState = TripState.loaded;
    CurrentTripItem().tripType = TripType.none;
    CurrentTripItem().updateMap = true;
    CurrentTripItem().mapUpdates = MapUpdates.updateAll;

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, 'createTrip', (Route<dynamic> route) => false, //,
          arguments: TripArguments(trip: widget.myTripItem, origin: 'db'));
    }
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: ' ', // _myTripItems[index].heading,
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) async {
    if (value > -1) {
      getPrivateRepository().deleteDriveLocal(tripItem: widget.myTripItem).then(
            (_) => setState(
              () => widget.onDeleteTrip(value),
            ),
          );
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
      await getPrivateRepository().publish(widget.myTripItem);
    } catch (e) {
      developer.log('Error in my_trip_tile.dart publishTrip()', name: 'error');
    }
    return;
  }
}
