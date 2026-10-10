import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class TripPackagerService {
  /// Packs a JSON metadata Map and a list of image File references
  /// into a single `.trip` (zip) file.
  ///
  /// Returns a [File] on native platforms (Windows/Mac/Linux/Android/iOS)
  /// or a [Uint8List] on Web.
  static Future<File> createTripArchive({
    required Map<String, dynamic> metadata,
    required List<File> imageFiles,
    required String outputDirectoryPath,
  }) async {
    // 1. Create an in-memory Archive container
    final archive = Archive();

    // 2. Encode metadata Map to JSON string & add as metadata.json
    final jsonString = jsonEncode(metadata);
    final jsonBytes = utf8.encode(jsonString);

    archive.addFile(
      ArchiveFile(
        'metadata.json',
        jsonBytes.length,
        jsonBytes,
      ),
    );

    // 3. Add each image file to the archive
    for (final imageFile in imageFiles) {
      if (await imageFile.exists()) {
        final imageBytes = await imageFile.readAsBytes();

        // Extract filename (e.g. "cover.jpg") to keep archive root flat
        final filename = p.basename(imageFile.path);

        archive.addFile(
          ArchiveFile(
            filename,
            imageBytes.length,
            imageBytes,
          ),
        );
      }
    }

    // 4. Encode the Archive into a Zip byte array
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      throw Exception('Failed to encode .trip zip archive.');
    }

    // 5. Write the output file
    final String tripId =
        metadata['id'] ?? 'trip_${DateTime.now().millisecondsSinceEpoch}';
    final String outputPath = p.join(outputDirectoryPath, '$tripId.trip');

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(zipData);

    return outputFile;
  }

  /// Web Alternative: Returns raw bytes directly without writing to a local File system.
  static Uint8List createTripArchiveBytes({
    required Map<String, dynamic> metadata,
    required List<Uint8List> imageBytesList,
    required List<String> imageFileNames,
  }) {
    final archive = Archive();

    // Add metadata.json
    final jsonBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(ArchiveFile('metadata.json', jsonBytes.length, jsonBytes));

    // Add image byte arrays
    for (int i = 0; i < imageBytesList.length; i++) {
      archive.addFile(
        ArchiveFile(
          imageFileNames[i],
          imageBytesList[i].length,
          imageBytesList[i],
        ),
      );
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData!);
  }
}
