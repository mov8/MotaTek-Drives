import 'package:universal_io/universal_io.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '/classes/route.dart' as mt;
import '/classes/classes.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '/helpers/edit_helpers.dart';

class OfflineTiles {
  static const double EARTH_CIRCUMFERENCE = 40075016.686; // meters
  static const double TILE_SIZE = 256.0;
  // double _downloadSize = 0.5;
  bool _download = true;
  int _toDownload = 0;
  int _maxZoom = 13; //
  double _percentDownloaded = 0;
  //  Fence _bounds = Fence(northEast: LatLng(0, 0), southWest: LatLng(0, 0));
  double _zoom = 0.5;
  double _cover = 0.5;
  mt.Route _route = mt.Route(points: [LatLng(0, 0)]);
  Function(double downloaded)? _updateDownloaded;
  bool _cancel = false;
  Set<TileIdentity> _tilesToDownload = {};

  VectorTileProvider apiProvider;
  BuildContext context;
  List<mt.Route> routes;

  OfflineTiles(
      {required this.context, required this.apiProvider, required this.routes});

  /// Converts latitude to Mercator Y pixel coordinate at a given zoom.
  static double _latToPixelY(double lat, int z) {
    double sinLat = sin(lat * pi / 180);
    double y = 0.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi);
    return y * (TILE_SIZE * pow(2, z));
  }

  /// Converts longitude to Mercator X pixel coordinate at a given zoom.
  static double _lonToPixelX(double lon, int z) {
    double x = (lon + 180) / 360;
    return x * (TILE_SIZE * pow(2, z));
  }

  /// Calculates the tile Y index from latitude and zoom.
  static int latToTileY(double lat, int z) {
    return (_latToPixelY(lat, z) / TILE_SIZE).floor();
  }

  /// Calculates the tile X index from longitude and zoom.
  static int lonToTileX(double lon, int z) {
    return (_lonToPixelX(lon, z) / TILE_SIZE).floor();
  }

  mt.Route routesFlatten({required List<mt.Route> routes}) {
    mt.Route route = mt.Route(points: []);
    for (int i = 0; i < routes.length; i++) {
      route.points.addAll(routes[i].points);
    }
    return route;
  }
/*
  Future<bool> downloadMaps2(
      {required List<mt.Route> routes,
      int minZoom = 12,
      int maxZoom = 13,
      bool clearFirst = true,
      bool showDialog = true}) async {
    bool ok = true;

    mt.Route route = mt.Route(points: []);
    for (int i = 0; i < routes.length; i++) {
      route.points.addAll(routes[i].points);
    }

    return ok;
  }
  */

  Set<TileIdentity> tilesToDownload(
      {required double margin, double zoom = 0.5}) {
    Fence bounds = fenceFromPolylines(polyline: _route, margin: margin);
    int minZoom = _maxZoom - (3 * zoom).toInt();
    Set<TileIdentity> tiles = getTilesInBounds(bounds, minZoom, _maxZoom);
    _toDownload = tiles.length;
    _zoom = zoom;
    _cover = margin;
    _tilesToDownload = tiles;
    return tiles;
  }

  Future<bool> downloadTiles({required Set<TileIdentity> tiles}) async {
    bool ok = false;
    Uint8List? data = Uint8List.fromList([]);
    Directory? cacheDirectory;
    cacheDirectory ??= await getCache();
    List files = cacheDirectory.listSync();
    List fileNames = [];
    int lastPercent = 0;
    int percent = 0;
    int downloaded = 0;
    for (int i = 0; i < files.length; i++) {
      fileNames
          .add(files[i].path.substring(files[i].path.lastIndexOf('/') + 1));
    }
    _cancel = false;
    debugPrint('cache contains ${files.length}');
    for (TileIdentity tile in tiles) {
      String fileName = '_${tile.z}_${tile.x}_${tile.y}.pbf';
      File mapFile = File('${cacheDirectory.path}/$fileName');
      if (!fileNames.contains(fileName)) {
        data = await apiProvider.provide(tile);
        await mapFile.writeAsBytes(data);
      } else {
        fileNames.removeWhere((file) => file == fileName);
      }
      percent = ((++downloaded * 100) ~/ tiles.length);
      if (percent > lastPercent) {
        try {
          _updateDownloaded!(percent / 100);
        } catch (e) {
          debugPrint('error notifying ${e.toString()}');
        }
        lastPercent = percent;
      }
      if (_cancel) {
        break;
      }
    }
    for (String fileName in fileNames) {
      File file = File('${cacheDirectory.path}/$fileName');
      file.delete();
    }
    return ok;
  }

  int downloaded() {
    return 1;
  }

  Future<bool> downloadMaps() async {
    _route = routesFlatten(routes: routes);
    _tilesToDownload = tilesToDownload(margin: 0.5);
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            _updateDownloaded =
                (value) => setState(() => _percentDownloaded = value);
            return AlertDialog(
              title: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
                child: Text(
                  'Download offline maps?',
                  style:
                      textStyle(context: context, size: 2, color: Colors.black),
                ),
              ),
              content: SizedBox(
                width: 150,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Offline maps with ${(50 * _cover).toInt()} mile margin',
                            style: textStyle(
                                context: context, size: 3, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                    Slider(
                      value: _cover,
                      min: 0,
                      max: 1,
                      divisions: 3,
                      onChanged: (double value) => setState(
                          () => tilesToDownload(margin: value, zoom: _zoom)),
                      year2023: false,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Scaling - zoom levels ${_maxZoom - (3 * _zoom).toInt()} - 13',
                            style: textStyle(
                                context: context, size: 3, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                    Slider(
                      value: _zoom,
                      min: 0,
                      max: 1,
                      divisions: 2,
                      onChanged: (double value) => setState(
                          () => tilesToDownload(margin: _cover, zoom: value)),
                      year2023: false,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            ' $_toDownload tiles to download - ${(_percentDownloaded * 100).toStringAsFixed(1)}% done',
                            style: textStyle(
                                context: context, size: 3, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    LinearProgressIndicator(
                      minHeight: 10,
                      value: _percentDownloaded,
                      year2023: false,
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(_download ? 'Download' : 'Cancel',
                      style: textStyle(
                          context: context, size: 2, color: Colors.deepPurple)),
                  onPressed: () => setState(() => downloadCancel()),
                ),
                TextButton(
                  child: Text('Dismiss',
                      style: textStyle(
                          context: context, size: 2, color: Colors.deepPurple)),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        );
      },
    );
    return false;
  }

  downloadCancel() {
    if (_download) {
      downloadTiles(tiles: _tilesToDownload);
      _download = false;
    } else {
      _cancel = true;
      _download = true;
    }
  }

  /// Get a set of unique tiles (z, x, y) that cover a given LatLngBounds
  /// for a range of zoom levels.
  static Set<TileIdentity> getTilesInBounds(
      Fence bounds, int minZoom, int maxZoom) {
    final Set<TileIdentity> tilesToDownload = {};

    for (int z = minZoom; z <= maxZoom; z++) {
      // Calculate tile X range
      int minTileX = lonToTileX(bounds.southWest.longitude, z);
      int maxTileX = lonToTileX(bounds.northEast.longitude, z);
      if (minTileX > maxTileX) {
        // Handle international date line crossing (simplified)
        int temp = minTileX;
        minTileX = maxTileX;
        maxTileX = temp;
      }

      // Calculate tile Y range (note: maxLat gives smaller Y, minLat gives larger Y)
      int minTileY = latToTileY(bounds.northEast.latitude, z);
      int maxTileY = latToTileY(bounds.southWest.latitude, z);
      if (minTileY > maxTileY) {
        // Ensure min is truly min
        int temp = minTileY;
        minTileY = maxTileY;
        maxTileY = temp;
      }
      // Add all tiles within this range for the current zoom level
      for (int x = minTileX; x <= maxTileX; x++) {
        for (int y = minTileY; y <= maxTileY; y++) {
          tilesToDownload.add(TileIdentity(z, x, y));
        }
      }
    }
    return tilesToDownload;
  }
}
/*
void main() {
  // Example: Bounding box around a small area (e.g., a city block)
  final LatLng southWest =
      LatLng(34.0522, -118.2437); // Los Angeles downtown-ish
  final LatLng northEast = LatLng(34.0622, -118.2337);
  final Fence routeBounds = Fence(southWest: southWest, northEast: northEast);

  // Define the zoom levels you want to download
  final int minZoom = 10;
  final int maxZoom = 14;

  final Set<TileIdentity> requiredTiles =
      OfflineTiles.getTilesInBounds(routeBounds, minZoom, maxZoom);

  print(
      'Tiles to download for zoom levels $minZoom-$maxZoom: ${requiredTiles.length} tiles');
  // requiredTiles.take(10).forEach(print); // Print first 10 for example
  // print('...');
  // print('Last 10 tiles:');
  // requiredTiles.skip(requiredTiles.length - 10).forEach(print);
}
*/
