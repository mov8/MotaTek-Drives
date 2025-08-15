import 'package:drives/services/services.dart'; // hide getPosition;
import 'package:drives/classes/classes.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/models/models.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

enum PinTypes {
  beautySpot,
  pub,
  cafe,
  historicBuilding,
  monument,
  park,
  parking,
  other,
  start,
  end,
  routePoint,
  waypoint,
  goodRoadStart,
  goodRoadEnd,
  newPointOfInterest,
  follower,
  tripStart,
  tripEnd,
}

class Feature extends Marker {
  final int row;
  final String uri;
  final int id;
  final int drive;
  final int type;
  final int poiType;
  final LatLng maxPoint;
  final String pointOfInterestUri;

  const Feature(
      {this.row = -1,
      this.uri = '',
      this.id = -1,
      this.drive = -1,
      this.type = 0,
      this.poiType = 0,
      double iconSize = 30,
      super.width = 30,
      super.height = 30,
      super.child = const Icon(Icons.pin),
      super.point = const LatLng(0, 0),
      this.maxPoint = const LatLng(0, 0),
      this.pointOfInterestUri = ''});

  factory Feature.fromMap({
    required Map<String, dynamic> map,
    int row = -1,
    double size = 30,
    required Function onTap,
  }) {
    return Feature(
      row: row == -1 ? map['row'] ?? -1 : row,
      uri: map['uri'],
      id: -1,
      drive: map['drive'] ?? -1,
      type: map['type'] ?? 0,
      poiType: map['feature_id'] ?? 1,
      point: LatLng(map['min_lat'] ?? 50.0, map['min_lng'] ?? 0.0),
      maxPoint: LatLng(map['max_lat'] ?? 50.0, map['max_lng'] ?? 0.0),
      pointOfInterestUri: map['point_of_interest_uri'] ?? '',
      width: size,
      height: size,
    );
  }

  factory Feature.fromFeature(
      {required Feature feature,
      LatLng? point,
      int? row,
      double? size,
      Widget? child}) {
    return Feature(
        row: row ?? feature.row,
        uri: feature.uri,
        id: feature.id,
        drive: feature.drive,
        type: feature.type,
        poiType: feature.poiType,
        point: point ?? feature.point,
        maxPoint: point ?? feature.maxPoint,
        pointOfInterestUri: feature.pointOfInterestUri,
        width: size ?? feature.width,
        height: size ?? feature.height,
        child: child ?? feature.child);
  }

  Fence getBounds() {
    return Fence(northEast: maxPoint, southWest: point);
  }

  toMap() {
    return {
      'row': row,
      'id': id,
      'uri': uri,
      'feature_id': id,
      'drive': drive,
      'type': type,
      'max_lat': maxPoint.latitude,
      'max_lng': maxPoint.longitude,
      'min_lat': point.latitude,
      'min_lng': point.longitude,
      'point_of_interest_uri': pointOfInterestUri,
    };
  }
}

/// PublishedFeatures - maintains the lists of features and cards based on the
/// camara bounds - the lists it maintains are:
///
/// 1 - features  - a full list of all the available features obtained
///                 from the API or the SQLite cache.
/// 2 - cache     - a subset of the features based on the current
///                 map position with a cache margin.
/// 3 - markers   - a subset of the cache features that are within the
///                 camara's visible bounds that show as Markers on the
///                 map.
/// 4 - cards     - a list of Cards for the appropriate visible features
///                 to be displayed at the bottom of the screen.
///
/// Methods:
///   update(bounds, margin, zoom)
///         bounds -updates the lists based on the camara.visibleBounds
///         margin (in degrees) - determines the size of the cache.
///         zoom -  determins which features are visible - at low
///                 zoom levels markers and cards may be hidden
///
/// Callback:
///   onUpdate(bool) reports back if any of the visible items have changed
///
/// if the camera bounds moves outside the cache bounds the whole
/// features are filtered again to repoulate the cache, the
/// visible list and the cards
///
/// getPublishedFeatures(zoom, pinTap) creates an instance of PublishedFeatures
///     as there aren't asyc constructors in Dart. It populates features
///     from the API or SQLite database.
///     The zoom parameter sets the initial zoom level
///     The pinTap parameter passes the onPinTap callback for the
///     MarkerWidgets that are generated.
///

Future<PublishedFeatures> getPublishedFeatures(
    {double zoom = 10,
    pinTap,
    Function(int, String)? onGetTrip,
    showRoutes = false,
    ExpandNotifier? expandNotifier,
    Map<String, int>? pointOfInterestLookup}) async {
  List<Feature> features = [];
  Map<String, int> pointOfInterestLookup = {};

  features.addAll(await getFeatures(
      zoom: 10, onTap: pinTap, pointOfInterestLookup: pointOfInterestLookup));
  return PublishedFeatures(
    features: features,
    pointOfInterestLookup: pointOfInterestLookup,
    pinTap: pinTap,
    onGetTrip: onGetTrip,
    showRoutes: showRoutes,
    expandNotifier: expandNotifier,
  );
}

class OsmFeatures {
  Function(int)? pinTap;
  List<OsmAmenity> amenities = [];
  Fence? cacheFence = Fence.create();
  OsmFeatures({this.amenities = const [], this.pinTap, this.cacheFence});
  Future<bool> update({required Fence fence, double size = 30}) async {
    try {
      amenities =
          await getOsmAmenities(polygon: fence.polygonString(), size: size);
      debugPrint('amenities polygonString = $amenities');
      return true;
    } catch (e) {
      debugPrint('Error getting OSM data ${e.toString()}');
      return true;
    }
  }

  void resizeOsmAmenities({required double size}) {
    for (int i = 0; i < amenities.length; i++) {
      amenities[i] = OsmAmenity.morph(osmAmenity: amenities[i], size: size);
    }
  }

/*
  void updateMarkers() {
    for (int i = 0; i < amenities.length; i++) {
      amenities[i].

    }
  }
*/
  void clear() {
    amenities.clear();
  }
}

class PublishedFeatures {
  Function(bool)? onUpdate;
  Function(int) pinTap;
  Function(int, String)? onGetTrip;
  List<Feature> features = [];
  List<Feature> cache = [];
  List<Feature> markers = [];
  List<mt.Route> routes = [];
  List<mt.Route> goodRoads = [];
  List<Card> cards = [];
  List<Card> routeCards = [];
  Fence cacheFence = Fence.create();
  List<int> exclude;
  int showZoom;
  bool showRoutes;
  bool updated = false;
  Map<String, int> pointOfInterestLookup = {};
  ExpandNotifier? expandNotifier;
  LatLng screenCenter = LatLng(0, 0);

  final GoodRoadRepository goodRoadRepository = GoodRoadRepository();
  final ImageRepository imageRepository = ImageRepository();
  final RouteRepository routeRepository = RouteRepository();
  final TripItemRepository tripItemRepository = TripItemRepository();
  final PointOfInterestRepository pointOfInterestRepository =
      PointOfInterestRepository();

  PublishedFeatures(
      {required this.features,
      required this.pinTap,
      required this.pointOfInterestLookup,
      this.onGetTrip,
      this.onUpdate,
      this.exclude = const [12, 14, 16, 17, 18],
      this.expandNotifier,
      this.showZoom = 10,
      this.showRoutes = false});

  Future<void> populate({double zoom = 10, onTap}) async {
    features.addAll(await getFeatures(zoom: zoom, onTap: onTap));
    return;
  }

  Future<bool> update({
    required Fence screenFence,
    double zoom = 12,
  }) async {
    if (features.isEmpty) {
      return false;
    }
    screenCenter = screenFence.getCentre(bounds: screenFence);
    bool updateCache = cache.isEmpty;
    bool updateDetails = true;

    if (!cacheFence.contains(bounds: screenFence)) {
      cacheFence = Fence.fromFence(bounds: screenFence, deltaDegrees: 0.5);
      updateCache = true;
    }

    List<Feature> listToFilter = cache;
    if (updateCache) {
      cache.clear();
      routes.clear();
      goodRoads.clear();
      cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
      updateDetails = true;
      listToFilter = features;
    } else if (markers.isEmpty) {
      updateDetails = true;
    } else if (zoom > 11) {
      for (Feature feature in markers) {
        if (!screenFence.contains(bounds: feature.getBounds())) {
          //   debugPrint('Feature ${feature.row}has left the _screenFence');
          updateDetails = true;
          break;
        }
      }
      updateDetails = true;
    }
    if (updateDetails) {
      markers.clear();
      cards.clear();
      routeCards.clear();
      for (Feature feature in listToFilter) {
        switch (feature.type) {
          case 0:
            if (showRoutes &&
                cacheFence.overlapped(bounds: feature.getBounds())) {
              List<mt.Route>? toAdd = await routeRepository.loadRoute(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (toAdd != null) {
                if (updateCache) {
                  routes.addAll(toAdd);
                  cache.add(feature);
                }
                if (zoom >= showZoom) {
                  updateDetails = await addRouteMarker(
                      screenFence: screenFence,
                      routes: toAdd,
                      feature: feature,
                      visibleFeatures: markers,
                      score: 1,
                      pinTap: pinTap,
                      zoom: zoom);
                }
                List<Card> poiCards = [];
                for (Feature poiFeature in features) {
                  if (poiFeature.type != 0 &&
                      poiFeature.drive == feature.drive) {
                    Card? poiCard = await getCard(
                        feature: poiFeature, index: poiCards.length);
                    if (poiCard != null) {
                      poiCards.add(poiCard);
                    }
                  }
                }
                Card? card = await getCard(
                  feature: feature,
                  index: routeCards.length,
                  children: poiCards,
                  expandNotifier: expandNotifier,
                );
                if (card != null) {
                  routeCards.add(card);
                }
              }
            }
            break;
          case 1:
            if ((!exclude.contains(feature.poiType) &&
                    cacheFence.contains(
                      bounds: feature.getBounds(),
                    )) &&
                zoom >= showZoom &&
                updateCache) {
              if ([17, 18].contains(feature.poiType) &&
                  feature.child.runtimeType != EndMarkerWidget) {
                feature = Feature.fromFeature(
                    feature: feature,
                    child: EndMarkerWidget(
                      index: feature.row,
                      begining: feature.poiType == 17,
                      width: 25,
                      color: Colors.white60,
                      onPress: pinTap,
                    ));
              } else if (feature.child.runtimeType != PinMarkerWidget) {
                PointOfInterest? pointOfInterest =
                    await pointOfInterestRepository.loadPointOfInterest(
                        key: feature.row, id: feature.id, uri: feature.uri);
                feature = Feature.fromFeature(
                  feature: feature,
                  child: PinMarkerWidget(
                    index: feature.row,
                    color: feature.poiType == 13
                        ? colourList[Setup().goodRouteColour]
                        : colourList[Setup().pointOfInterestColour],
                    width: zoom * 2,
                    overlay:
                        markerIcon(getIconIndex(iconIndex: feature.poiType)),
                    onPress: pinTap,
                    rating: pointOfInterest!.getScore(),
                  ),
                );
              }
              cache.add(feature);
            }

            if (!exclude.contains(feature.poiType) &&
                screenFence.contains(bounds: feature.getBounds())) {
              markers.add(feature);
              Card? card = await getCard(
                  feature: feature,
                  index: cards.length,
                  expandNotifier: expandNotifier);
              if (card != null) {
                cards.add(card);
              }
              updateDetails = true;
            }
            break;
          case 2:
            if (cacheFence.overlapped(bounds: feature.getBounds())) {
              mt.Route? goodRoad = await goodRoadRepository.loadGoodRoad(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (goodRoad != null) {
                if (updateCache) {
                  goodRoads.add(goodRoad);
                  cache.add(feature);
                }
                if (zoom >= showZoom) {
                  updateDetails = await moveRouteMarker(
                      screenFence: screenFence,
                      route: goodRoad,
                      feature: feature,
                      pinTap: pinTap,
                      zoom: zoom);
                  Card? card = await getCard(
                      feature: feature,
                      index: cards.length,
                      expandNotifier: expandNotifier);
                  if (card != null) {
                    cards.add(card);
                  }
                }
              }
            }
            break;
          default:
            break;
        }
      }

      updated = true;
    } else {
      //   debugPrint('filterFeatures had nothing to update');
    }
    if (onUpdate != null) {
      onUpdate!(updated);
    }
    return updated;
  }

  Future<bool> addRouteMarker(
      {required List<mt.Route> routes,
      required Feature feature,
      required List<Feature> visibleFeatures,
      required Fence screenFence,
      double score = 1,
      Function(int)? pinTap,
      zoom = 12}) async {
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: routes, fence: screenFence);
    if (markerPoint != null && screenFence.containsPoint(point: markerPoint)) {
      visibleFeatures.add(
        Feature.fromFeature(
          feature: feature,
          point: markerPoint,
          child: PinMarkerWidget(
            index: feature.row,
            color: feature.type == 0
                ? colourList[Setup().publishedTripColour]
                : colourList[Setup().goodRouteColour],
            width: (zoom * 2).toDouble(),
            overlay: Icons.route_outlined,
            onPress: pinTap,
            rating: routes[0].rating.toDouble(),
          ),
        ),
      );
    }
    return false;
  }

  Future<bool> moveRouteMarker(
      {required mt.Route route,
      required Feature feature,
      required Fence screenFence,
      Function(int)? pinTap,
      zoom = 12}) async {
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: [route], fence: screenFence);
    Feature? target;
    int index = -1;
    if (markerPoint == null) {
      //    debugPrint('Point not found in fence');
    } else {
      //    debugPrint('point FOUND in fence');
    }
    if (markerPoint != null && screenFence.containsPoint(point: markerPoint)) {
      String uri = feature.pointOfInterestUri;
      if (pointOfInterestLookup.containsKey(uri)) {
        index = pointOfInterestLookup[uri]!;
        target = features[index];
        //     debugPrint('Fence contains feature.row = $index');
      }
      if (target != null && index > -1) {
        bool add = !markers.any((feature) =>
            feature.row ==
            target!
                .row); //true; //!screenFence.containsPoint(point: target.maxPoint);
        Feature moved = Feature.fromFeature(
          feature: target,
          point: markerPoint,
          child: PinMarkerWidget(
            index: target.row, // feature.row ?
            color: target.type == 0 //feature.type ?
                ? colourList[Setup().publishedTripColour]
                : colourList[Setup().goodRouteColour],
            width: (zoom * 2).toDouble(),
            overlay: Icons.route_outlined,
            onPress: pinTap,
          ),
        );
        features[index] = moved;
        if (add) {
          markers.add(moved);
          Card? card = await getCard(feature: moved, index: cards.length);
          if (card != null) {
            cards.add(card);
          }
        }
      }
      return true;
    }
    return false;
  }

/*
  Future<bool> moveRouteMarker(
      {required mt.Route route,
      required Feature feature,
      required List<Feature> cache,
      required List<Feature> visibleFeatures,
      required Fence screenFence,
      Function(int)? pinTap,
      zoom = 12}) async {
    Feature start = feature;
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: [route], fence: screenFence);
    if (markerPoint != null && screenFence.containsPoint(point: markerPoint)) {
      for (Feature feature in cache) {
        if (feature.poiType == 13) {
          PointOfInterest? goodRoadStart =
              await pointOfInterestRepository.loadPointOfInterest(
                  key: feature.row, id: feature.id, uri: feature.uri);
          if (goodRoadStart != null) {
            if (route.pointOfInterestUri == goodRoadStart.url) {
              start = feature;
              break;
            }
          }
        }
      }

      visibleFeatures.add(
        Feature.fromFeature(
          feature: start,
          point: markerPoint,
          child: PinMarkerWidget(
            index: feature.row,
            color: feature.type == 0
                ? colourList[Setup().publishedTripColour]
                : colourList[Setup().goodRouteColour],
            width: (zoom * 2).toDouble(),
            overlay: Icons.route_outlined,
            onPress: pinTap,
          ),
        ),
      );
      return true;
    }
    return false;
  }
*/
  Future<LatLng?> routeMarkerPosition(
      {required List<Polyline> polylines, required Fence fence}) async {
    int first = -1;
    LatLng? pos;
    bool debug = false;
    Fence offsetFence = Fence.fromFence(
        bounds: fence, deltaPercent: -5); //deltaDegrees: -0.015);
    for (int h = 0; h < polylines.length; h++) {
      for (int i = 0; i < polylines[h].points.length; i++) {
        //    debugPrint(
        //        'fence bounds NE: ${offsetFence.northEast.toString()} SW: ${offsetFence.southWest.toString()} point[$i].LatLng(${polyline.points[i].latitude} ${polyline.points[i].longitude})');
        // if (_goodRoad && (i == 0 || i == polylines[h].points.length - 1)) {
        //  debug = true;
        //  debugPrint(
        //      'fence SW lat:${fence.southWest.latitude} lng:${fence.southWest.longitude}  NE lat:${fence.northEast.latitude} lng:${fence.northEast.longitude} - point[$i].LatLng(${polylines[h].points[i].latitude} ${polylines[h].points[i].longitude})');
        // }
        if (offsetFence.containsPoint(
            point: polylines[h].points[i], debug: debug)) {
          first = first < 0 ? i : first;
          pos = polylines[h].points[i];
        } else {
          if (first >= 0) {
            break;
          }
        }
      }
    }
    return pos;
  }

  Future<Card?> getCard({
    required Feature feature,
    required int index,
    List<Card>? children,
    ExpandNotifier? expandNotifier,
  }) async {
    // debugPrint('getCard called for index $index');
    /// getFeatures returns all the features from the API
    /// type 1: drives - id + max/min lat/lng
    /// type 2: points of interest excluding type 12 ad 16 drive start end (12) and followers (16)
    ///         type 3 is the automatically inserted point of imterest
    ///         when a good road is tarted.
    /// type 3: good roads - id + max/min lat/lng
    ///
    /// good_roads.point_of_interest_id ties the point of interest
    /// to the good_roads polylines(mt.route)

    if (feature.type == 0) {
      TripItem tripItem = await tripItemRepository.loadTripItem(
          key: feature.row, id: feature.id, uri: feature.uri);
      tripItem.closest = distanceBetween(
              LatLng(Setup().lastPosition.latitude,
                  Setup().lastPosition.longitude),
              feature.point)
          .truncate();
      // tripItem.closest = 1;
      //  debugPrint('getting trip data ${feature.uri} name ${tripItem.heading}');
      return Card(
        key: Key('pin_${feature.row}'),
        //       elevation: 10,
        //       shadowColor: Colors.grey.withValues(alpha: 125),
        shadowColor: Colors.transparent,
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: TripTile(
          tripItem: tripItem,
          expandNotifier: expandNotifier,
          imageRepository: imageRepository,
          index: index,
          childCards: children,
          onGetTrip: onGetTrip,
        ),
      );
    } else if (feature.type == 1 || feature.type == 6 || feature.type == 3) {
      PointOfInterest? pointOfInterest =
          await pointOfInterestRepository.loadPointOfInterest(
              key: feature.row, id: feature.id, uri: feature.uri);
      // pointOfInterest?.setName('$index. ${pointOfInterest.getName()}');
      return Card(
        key: Key('pin_${feature.row}'),
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: PointOfInterestTile(
          expandNotifier: expandNotifier,
          index: index,
          pointOfInterest: pointOfInterest!,
          imageRepository: imageRepository,
          canEdit: false,
        ),
      );
    }
    return null;
  }
}
