import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
// import 'package:latlong2/latlong.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/helpers/edit_helpers.dart';
import 'tiles.dart';
import '/services/services.dart';
import 'dart:developer' as developer;

class TripTile extends StatefulWidget {
  final TripItem tripItem;
  final ImageRepository imageRepository;
  final Function(int, String)? onGetTrip;
  final Function(int, int)? onRatingChanged;
  final Function(int)? onExpand;
  final bool? expanded;
  final MapLibreMapController? mapController;
  final int index;

  const TripTile({
    super.key,
    required this.tripItem,
    required this.imageRepository,
    required this.index,
    this.onGetTrip,
    this.onRatingChanged,
    this.onExpand,
    this.mapController,
    bool? expanded,
  }) : expanded = expanded ?? false;

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  List<Photo> photos = [];
  // String _photoString = '';
  bool isExpanded = false;
  bool expanded = true;
  final List<Card> _childCards = [];
  @override
  void initState() {
    super.initState();
    //  _childCards = [];
    expanded = widget.expanded!;
    photos = photosFromJson(
      photoString: widget.tripItem.imageUrls,
      endPoint: '${widget.tripItem.uri}/',
    );
  }

  expandChange({required bool expanded}) async {
    try {
      if (expanded) {
        await getDetails();
        //  widget.expanded = true;
        if (mounted) {
          setState(() {});
        }
        if (widget.onExpand != null) {
          widget.onExpand!(widget.index);
        }
      } else {
        //  _expansionTileController.collapse();
      }
      //  setState(() => isExpanded = expanded);
    } catch (e) {
      debugPrint('Error tripTile expandChange: ${e.toString()} ');
    }
  }

/*
  expandChange(index, expanded) async {
    // if (widget.onExpandChange != null) {
    //   widget.onExpandChange!(index, expanded);
    // }

    if (expanded) {
      if (widget.tripItem.pointsOfInterestCount > 0) {
        MyTripItem? fullTrip = await getPrivateRepository()
            .loadMyTripItem(uri: widget.myTripItem.uri);
        if (fullTrip != null) {
          setState(() {
            widget.myTripItem.routes = fullTrip.routes;
            widget.myTripItem.goodRoads = fullTrip.goodRoads;
            widget.myTripItem.pointsOfInterest = fullTrip.pointsOfInterest;
          });

          developer.log('Trip name: ${fullTrip.title}', name: '_init_');
        } else {
          developer.log('Trip is null', name: '_init_');
        }
      }
      if (widget.mapController != null && widget.myTripItem.routes.isNotEmpty) {
        try {
          developer.log('Ready to draw routes', name: '_map_');
          List<Map<String, dynamic>> jsonRoutes =
              routesToGeoJson(routes: widget.myTripItem.routes);
          await widget.mapController!.setGeoJsonSource("route-data", {
            "type": "FeatureCollection",
            "features": jsonRoutes,
          });
          List<Map<String, dynamic>> jsonEnds =
              routeEndsToGeoJson(routes: widget.myTripItem.routes);
          List coordinates = widget.myTripItem.routes.first.lines.first;
          LatLng start = LatLng(coordinates[1], coordinates[0]);
          await widget.mapController!.setGeoJsonSource("waypoint-data", {
            "type": "FeatureCollection",
            "features": jsonEnds,
          });
          widget.mapController!.animateCamera(CameraUpdate.newLatLng(start),
              duration: Duration(seconds: 1));
        } catch (e) {
          developer.log('Error showing routes: ${e.toString()}', name: '_map_');
        }
      } else {
        developer.log('Skipped draw routes bit', name: '_map_');
      }
    }
  }
*/
  getDetails() async {
    if (_childCards.isEmpty) {
      try {
        var details = await getTripDetails(uuid: widget.tripItem.uri);
        for (int i = 0; i < details.length; i++) {
          PointOfInterest pointOfInterest =
              PointOfInterest.fromJson(map: details[i]);
          if (![12, 17, 18].contains(pointOfInterest.type)) {
            _childCards.add(
              Card(
                child: PointOfInterestTile(
                  index: i,
                  canEdit: false,
                  pointOfInterest: pointOfInterest,
                  imageRepository: widget.imageRepository,
                  driveId: widget.tripItem.uri,
                ),
              ),
            );
          }
        }
      } catch (e) {
        developer.log(
            'Error TripTile().getDetails() getting trip details: ${e.toString()}',
            name: 'error');
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    /*
    if (widget.tripItem.imageUrls != _photoString) {
      photos = photosFromJson(
          photoString: widget.tripItem.imageUrls, endPoint: '$urlDriveImages/');
      _photoString = widget.tripItem.imageUrls;
    }
    */
    return RrExpansionTile(
      context: context,
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: null,
        title: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                widget.tripItem.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Text(
                    'by: ${widget.tripItem.author}',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.tripItem.added,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                '${widget.tripItem.distance.toStringAsFixed(0)} miles long, ${(widget.tripItem.distanceAway * metersToMiles).toStringAsFixed(0)} miles away.',
                style: textStyle(
                  context: context,
                  color: Colors.black,
                  size: 3,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 12,
                  child: Text(
                    'Downloads (${widget.tripItem.downloads})',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 5),
                    child: Text(
                      widget.tripItem.score,
                      // '${'★' * widget.tripItem.rating.toInt()}${'☆' * (5 - widget.tripItem.rating.toInt())}',
                      style: textStyle(
                        context: context,
                        color: const Color.fromRGBO(255, 196, 0, 0.918),
                        size: 1,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    ' (${widget.tripItem.scored})',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        initiallyExpanded: expanded,
        onExpansionChanged: (value) => expandChange(expanded: value),
        leading: Expanded(
          flex: 1,
          child: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              getInitials(name: widget.tripItem.author),
            ),
          ),
        ),
        /* Icon(Icons.route,
              size: 25, color: colourList[Setup().publishedTripColour]), */
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.tripItem.imageUrls.isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              // height: 350,
                              child: PhotoCarousel(
                                imageRepository: widget.imageRepository,
                                photos: widget.tripItem.tripPhotos,
                                height: 300,
                                width: MediaQuery.of(context).size.width - 50,
                              ),
                            ),
                          )
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
                            widget.tripItem.subTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.tripItem.body,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    /*
                      if (widget.tripItem.author.isNotEmpty)
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      getInitials(name: widget.tripItem.author),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 7,
                                  child: Text(
                                    widget.tripItem.author,
                                    style: textStyle(
                                      context: context,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.group_add),
                                        onPressed: () => (setState(() {})),
                                      ),
                                      //   const Text('follow'),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        */
                    if (_childCards.isNotEmpty)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Text(
                              'Points of interest...',
                              style: titleStyle(
                                context: context,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ..._childCards,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  changeRating(value) {
    if (widget.tripItem.uri.isNotEmpty) {
      putDriveRating(widget.tripItem.uri, value);
      if (widget.onRatingChanged != null) {
        widget.onRatingChanged!(value, widget.index);
      }
      setState(() => widget.tripItem.rating = value.toDouble());
    }
  }

  getTrip(value) {
    if (widget.onGetTrip != null) {
      widget.onGetTrip!(widget.index, widget.tripItem.uri);
    }
  }
}
