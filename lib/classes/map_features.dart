import 'dart:math';
import '/services/services.dart'; // hide getPosition;
import '/classes/classes.dart';
import '/tiles/tiles.dart';
import '/classes/route.dart' as mt;
import '/models/models.dart';
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

class Feature {
  final int row;
  final String uri;
  final int id;
  final int drive;
  final int type;
  final int poiType;
  final Point point;
  final Point maxPoint;
  final String pointOfInterestUri;

  const Feature(
      {this.row = -1,
      this.uri = '',
      this.id = -1,
      this.drive = -1,
      this.type = 0,
      this.poiType = 0,
      double iconSize = 30,
      this.point = const Point(0, 0),
      this.maxPoint = const Point(0, 0),
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
      point: Point(map['max_lng'] ?? 0.0, map['max_lat'] ?? 50.0),
      maxPoint: Point(map['max_lng'] ?? 0.0, map['max_lat'] ?? 50.0),
      pointOfInterestUri: map['point_of_interest_uri'] ?? '',
    );
  }

  factory Feature.fromFeature(
      {required Feature feature,
      Point? point,
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
    );
  }
/*
  Fence getBounds() {
    return Fence(northEast: maxPoint, southWest: point);
  }
  */

  toMap() {
    return {
      'row': row,
      'id': id,
      'uri': uri,
      'feature_id': id,
      'drive': drive,
      'type': type,
      'max_lat': maxPoint.y.toDouble(),
      'max_lng': maxPoint.x.toDouble(),
      'min_lat': point.y.toDouble(),
      'min_lng': point.x.toDouble(),
      'point_of_interest_uri': pointOfInterestUri,
    };
  }
}
