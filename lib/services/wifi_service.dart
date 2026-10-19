import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http_parser/http_parser.dart';

class WifiReceiverService {
  HttpServer? _server;

  Future<String> getIPaddress() async {
    String? ip = '';
    try {
      final info = NetworkInfo();
      ip = await info.getWifiIP();
    } catch (e) {
      developer.log('Error getting IP address : ${e.toString}', name: 'error');
    }
    return ip ?? '';
  }

  /// Starts the Shelf HTTP server and returns the local URL (e.g. "http://192.168.1.88:8080")
  Future<String?> startServer({
    required Function(File tripZipFile) onFileReceived,
    required Function(String error) onError,
  }) async {
    try {
      // 1. Obtain Local Wi-Fi IP Address
      final info = NetworkInfo();
      final String? ip = await info.getWifiIP();

      if (ip == null || ip.isEmpty) {
        onError("Device is not connected to a Wi-Fi network.");
        return null;
      }

      // 2. Define HTTP Router & Routes
      final app = Router();

      // Health-check endpoint for the PC client to verify connectivity
      app.get('/health', (Request request) {
        return Response.ok('OK');
      });

      // Upload endpoint: Handles incoming POST requests with file streams
      app.post('/upload', (Request request) async {
        final contentType = request.headers['content-type'];
        if (contentType == null ||
            !contentType.contains('multipart/form-data')) {
          return Response.badRequest(body: 'Expected multipart/form-data');
        }

        try {
          final mediaType = MediaType.parse(contentType);
          final boundary = mediaType.parameters['boundary'];
          if (boundary == null) {
            return Response.badRequest(body: 'Missing boundary parameter');
          }

          // Read the binary stream using MIME multipart transformer
          final transformer = MimeMultipartTransformer(boundary);
          final bodyStream = request.read();
          final parts = await transformer.bind(bodyStream).toList();

          File? savedFile;

          for (final part in parts) {
            final contentDisposition = part.headers['content-disposition'];
            if (contentDisposition != null &&
                contentDisposition.contains('name="trip_file"')) {
              // Extract filename or fallback to default
              final appDir = await getApplicationDocumentsDirectory();
              final savePath = p.join(appDir.path,
                  'incoming_trip_${DateTime.now().millisecondsSinceEpoch}.zip');

              savedFile = File(savePath);
              final sink = savedFile.openWrite();

              // Stream file chunks directly to local disk storage
              await part.pipe(sink);
              await sink.close();
              break;
            }
          }

          if (savedFile != null && await savedFile.exists()) {
            // Notify UI listener of successful file save
            onFileReceived(savedFile);

            return Response.ok('Upload Successful');
          } else {
            return Response.badRequest(
                body: 'No valid "trip_file" payload found');
          }
        } catch (e) {
          onError("File processing error: $e");
          return Response.internalServerError(
              body: 'Error saving file payload');
        }
      });

      // 3. Create Pipeline and Bind Server
      final handler =
          const Pipeline().addMiddleware(logRequests()).addHandler(app.call);

      // Bind to port 8080 on the active Wi-Fi interface
      _server = await shelf_io.serve(handler, ip, 8080);

      return 'http://$ip:${_server!.port}';
    } catch (e) {
      onError("Failed to start local HTTP server: $e");
      return null;
    }
  }

  /// Gracefully stops the Shelf server and releases port 8080
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }
}
