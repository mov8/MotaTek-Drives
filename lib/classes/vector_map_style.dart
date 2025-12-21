import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '/constants.dart';
import '/services/services.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import '/classes/classes.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Stackoverflow descripion of extending TileProvide to cache
/// https://stackoverflow.com/questions/79609507/how-to-cache-map-tiles-in-flutter-using-flutter-map-for-offline-usage
/// Look at the source for the current Prividers class

class VectorMapStyle {
  dynamic style;
  VectorMapStyle._privateConstructor();
  static final _instance = VectorMapStyle._privateConstructor();
  factory VectorMapStyle() {
    return _instance;
  }

  Future<dynamic> mapStyle() async {
    try {
      if (style == null) {
        DrivesStyleReader styleReader =
            DrivesStyleReader(uri: urlTiler, apiKey: '', logger: null);
        style = await styleReader.read();
      }
      return style;
    } catch (e) {
      debugPrint('Error initiating style: ${e.toString()}');
    }
  }
}

class DrivesStyleReader {
  final String uri;
  final String? apiKey;
  final Logger logger;

  DrivesStyleReader({required this.uri, this.apiKey, Logger? logger})
      : logger = logger ?? const Logger.noop();

  Future<Style> read() async {
    String styleText = '';
    Directory cache = await getCache();
    String localStyleFile = '${cache.path}/style.txt';
    // String styleText = '';
    if (File(localStyleFile).existsSync()) {
      styleText = await File(localStyleFile).readAsString();
      debugPrint('got style locally');
    } else {
      styleText = await getStyle(url: uri);
      File(localStyleFile).writeAsString(styleText);
    }

    dynamic style;
    try {
      style = await compute(jsonDecode, styleText);
    } catch (e) {
      debugPrint('error getting style: ${e.toString()}');
    }
    if (style is! Map<String, dynamic>) {
      throw 'invalid uri $uri';
    }
    final sources = style['sources'];
    if (sources is! Map) {
      throw 'Style is not a Map';
    }

    final providerByName = await _readProviderByName(sources);

    final name = style['name'] as String?;

    final center = style['center'];
    LatLng? centerPoint;
    if (center is List && center.length == 2) {
      centerPoint =
          LatLng((center[1] as num).toDouble(), (center[0] as num).toDouble());
    }
    centerPoint = LatLng(51.507, 0.13);
    double? zoom = (style['zoom'] as num?)?.toDouble();
    if (zoom != null && zoom < 2) {
      zoom = null;
      centerPoint = null;
    }
    //  final spriteUri = style['sprite'];
    SpriteStyle? sprites;
    return Style(
        theme: ThemeReader(logger: logger).read(style),
        providers: TileProviders(providerByName),
        sprites: sprites,
        name: name,
        center: centerPoint,
        zoom: zoom);
  }

  Future<Map<String, VectorTileProvider>> _readProviderByName(
      Map sources) async {
    final providers = <String, VectorTileProvider>{};
    final sourceEntries = sources.entries.toList();
    for (final entry in sourceEntries) {
      final type = TileProviderType.values
          .where((e) => e.name == entry.value['type'])
          .firstOrNull;
      if (type == null) continue;
      dynamic source;
      var entryUrl = entry.value['url'] as String?;
      if (entryUrl != null) {
        source = await compute(jsonDecode, await getStyle(url: entryUrl));
        if (source is! Map) {
          throw 'invalid url';
        }
      } else {
        source = entry.value;
      }
      final entryTiles = source['tiles'];
      final maxzoom = source['maxzoom'] as int? ?? 14;
      final minzoom = source['minzoom'] as int? ?? 1;
      if (entryTiles is List && entryTiles.isNotEmpty) {
        final tileUrl = entryTiles[0] as String;
        providers[entry.key] = NetworkVectorTileProvider(
            type: type,
            urlTemplate: tileUrl,
            maximumZoom: maxzoom,
            minimumZoom: minzoom);
      }
    }
    if (providers.isEmpty) {
      throw 'Unexpected response';
    }
    return providers;
  }
}
