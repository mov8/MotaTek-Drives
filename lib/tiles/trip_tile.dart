import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/helpers/helpers.dart';
import '/screens/dialogs.dart';
import 'tiles.dart';
import '/services/services.dart';

class TripTile extends StatefulWidget {
  final TripItem tripItem;
  final ImageRepository imageRepository;
  final Function(int, String)? onGetTrip;
  final Function(int, int)? onRatingChanged;
  final Function(int)? onExpand;
  final bool? expanded;
  final MapLibreMapController? mapController;
  final int index;

  const TripTile({
    super.key,
    required this.tripItem,
    required this.imageRepository,
    required this.index,
    this.onGetTrip,
    this.onRatingChanged,
    this.onExpand,
    this.mapController,
    bool? expanded,
  }) : expanded = expanded ?? false;

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  List<Photo> photos = [];
  bool _downloading = false;
  bool isExpanded = false;
  bool expanded = true;

  /// The whole trip - its waypoints and its own points of interest - fetched
  /// when the tile opens (not counted as a download)
  MyTripItem? _trip;
  bool _loading = false;
  bool _descriptionOpen = false;
  @override
  void initState() {
    super.initState();
    expanded = widget.expanded!;
    if (expanded) {
      // e.g. opened by tapping its label on the map
      getDetails().then((_) {
        if (mounted) setState(() {});
      });
    }
    photos = photosFromJson(
      photoString: widget.tripItem.imageUrls,
      endPoint: '${widget.tripItem.uri}/',
    );
  }

  expandChange({required bool expanded}) async {
    try {
      if (expanded) {
        _showStart();
        await getDetails();
        if (mounted) {
          setState(() {});
        }
        if (widget.onExpand != null) {
          widget.onExpand!(widget.index);
        }
      } else if (_trip != null) {
        MapService().showPublishedTrip(null);
      }
    } catch (e) {
      debugPrint('Error tripTile expandChange: ${e.toString()} ');
    }
  }

  /// Pans the map to the start of the trip - from its line on the map
  void _showStart() {
    List start = widget.tripItem.startPoint;
    if (start.length >= 2) {
      MapService().showInView(LatLng(start[1].toDouble(), start[0].toDouble()));
    }
  }

  /// The whole trip, once: its figures, its points of interest for the list,
  /// and its waypoints and points of interest on the map
  Future<void> getDetails() async {
    if (_trip == null && !_loading) {
      _loading = true;
      MyTripItem trip = await getMyTrip(widget.tripItem.uri);
      _loading = false;
      if (trip.routes.isNotEmpty) _trip = trip;
    }
    if (_trip != null) MapService().showPublishedTrip(_trip);
  }

  /// Its own points of interest - not its waypoints (or the Start and End
  /// that mark them)
  List<PointOfInterest> get _pointsOfInterest => [
        for (PointOfInterest poi in _trip?.pointsOfInterest ?? [])
          if (![12, 14, 17, 18].contains(poi.type)) poi
      ];

  /// The figures, as AI assist shows a trip's
  Widget _stats(TextTheme text) {
    MyTripItem? trip = _trip;
    int waypoints = trip == null || trip.routes.isEmpty
        ? 0
        : trip.routes.first.waypoints.where((w) => !w.revisit).length;
    List<(String, String)> figures = [
      ('Distance', '${widget.tripItem.distance.toStringAsFixed(0)} miles'),
      if (trip != null) ...[
        ('Waypoints', '$waypoints'),
        ('Points of interest', '${_pointsOfInterest.length}'),
        if (trip.goodRoads.isNotEmpty)
          ('Great roads', '${trip.goodRoads.length}'),
      ],
      ('Downloads', '${widget.tripItem.downloads}'),
      if (widget.tripItem.driven > 0)
        ('Driven by', '${widget.tripItem.driven}'),
    ];
    return Wrap(spacing: 20, runSpacing: 8, children: [
      for (var (label, value) in figures)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: text.bodySmall?.copyWith(color: Colors.black54)),
          Text(value, style: text.titleMedium?.copyWith(color: Colors.black)),
        ]),
    ]);
  }

  /// Its summary and the start of its description; opened, the whole
  /// description and its photos
  Widget _description(TextTheme text) {
    String body = widget.tripItem.body.trim();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        onExpansionChanged: (open) => setState(() => _descriptionOpen = open),
        title: Text(
            widget.tripItem.subTitle.isEmpty
                ? 'About this trip'
                : widget.tripItem.subTitle,
            style: text.titleSmall
                ?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        subtitle: _descriptionOpen || body.isEmpty
            ? null
            : Text(body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: Colors.black87)),
        children: [
          if (widget.tripItem.imageUrls.isNotEmpty)
            PhotoCarousel(
              imageRepository: widget.imageRepository,
              photos: widget.tripItem.tripPhotos,
              height: 300,
              width: MediaQuery.of(context).size.width - 50,
            ),
          const SizedBox(height: 8),
          Text(body, style: text.bodyLarge?.copyWith(color: Colors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RrExpansionTile(
      context: context,
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: null,
        title: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                widget.tripItem.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Text(
                    'by: ${widget.tripItem.author}',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.tripItem.added,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                '${widget.tripItem.distance.toStringAsFixed(0)} miles long, ${(widget.tripItem.distanceAway * metersToMiles).toStringAsFixed(0)} miles away.',
                style: textStyle(
                  context: context,
                  color: Colors.black,
                  size: 3,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 12,
                  child: Text(
                    widget.tripItem.driven > 0
                        ? 'Driven by ${widget.tripItem.driven} · Downloads (${widget.tripItem.downloads})'
                        : 'Downloads (${widget.tripItem.downloads})',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 5),
                    child: Text(
                      widget.tripItem.score,
                      style: textStyle(
                        context: context,
                        color: const Color.fromRGBO(255, 196, 0, 0.918),
                        size: 1,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    ' (${widget.tripItem.scored})',
                    style: textStyle(
                      context: context,
                      color: Colors.black,
                      size: 3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        initiallyExpanded: expanded,
        onExpansionChanged: (value) => expandChange(expanded: value),
        // Not Expanded - the leading widget isn't in a Row (it threw)
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            getInitials(name: widget.tripItem.author),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Builder(builder: (context) {
              TextTheme text = Theme.of(context).textTheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _stats(text),
                  _description(text),
                  // To follow, or change and keep as the user's own -
                  // the bar's "Choose a drive to download"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: _downloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download),
                      label: const Text('Download',
                          style: TextStyle(fontSize: 18)),
                      onPressed: _downloading ? null : download,
                    ),
                  ),
                  if (_loading && _trip == null)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_pointsOfInterest.isNotEmpty) ...[
                    Text('Points of interest',
                        style:
                            titleStyle(context: context, color: Colors.black)),
                    for (int i = 0; i < _pointsOfInterest.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: PointOfInterestTile(
                          key: Key('ppoi_${_pointsOfInterest[i].uuid}'),
                          index: i,
                          canEdit: false,
                          pointOfInterest: _pointsOfInterest[i],
                          imageRepository: widget.imageRepository,
                          driveId: widget.tripItem.uri,
                          backgroundColor:
                              const Color.fromRGBO(10, 169, 243, 0.158),
                        ),
                      ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Kept only if they've driven it - otherwise they're told why
  Future<void> changeRating(value) async {
    if (widget.tripItem.uri.isNotEmpty) {
      String? why = await putDriveRating(widget.tripItem.uri, value);
      if (!mounted) return;
      if (why != null) return cantRateDialog(context, why);
      if (widget.onRatingChanged != null) {
        widget.onRatingChanged!(value, widget.index);
      }
      setState(() => widget.tripItem.rating = value.toDouble());
    }
  }

  /// Opens the trip on the map, to follow or change - warning first if the
  /// trip being worked on hasn't been saved
  Future<void> download() async {
    if (CurrentTripItem().hasUnsavedChanges) {
      String current = CurrentTripItem().title.isEmpty
          ? 'The trip you are working on'
          : '"${CurrentTripItem().title}"';
      Utility().showOkCancelDialog(
          context: context,
          alertTitle: 'Discard unsaved trip?',
          alertMessage:
              "$current hasn't been saved. Downloading \"${widget.tripItem.title}\" will clear it.",
          okValue: 1,
          callback: (value) {
            if (value > -1) _download();
          });
    } else {
      await _download();
    }
  }

  /// The whole trip, waypoints and all, as a copy of its own - saving or
  /// publishing it doesn't touch the original
  Future<void> _download() async {
    setState(() => _downloading = true);
    MyTripItem trip = await getMyTrip(widget.tripItem.uri, download: true);
    if (!mounted) return;
    setState(() => _downloading = false);
    if (trip.routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("The trip couldn't be downloaded - please try again")));
      return;
    }
    trip.uri = getUuid();
    trip.published = false;
    await openTripOnMap(trip);
    // Not saved on this device yet - leaving it warns
    CurrentTripItem().markUnsaved();
    // After the next frame - the map page may only be being built now, and
    // its message box isn't there to take the message until it is
    WidgetsBinding.instance.addPostFrameCallback((_) => MapService()
        .messageBoxController
        ?.message(message: Warning.tripDownloaded));
  }

  getTrip(value) {
    if (widget.onGetTrip != null) {
      widget.onGetTrip!(widget.index, widget.tripItem.uri);
    }
  }
}
