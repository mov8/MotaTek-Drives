// import 'dart:io';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/src/grid/grid_layer.dart';
import 'package:vector_map_tiles/src/options.dart';
import 'package:vector_map_tiles/src/extensions.dart';
/*
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'extensions.dart';
import 'package:vector_map_tiles/src/grid/grid_layer.dart';
import 'options.dart';
import 'style/style.dart';
import 'tile_offset.dart';
import 'tile_providers.dart';
import 'vector_tile_layer_mode.dart';
import 'vector_tile_provider.dart';
*/
import 'package:vector_map_tiles/vector_map_tiles.dart';

class CachedVectorTileLayer extends VectorTileLayer {
  CachedVectorTileLayer(
      {super.key,
      required super.tileProviders,
      required super.theme,
      super.sprites,
      super.fileCacheTtl, // = defaultCacheTtl,
      super.memoryTileCacheMaxSize, // = defaultTileCacheMaxSize,
      super.memoryTileDataCacheMaxSize, // = defaultTileDataCacheMaxSize,
      super.fileCacheMaximumSizeInBytes, // = defaultCacheMaxSize,
      super.textCacheMaxSize, // = defaultTextCacheMaxSize,
      super.concurrency, // = defaultConcurrency,
      super.tileOffset = TileOffset.DEFAULT,
      super.maximumTileSubstitutionDifference, // =
      //  defaultMaxTileSubstitutionDifference,
      super.backgroundTheme,
      super.showTileDebugInfo = false,
      super.logCacheStats = false,
      super.layerMode = VectorTileLayerMode.vector,
      super.maximumZoom,
      super.tileDelay = const Duration(milliseconds: 0),
      super.cacheFolder}) {
    assert(concurrency >= 0 && concurrency <= 100);
    final providers = theme.tileSources
        .map((source) => tileProviders.tileProviderBySource[source])
        .whereType<VectorTileProvider>();
    assert(
        providers.isNotEmpty,
        '''
tileProviders must provide at least one provider that matches the given theme. 
Usually this is an indication that TileProviders in the code doesn't match the sources
required by the theme. 
The theme uses the following sources: ${theme.tileSources.toList().sorted().join(', ')}.
'''
            .trim());
    assert(
        maximumTileSubstitutionDifference >= 0 &&
            maximumTileSubstitutionDifference <= 3,
        'maximumTileSubstitutionDifference must be >= 0 and <= 3');
    assert(memoryTileDataCacheMaxSize >= 0 && memoryTileDataCacheMaxSize < 100);
  }

  @override
  Widget build(BuildContext context) {
    final mapCamera = MapCamera.maybeOf(context)!;
    return VectorTileCompositeLayer(VectorTileLayerOptions(this), mapCamera);
  }
}
