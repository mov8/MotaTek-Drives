// A stand-in for the routing server, so trip editing can be tested without
// the network. It answers in the router's own (OSRM) format - see the real
// reply in test/fixtures/router_staines_egham_windsor.json - with a straight
// line between each pair of waypoints and a depart / arrive for each leg.
//
// Use it in a test:
//   final router = FakeRouter()..install();
//   ... add waypoints ...
//   expect(router.requests, hasLength(2));

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:drives/helpers/create_trip_helpers.dart';

class FakeRouter {
  /// The waypoints of each route asked for, as [longitude, latitude]
  final List<List<List<double>>> requests = [];

  /// Set to make the router fail, e.g. 500 - as if the server were down
  int statusCode = 200;

  /// Points along each leg's straight line, including both ends
  final int pointsPerLeg;

  FakeRouter({this.pointsPerLeg = 5});

  void install() => routerHttpGet = _get;

  Future<http.Response> _get(Uri url) async {
    // .../route/v1/driving/-0.51,51.43;-0.53,51.43?steps=true...
    String coordinates = url.path.split('/').last;
    List<List<double>> waypoints = [
      for (String pair in coordinates.split(';'))
        pair.split(',').map(double.parse).toList()
    ];
    requests.add(waypoints);
    if (statusCode != 200) return http.Response('', statusCode);
    return http.Response(jsonEncode(_reply(waypoints)), 200);
  }

  Map<String, dynamic> _reply(List<List<double>> waypoints) {
    List<List<double>> line = [];
    List<Map<String, dynamic>> legs = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      List<double> a = waypoints[i], b = waypoints[i + 1];
      for (int p = (i == 0 ? 0 : 1); p < pointsPerLeg; p++) {
        double t = p / (pointsPerLeg - 1);
        line.add([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
      }
      legs.add({
        'distance': 1000.0,
        'duration': 60.0,
        'steps': [
          {
            'name': 'Road ${i + 1}',
            'distance': 1000.0,
            'maneuver': {
              'type': 'depart',
              'location': a,
              'bearing_before': 0,
              'bearing_after': 90,
            },
          },
          {
            'name': 'Road ${i + 1}',
            'distance': 0.0,
            'maneuver': {
              'type': 'arrive',
              'modifier': 'straight',
              'location': b,
              'bearing_before': 90,
              'bearing_after': 0,
            },
          },
        ],
      });
    }
    return {
      'code': 'Ok',
      'routes': [
        {
          'geometry': {'type': 'LineString', 'coordinates': line},
          'legs': legs,
          'distance': 1000.0 * legs.length,
          'duration': 60.0 * legs.length,
        }
      ],
      'waypoints': [
        for (List<double> w in waypoints) {'location': w, 'name': ''}
      ],
    };
  }
}
