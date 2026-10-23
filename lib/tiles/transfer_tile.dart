import '/models/other_models.dart';
import '/services/services.dart';
import 'package:universal_io/universal_io.dart';

Future<void> exportTripForWifiTransfer() async {
  // 1. Prepare Trip Metadata
  final tripMetadata = {
    'id': 'trip_2026_alpine_pass',
    'title': 'Alpine Road Trip',
    'createdAt': DateTime.now().toIso8601String(),
    'waypoints': [
      {'name': 'Zurich Start', 'lat': 47.3769, 'lng': 8.5417},
      {'name': 'Furka Pass', 'lat': 46.5721, 'lng': 8.4001},
    ],
  };

  // 2. Collect local image files
  final List<File> imageFiles = [
    File('/path/to/local/photos/cover.jpg'),
    File('/path/to/local/photos/waypoint_1.jpg'),
  ];

  // 3. Get temporary output directory
  final tempDir =
      await Setup().appDocumentDirectory; //  getTemporaryDirectory();

  // 4. Create the .trip file
  try {
    final File tripArchiveFile = await TripPackagerService.createTripArchive(
      metadata: tripMetadata,
      imageFiles: imageFiles,
      outputDirectoryPath: tempDir, //.path,
    );

    print('Successfully generated archive at: ${tripArchiveFile.path}');

    // 5. Post `tripArchiveFile` over local Wi-Fi via HTTP multipart request
    // sendTripToMobile(mobileUrl: 'http://192.168.1.88:8080', zipFile: tripArchiveFile);
  } catch (e) {
    print('Error generating trip package: $e');
  }
}
