import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/helpers/helpers.dart';
import '/screens/dialogs.dart';
import 'tiles.dart';
import '/services/services.dart';
import 'dart:developer' as developer;

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
  final List<Card> _childCards = [];
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
      } else {}
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

  getDetails() async {
    if (_childCards.isEmpty) {
      try {
        var details = await getTripDetails(uuid: widget.tripItem.uri);
        for (int i = 0; i < details.length; i++) {
          PointOfInterest pointOfInterest =
              PointOfInterest.fromJson(map: details[i]);
          if (![12, 17, 18].contains(pointOfInterest.type)) {
            _childCards.add(
              Card(
                child: PointOfInterestTile(
                  index: i,
                  canEdit: false,
                  pointOfInterest: pointOfInterest,
                  imageRepository: widget.imageRepository,
                  driveId: widget.tripItem.uri,
                ),
              ),
            );
          }
        }
      } catch (e) {
        developer.log(
            'Error TripTile().getDetails() getting trip details: ${e.toString()}',
            name: 'error');
      }
    }
    return;
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
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.tripItem.imageUrls.isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              child: PhotoCarousel(
                                imageRepository: widget.imageRepository,
                                photos: widget.tripItem.tripPhotos,
                                height: 300,
                                width: MediaQuery.of(context).size.width - 50,
                              ),
                            ),
                          )
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.tripItem.subTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.tripItem.body,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
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
                    if (_childCards.isNotEmpty)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Text(
                              'Points of interest...',
                              style: titleStyle(
                                context: context,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ..._childCards,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  changeRating(value) {
    if (widget.tripItem.uri.isNotEmpty) {
      putDriveRating(widget.tripItem.uri, value);
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
