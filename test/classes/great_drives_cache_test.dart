import 'package:drives/classes/great_drives_cache.dart';
import 'package:drives/helpers/geojson_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Published's list of trips (testing, 2026-11-06): it listed every trip
/// fetched for the area round the view, and kept trips that had gone out of
/// view until the zoom changed level
void main() {
  // A trip as the API sends it: its line, and its labels along it
  List trip(String id, double west, double south, double east, double north,
          {int rated = 0}) =>
      [
        {
          'id': id,
          'group': 'line',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [west, south],
              [east, north]
            ]
          },
          'properties': {
            'group': 'line',
            'min_lon': west,
            'min_lat': south,
            'max_lon': east,
            'max_lat': north,
          },
        },
        for (int i = 0; i < 2; i++)
          {
            'id': id,
            'group': 'shield',
            'geometry': {
              'type': 'MultiPoint',
              'coordinates': [
                [west, south],
                [east, north]
              ]
            },
            'properties': {
              'group': 'shield',
              'title': 'Trip $id',
              'distance': 20,
              'rated': rated,
              'rating': '★★★★★',
              'downloads': 0,
            },
          },
      ];

  LatLngBounds view(double west, double south, double east, double north) =>
      LatLngBounds(
          southwest: LatLng(south, west), northeast: LatLng(north, east));

  DrivesRequest cache() => DrivesRequest(onUpdated: (_) {})
    ..read([
      ...trip('fen', 0.0, 52.6, 0.4, 52.8),
      ...trip('dales', -2.2, 54.1, -1.8, 54.3, rated: 3),
    ]);

  test('only the trips in view are listed - once each', () {
    DrivesRequest drives = cache();
    expect([for (var t in drives.inView(view(-0.5, 52.4, 0.6, 53.0))) t.uri],
        ['fen']);
    expect([for (var t in drives.inView(view(-3, 51, 1, 55))) t.uri],
        ['fen', 'dales']);
    expect(drives.inView(view(-5, 50, -4, 51)), isEmpty);
  });

  test('a trip whose details are open stays listed out of view', () {
    DrivesRequest drives = cache()..openTrip = 'dales';
    expect([for (var t in drives.inView(view(-0.5, 52.4, 0.6, 53.0))) t.uri],
        ['fen', 'dales']);
  });

  test('a trip nobody has rated shows empty stars, not five', () {
    DrivesRequest drives = cache();
    List trips = drives.inView(view(-3, 51, 1, 55));
    expect(trips[0].score, '☆☆☆☆☆');
    expect(trips[1].score, '★★★★★'); // rated - the server's stars
    expect(unratedStars(0, '★★★★★'), '☆☆☆☆☆');
    expect(unratedStars(null, null), '☆☆☆☆☆');
    expect(unratedStars(2, '★★★☆☆'), '★★★☆☆');
  });
}
