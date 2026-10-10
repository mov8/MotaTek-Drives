import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

class TripImporterService {
  /// Unpacks a .trip (.zip) file and writes metadata & images into Hive
  static Future<Map<String, dynamic>> importTripArchive(
      File tripZipFile) async {
    // 1. Read bytes from file
    final bytes = await tripZipFile.readAsBytes();

    // 2. Decode the Zip archive
    final archive = ZipDecoder().decodeBytes(bytes);

    Map<String, dynamic>? tripMetadata;
    final List<String> extractedImagePaths = [];

    // Get persistent directory for saving extracted images
    final appDir = await getApplicationDocumentsDirectory();

    // Find metadata.json first to obtain the unique trip ID
    ArchiveFile? metadataFile;
    try {
      metadataFile = archive.firstWhere((file) => file.name == 'metadata.json');
    } catch (_) {
      throw Exception('Invalid .trip archive: missing metadata.json file.');
    }

    // Parse trip JSON
    final jsonContent = utf8.decode(metadataFile.content as List<int>);
    tripMetadata = jsonDecode(jsonContent) as Map<String, dynamic>;

    final String tripId =
        tripMetadata['id'] ?? 'trip_${DateTime.now().millisecondsSinceEpoch}';

    // Create a specific sub-folder for this trip's extracted photos
    final tripImagesDir = Directory(p.join(appDir.path, 'trip_images', tripId));
    if (!await tripImagesDir.exists()) {
      await tripImagesDir.create(recursive: true);
    }

    // 3. Extract and save all image files
    for (final file in archive) {
      if (file.isFile && file.name != 'metadata.json') {
        // Filter for supported image extensions
        final extension = p.extension(file.name).toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
          final String localImagePath =
              p.join(tripImagesDir.path, p.basename(file.name));

          final imageFile = File(localImagePath);
          await imageFile.writeAsBytes(file.content as List<int>);

          extractedImagePaths.add(localImagePath);
        }
      }
    }

    // 4. Update metadata object with local image file references
    tripMetadata['imagePaths'] = extractedImagePaths;
    tripMetadata['lastImportedAt'] = DateTime.now().toIso8601String();

    // 5. Save into Hive Box
    final Box tripsBox = Hive.box('trips');

    // Save or overwrite using trip ID as key
    await tripsBox.put(tripId, tripMetadata);

    // 6. Clean up the temporary incoming .zip file
    if (await tripZipFile.exists()) {
      await tripZipFile.delete();
    }

    return tripMetadata;
  }
}

class NetworkHelper {
  /// Safely gets the local Wi-Fi IP address on mobile/desktop platforms.
  /// Returns `null` when running on Web or when Wi-Fi is disconnected.
  static Future<String?> getLocalWifiIp() async {
    // Web browsers cannot access local hardware IP addresses
    if (kIsWeb) {
      return null;
    }
    try {
      final info = NetworkInfo();
      final String? ip = await info.getWifiIP();
      return ip;
    } catch (e) {
      debugPrint('Failed to get local Wi-Fi IP: $e');
      return null;
    }
  }

  Future<String?> getPublicIpAddress() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip']; // e.g., "82.12.34.5"
      }
    } catch (e) {
      print('Failed to fetch public IP: $e');
    }
    return null;
  }
}
