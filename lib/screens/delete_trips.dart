import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/theme.dart';

/// Admin (web only): removes published trips from the server for good.
/// Shown in the SideDrawer from the overflow menu.
class DeleteTripsForm extends StatefulWidget {
  const DeleteTripsForm({super.key});

  @override
  State<DeleteTripsForm> createState() => _DeleteTripsFormState();
}

class _DeleteTripsFormState extends State<DeleteTripsForm> {
  final List<TripSummary> _drives = [];
  late Future<bool> _loaded;
  int selected = 0;

  @override
  void initState() {
    super.initState();
    _loaded = _loadTrips();
  }

  Future<bool> _loadTrips() async {
    _drives
      ..clear()
      ..addAll(await getTripSummaries());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScreensAppBarBottom(
      heading: 'Remove trips',
      prompt: 'Remove trips permanently from the server',
      textColor: DrivesColours.current.ink,
      content: FutureBuilder<bool>(
        future: _loaded,
        builder: (context, snapshot) => snapshot.hasData
            ? portraitView()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget portraitView() {
    if (_drives.isEmpty) {
      return const Center(child: Text('There are no published trips.'));
    }
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: _drives.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Card(
              child: CheckboxListTile(
                title: Text(_drives[index].title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_drives[index].subTitle.trim().isNotEmpty)
                      Text(_drives[index].subTitle),
                    if (_drives[index].author.isNotEmpty)
                      Text('by ${_drives[index].author}'),
                    StarRating(
                        onRatingChanged: (_) {}, rating: _drives[index].score),
                  ],
                ),
                value: _drives[index].id == 1,
                onChanged: (value) => setState(() {
                  _drives[index].id = value! ? 1 : -1;
                  selected += value ? 1 : -1;
                }),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: ActionChip(
            onPressed: selected == 0 ? null : _confirmDelete,
            backgroundColor: Colors.blue,
            disabledColor:
                Colors.blue.shade200, // until there's something to remove
            avatar: const Icon(Icons.delete, color: Colors.white),
            label: Text('Remove $selected trip${selected == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  /// There's no undo - the trips, their routes, points of interest and
  /// images all go
  Future<void> _confirmDelete() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $selected trip${selected == 1 ? '' : 's'}?'),
        content: const Text('They are deleted from the server, with their '
            'routes, points of interest and photos. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await deleteTrips();
  }

  Future<void> deleteTrips() async {
    List<Map<String, String>> items = [
      for (TripSummary trip in _drives)
        if (trip.id == 1) {'delete': "'${trip.uri}'"}
    ];
    bool deleted = items.isNotEmpty && await deleteWebTrip(uriMap: items);
    if (!mounted) return;
    if (deleted) {
      setState(() {
        selected = 0;
        _drives.removeWhere((trip) => trip.id == 1);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The trips couldn't be removed")));
    }
  }
}
