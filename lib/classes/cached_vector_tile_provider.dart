/*
import 'dart:typed_data';

import 'package:drives/classes/classes.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

class CachedVectorTileProvider extends VectorTileProvider {
  final CachedVectorTileProvider delegate;
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

/*
  Future<Uint8List> provide(TileIdentity tile);

  int get maximumZoom;

  int get minimumZoom;

  TileRepository({required this.deligate});
  Future<Uint8List?> loadTile({
    required TileIdentity tile,
    required int id,
    required String uri,


*/
