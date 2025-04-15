/*

 import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:drives/classes/classes.dart';

class CachedTileProviders {
  //extends TileProviders {
  // @override
  final Map<String, CachedVectorTileProvider> tileProviderBySource;
  const CachedTileProviders({required this.tileProviderBySource});
  CachedVectorTileProvider get(String source) {
    final provider = tileProviderBySource[source];
    if (provider == null) {
      throw 'no VectorTileProvider for source $source';
    }
    return provider;
  }
}




class TileProviders {
  /// provides vector tiles, by source ID where the source ID corresponds to
  /// a source in the theme
  final Map<String, VectorTileProvider> tileProviderBySource;

  const TileProviders(this.tileProviderBySource);

  VectorTileProvider get(String source) {
    final provider = tileProviderBySource[source];
    if (provider == null) {
      throw 'no VectorTileProvider for source $source';
    }
    return provider;
  }
}
*/
