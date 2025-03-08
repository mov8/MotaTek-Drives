import 'package:vector_map_tiles/vector_map_tiles.dart';

class CachedTileIdentity extends TileIdentity {
  int id;
  CachedTileIdentity(super.z, super.x, super.y, {this.id = -1});
}
