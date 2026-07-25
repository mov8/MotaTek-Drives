/*
import 'dart:typed_data';
import 'dart:developer' as developer;
import '/classes/classes.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

class CachedVectorTile_Provider extends VectorTileProvider {
  final VectorTileProvider delegate;
  late final TileRepository _cache;
  CachedVectorTileProvider({required this.delegate}) {
    _cache = TileRepository(deligate: delegate);
  }

  @override
  int get maximumZoom => delegate.maximumZoom;

  @override
  int get minimumZoom => delegate.minimumZoom;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    return await _cache.loadTile(tile: tile, id: 0, uri: '');
  }
}
*/
