import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/classes/route.dart';

/// The issue of slow data loading is to be addressed by only retrieving the data
/// needed. A geofence will be calculated that will contain a customisable
/// number of screens worth of data, or all the data from a given radius from
/// a point.

/// A Drive contains three types of data - all have a drive_id
///   Points of interest with a single LatLng position
///   Route polylines containin multiple LatLng points
///   GoodRoad polylines contain multiple polylines
/// Each Drive has a min_lat, max_lat, min_long and max_long that is set by
/// looking at the Route and GoodRoad polylines.
///
/// The Trips route will only show polylines at zoom >= 12 below that
/// it'll only show features as pins. Probably should only show pins
/// for GoodRoads and PointsOfInterest
///
/// GoodRoads does have a min_lat, max_lat, min_long and max_long so it
/// should be possible tp identify those in the geofence without having to
/// reference the Drive. They are Drive children, but can stand on their on
/// too
///
/// Polylines don't have a min_lat, max_lat, min_long and max_long as they
/// are children of a Drive which does.
///
/// PointsOfInterest only have a single locatiuon reference - latitude and
/// longitude. They do have a drive_id. They are Drive children, but can stand
/// on their own too.
///
/// Caching strategey-
///   A [List<Feature>] is pulled from the API or the local db - a last_updated
///   flag will dertermine which.
///   The Feature list will hold uri, feature_type, lat and lng:
///     type 1 - Drives
///     type 2 - GoodRoads
///     type 3 - PointsOfInterest
///
/// Once the geofence has been set then the Features list will be filtered
/// for those features that are within the geofence. If in scope of the fence the
/// data will be loaded from the API, local db or the cache.
///
/// When the page is destroyed the Features list will be written to the
/// local db along with any fetched data - PointsOfInteres, GoodRoads,
/// Routes, Drives and images.
///
/// This should speed up the loading of data, reduce network traffic,
/// and allow the apop to be used in poor coverage areas.
///

Fence changeFenceByDegrees({required Fence fence, double degrees = 0.5}) {
  LatLng ne = LatLng(
      fence.northEast.latitude + degrees, fence.northEast.longitude + degrees);
  LatLng sw = LatLng(
      fence.southWest.latitude - degrees, fence.southWest.longitude - degrees);
  return Fence(northEast: ne, southWest: sw);
}

LatLng setFence({required LatLng location, required double margin}) {
  /// One degree latitude is ~ 69.172 miles
  /// One degree longitude at the Equator is ~ 69.172 miles
  /// E-W delta * degree long = (Lat degrees decimal - 90) * Pi / 180
  double longMargin =
      1 / ((90 - (location.latitude + margin)) * pi / 180).abs() * margin;
  return LatLng(location.latitude + margin, location.longitude + longMargin);
}

class Fence {
  LatLng northEast;
  LatLng southWest;
  Fence({required this.northEast, required this.southWest});
  factory Fence.fromBounds(LatLngBounds bounds) {
    return Fence(northEast: bounds.northEast, southWest: bounds.southWest);
  }

  factory Fence.fromDoubles(
      double neLat, double neLng, double swLat, double swLng) {
    return Fence(
        northEast: LatLng(neLat, neLng), southWest: LatLng(swLat, swLng));
  }

  factory Fence.fromFence(
      {required Fence bounds,
      double deltaDegrees = 0.0,
      double deltaPercent = 0}) {
    if (deltaPercent != 0) {
      deltaDegrees = (bounds.northEast.latitude - bounds.southWest.latitude) /
          100 *
          deltaPercent;
    }
    return Fence(
        northEast: LatLng(bounds.northEast.latitude + deltaDegrees,
            bounds.northEast.longitude + deltaDegrees),
        southWest: LatLng(bounds.southWest.latitude - deltaDegrees,
            bounds.southWest.longitude - deltaDegrees));
  }

  Fence.create(
      {this.northEast = const LatLng(0, 0),
      this.southWest = const LatLng(0, 0)});

  bool contains({required Fence bounds}) {
    bool ok = southWest.latitude <= bounds.southWest.latitude;
    ok = ok && northEast.latitude >= bounds.northEast.latitude;
    ok = ok && southWest.longitude <= bounds.southWest.longitude;
    ok = ok && northEast.longitude >= bounds.northEast.longitude;
    return ok;
  }

  LatLng getCentre({required Fence bounds}) {
    double lat = bounds.southWest.latitude +
        ((bounds.northEast.latitude - bounds.southWest.latitude) / 2);
    double lng = bounds.southWest.longitude +
        ((bounds.northEast.longitude - bounds.southWest.longitude) / 2);
    return LatLng(lat, lng);
  }

  bool containsPoint({required LatLng point, bool debug = false}) {
    return (southWest.latitude <= point.latitude &&
        northEast.latitude >= point.latitude &&
        southWest.longitude <= point.longitude &&
        northEast.longitude >= point.longitude);
  }

  bool overlapped({required Fence bounds}) {
    return bounds.southWest.latitude < northEast.latitude &&
        bounds.northEast.latitude > southWest.latitude &&
        bounds.northEast.longitude > southWest.longitude &&
        bounds.southWest.longitude < northEast.longitude;
  }

  void setBounds({required Fence bounds, double deltaDegrees = 0.0}) {
    northEast = LatLng(bounds.northEast.latitude + deltaDegrees,
        bounds.northEast.longitude + deltaDegrees);
    southWest = LatLng(bounds.southWest.latitude - deltaDegrees,
        bounds.southWest.longitude - deltaDegrees);
  }

  void changeBounds(
      {required LatLngBounds latlngBounds, double deltaDegrees = 0.0}) {
    northEast = LatLng(latlngBounds.northEast.latitude + deltaDegrees,
        latlngBounds.northEast.longitude + deltaDegrees);
    southWest = LatLng(latlngBounds.southWest.latitude - deltaDegrees,
        latlngBounds.southWest.longitude - deltaDegrees);
  }

  String polygonString() {
    return '${southWest.latitude} ${southWest.longitude},${northEast.latitude} ${southWest.longitude}, ${northEast.latitude} ${northEast.longitude}, ${southWest.latitude} ${northEast.longitude}, ${southWest.latitude} ${southWest.longitude}';
  }

  @override
  String toString() {
    return 'SW:${southWest.latitude} ${southWest.longitude} NE:${northEast.latitude} ${southWest.longitude}';
  }
}

Fence fenceFromPolylines({required Route polyline, margin = 0}) {
  double maxLat = -90;
  double minLat = 90;
  double maxLong = -180;
  double minLong = 180;
  return Fence(
      northEast: LatLng(maxLat - margin, maxLong + margin),
      southWest: LatLng(minLat + margin, minLong - margin));
}

/// Checks whether [bounds] is contained within [fence]
///           ^ +90
///   -180 <     > +180
///           v -90
///

bool containsBounds({required Fence fence, required Fence bounds}) {
  return (fence.southWest.latitude <= bounds.southWest.latitude) &&
      (fence.northEast.latitude >= bounds.northEast.latitude) &&
      (fence.southWest.longitude <= bounds.southWest.longitude) &&
      (fence.northEast.longitude >= bounds.northEast.longitude);
}

bool isOutside({required Fence fence, required LatLng location}) {
  return (location.latitude < fence.southWest.latitude ||
      location.longitude < fence.southWest.longitude ||
      location.latitude > fence.northEast.latitude ||
      location.longitude > fence.northEast.longitude);
}

/// Checks whether at least one edge of [bounds] is overlapping with some
/// other edge of [fence]
///
bool isOverlapping({required Fence fence, required Fence bounds}) {
  /// LatLngBounds bounds) {
  /// check if bounding box rectangle is outside the other, if it is then it's
  ///  considered not overlapping

  /// Want to check that bounds rectangle overlaps the fence rectangle
  /// bounds SW.latitude < fence NE.latitude and
  /// bounds NE.latitude > fence SW.latitude and
  /// bounds NE.longitude > fence SW.longitude and
  /// bounds SW.longitude < fence NW.longitude

  return bounds.southWest.latitude < fence.northEast.latitude &&
      bounds.northEast.latitude > fence.southWest.latitude &&
      bounds.northEast.longitude > fence.southWest.longitude &&
      bounds.southWest.longitude < fence.northEast.longitude;

  ///  if (bounds.southWest.latitude > fence.northEast.latitude ||
  ///      bounds.northEast.latitude < fence.southWest.latitude ||
  ///      bounds.northEast.longitude < fence.southWest.longitude ||
  ///      bounds.southWest.longitude > fence.northEast.longitude) {
  ///    return false;
  ///  }
  /// return true;
}
