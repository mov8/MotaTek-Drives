import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/helpers/hive_helpers.dart' show TripRepository;
import '/services/services.dart';

/// Offline maps (the phone's main drawer): each saved trip, to download the
/// map along it - and follow it where there's no signal - or to delete the
/// map to free the space. See OfflineMapsService.
class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  List<MyTripItem> _trips = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    TripRepository repository = TripRepository();
    await repository.openBox();
    List<MyTripItem> trips = await repository.getTrips();
    await OfflineMapsService().load();
    if (!mounted) return;
    setState(() {
      _trips = trips
          .where((trip) => OfflineMapsService.routeOf(trip).length > 1)
          .toList();
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(
          heading: 'Offline maps', prompt: 'The map along your trips'),
      body: ListenableBuilder(
        listenable: OfflineMapsService(),
        builder: (context, _) =>
            ListView(padding: const EdgeInsets.all(10), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
                "Download the map along a trip to follow it where there's no "
                'signal. Working out a new route, AI assist and messages still '
                'need the Internet.',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          if (_loaded && _trips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                  'Save a trip in Favourites first - then its map can be '
                  'downloaded here.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          for (MyTripItem trip in _trips) _tile(trip),
        ]),
      ),
    );
  }

  String _megabytes(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

  Widget _tile(MyTripItem trip) {
    OfflineMapsService maps = OfflineMapsService();
    double? progress = maps.downloading[trip.uri];
    bool downloaded = maps.isDownloaded(trip.uri);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trip.title.isEmpty ? 'A trip' : trip.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (progress != null) ...[
            Text('Downloading the map - ${(progress * 100).round()}%'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ] else
            Row(children: [
              Expanded(
                child: Text(downloaded
                    ? 'On this phone - ${_megabytes(maps.sizeOf(trip.uri))}'
                    : 'Not downloaded'),
              ),
              if (downloaded)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  onPressed: () => maps.delete(trip.uri),
                ),
              if (downloaded)
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Update'),
                  onPressed: () => _download(trip),
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download'),
                  onPressed: maps.downloading.isEmpty
                      ? () => _download(trip)
                      : null, // one at a time
                ),
            ]),
        ]),
      ),
    );
  }

  Future<void> _download(MyTripItem trip) async {
    String? problem = await OfflineMapsService().download(trip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(problem ??
            'The map along ${trip.title.isEmpty ? 'the trip' : trip.title} '
                'is on this phone')));
  }
}
