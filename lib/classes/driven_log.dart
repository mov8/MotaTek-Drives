import 'dart:math';
import '/helpers/create_trip_helpers.dart' show getDistanceBetween;

/// What following a published trip noted, for "driven by" and visits - only
/// if the user agreed (Setup().verifyDriven). It stays on the phone: only the
/// summary is sent - how many of the trip's turns were passed, how long it
/// took, which of its points of interest the user stopped at - never where
/// they went.
class DrivenLog {
  /// The published trip being followed
  final String tripUri;
  final List<Point> _checkpoints;
  final List<bool> _passed;
  final Map<String, Point> _pointsOfInterest;
  final Map<String, DateTime> _near = {};
  final Set<String> stoppedAt = {};
  DateTime? _first;
  DateTime? _last;

  /// Within this of a turn, it's passed
  static const double passedWithin = 100; // metres
  /// Within this of a point of interest for stopFor, it's a stop
  static const double nearWithin = 100; // metres
  static const Duration stopFor = Duration(minutes: 3);

  /// Point of interest types that aren't places to visit - parking, the
  /// start and end, waypoints, great roads (the app's poiTypes)
  static const Set<int> notVisitable = {7, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19};

  /// checkpoints: the trip's turns (its maneuvers). pointsOfInterest: its
  /// points of interest that can be visited, by uuid.
  DrivenLog({
    required this.tripUri,
    required List<Point> checkpoints,
    required Map<String, Point> pointsOfInterest,
  })  : _checkpoints = checkpoints,
        _passed = List.filled(checkpoints.length, false),
        _pointsOfInterest = pointsOfInterest;

  /// Each position while following
  void update(Point position, DateTime at) {
    _first ??= at;
    _last = at;
    for (int i = 0; i < _checkpoints.length; i++) {
      if (!_passed[i] &&
          getDistanceBetween(startXY: position, endXY: _checkpoints[i]) <=
              passedWithin) {
        _passed[i] = true;
      }
    }
    _pointsOfInterest.forEach((uuid, point) {
      if (getDistanceBetween(startXY: position, endXY: point) <= nearWithin) {
        DateTime since = _near.putIfAbsent(uuid, () => at);
        if (at.difference(since) >= stopFor) stoppedAt.add(uuid);
      } else {
        _near.remove(uuid);
      }
    });
  }

  /// Points along a route's line ([longitude, latitude]s) at least every so
  /// far apart - checkpoints for a trip with no turn instructions
  static List<Point> pointsAlong(List<List<double>> line,
      {double every = 500}) {
    List<Point> points = [];
    for (List<double> lngLat in line) {
      Point point = Point(lngLat[0], lngLat[1]);
      if (points.isEmpty ||
          getDistanceBetween(startXY: points.last, endXY: point) >= every) {
        points.add(point);
      }
    }
    return points;
  }

  int get checkpoints => _checkpoints.length;

  int get passed => _passed.where((p) => p).length;

  int get minutes =>
      _first == null ? 0 : _last!.difference(_first!).inMinutes;

  /// Worth sending - the trip was driven at least a little
  bool get hasSomething => passed > 0 || stoppedAt.isNotEmpty;

  /// What's sent (POST drive/driven)
  Map<String, dynamic> summary() => {
        'drive_id': tripUri,
        'checkpoints': checkpoints,
        'passed': passed,
        'minutes': minutes,
        'stopped_at': stoppedAt.toList(),
      };
}
