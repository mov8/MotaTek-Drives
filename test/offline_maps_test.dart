import 'package:drives/services/offline_maps_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offline maps cover only the trip: boxes along its route, a new one every
/// stretch of road, and an estimate of the tiles - so a trip can be refused
/// before it downloads half the country
void main() {
  // Staines to Windsor, roughly west - about 11 km, as [lng, lat]
  List<List<double>> stainesToWindsor = [
    for (int i = 0; i <= 20; i++) [-0.51 - i * 0.0075, 51.43 + i * 0.0015]
  ];

  test('a box every stretch of road, with a margin either side', () {
    var boxes = OfflineMapsService.boxesAlong(stainesToWindsor);
    expect(boxes.length, 2); // 10 km, then the rest
    var first = boxes.first;
    expect(first.southwest.latitude, lessThan(51.43 - 0.017)); // 2 km margin
    expect(first.northeast.longitude, greaterThan(-0.51 + 0.028));
    // the second starts where the first ended - no gap in the map
    expect(boxes[1].southwest.longitude,
        lessThan(first.southwest.longitude + 0.03 + 0.03));
  });

  test('no route, no boxes', () {
    expect(OfflineMapsService.boxesAlong([]), isEmpty);
    expect(OfflineMapsService.boxesAlong([
      [-0.51, 51.43]
    ]), isEmpty);
  });

  test("a short trip's tiles are well within the cap; the country isn't", () {
    int trip = OfflineMapsService.countTiles(
        OfflineMapsService.boxesAlong(stainesToWindsor));
    expect(trip, greaterThan(20));
    expect(trip, lessThan(OfflineMapsService.mostTiles ~/ 10));
    // a line from Land's End to John o' Groats - 1,000 km
    List<List<double>> length = [
      for (int i = 0; i <= 500; i++)
        [-5.7 + i * (2.7 / 500), 50.07 + i * (8.57 / 500)]
    ];
    expect(OfflineMapsService.countTiles(OfflineMapsService.boxesAlong(length)),
        greaterThan(OfflineMapsService.mostTiles));
  });
}
