import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:universal_io/universal_io.dart';
import '/helpers/create_trip_helpers.dart' show getUuid;

/// Voice memos recorded for points of interest, e.g. while tracking, so the
/// driver can write the point of interest up later. They're kept in Hive -
/// IndexedDB on the web, where there are no files - and
/// PointOfInterest.sounds holds the key. Unlike images they aren't cached in
/// memory or sent to the api.
class SoundRepository {
  static const String _boxName = 'sounds';

  Future<LazyBox> _box() async => Hive.isBoxOpen(_boxName)
      ? Hive.lazyBox(_boxName)
      : await Hive.openLazyBox(_boxName);

  /// Stores a memo and returns the key for PointOfInterest.sounds
  Future<String> save(Uint8List bytes) async {
    String key = getUuid();
    await (await _box()).put(key, bytes);
    return key;
  }

  Future<Uint8List?> load(String key) async {
    dynamic bytes = await (await _box()).get(key);
    if (bytes is Uint8List) return bytes;
    if (bytes is List) return Uint8List.fromList(bytes.cast<int>());
    return null;
  }

  Future<void> delete(String key) async {
    if (isKey(key)) {
      await (await _box()).delete(key);
    }
  }

  /// Memos recorded before they were kept in Hive hold a file path
  static bool isKey(String sounds) =>
      sounds.length == 32 && !sounds.contains('/') && !sounds.contains('\\');

  /// Plays a memo from Hive, or from its file for an older point of interest.
  /// Returns false if there's nothing to play.
  Future<bool> play(AudioPlayer player, String sounds) async {
    try {
      if (isKey(sounds)) {
        Uint8List? bytes = await load(sounds);
        if (bytes == null || bytes.isEmpty) return false;
        await player.play(BytesSource(bytes));
        return true;
      }
      if (!kIsWeb && sounds.isNotEmpty && await File(sounds).exists()) {
        await player.play(DeviceFileSource(sounds));
        return true;
      }
    } catch (e) {
      developer.log('Error SoundRepository().play(): ${e.toString()}',
          name: 'error');
    }
    return false;
  }
}
