import 'dart:math';
import 'dart:typed_data';
import '../helpers/create_trip_helpers.dart' show getUuid;
import '../classes/classes.dart' hide Position;
import '../models/models.dart' hide Message;
import '../services/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FabsController {
  _HandleCTFabsState? _handleCTFabsState;

  void _addState(_HandleCTFabsState handleCTFabsState) {
    _handleCTFabsState = handleCTFabsState;
  }

  void refresh() {
    if (isAttached) {
      _handleCTFabsState?.refresh();
    }
  }

  void hide() {
    if (isAttached) {
      _handleCTFabsState?.hide();
    }
  }

  void show() {
    if (isAttached) {
      _handleCTFabsState?.show();
    }
  }

  void drop({int height = 80}) {
    if (isAttached) {
      _handleCTFabsState?._dropFabs(height);
    }
  }

  Future<bool> dropped() async {
    if (isAttached) {
      return _handleCTFabsState!._dropped;
    }
    return false;
  }

  bool get isAttached => _handleCTFabsState != null;
}

class HandleCTFabs extends StatefulWidget {
  double top;

  final Function(bool)? update;
  FabsController? controller;
  HandleCTFabs({
    super.key,
    this.controller,
    this.update,
    this.top = 20,
  });

  @override
  State<HandleCTFabs> createState() => _HandleCTFabsState();
}

class _HandleCTFabsState extends State<HandleCTFabs> {
  final double _width = 50;
  final double _height = 56.0;
  bool visible = true;
  @override
  void initState() {
    super.initState;

    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
  }

  bool _drop = false;
  bool _dropped = false;
  void refresh() => setState(() {});

  void hide() => setState(() => visible = false);

  void show() => setState(() => visible = true);

  void _dropFabs(int height) {
    _dropped = false;
    setState(() => _drop = height > 0);
  }

  bool showMessage(index) {
    if (index > -1) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    FloatingTextEditController teController = FloatingTextEditController();
    bool osmIncludingChange = false;

    return Material(
      color: Colors.transparent,
      child: visible
          ? Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height),
              // When the keyboard is up (e.g. typing in a FloatingTextEdit)
              // the Scaffold has less room than the FABs need - scroll
              // rather than overflow
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsGeometry.fromLTRB(0, widget.top, 10, 0),
                      child: Column(
                        // Keep the FABs on the right edge when one expands -
                        // centred, they moved left as a FloatingTextEdit opened
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 500),
                            crossFadeState: _drop
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: SizedBox(height: 80),
                            secondChild: const SizedBox.shrink(),
                            onEnd: () {
                              _dropped = true;
                            },
                          ),
                          if (CurrentTripItem().tripState ==
                              TripState.following)
                            const SizedBox(height: 120),
                          if (MapService().controller != null)
                            HelpTip(
                              helpKey: 'fab.search',
                              child: PlaceFinder(
                                height: _height,
                                width: _width,
                                // Zoomed in to it if the map was further
                                // out - at zoom 5 the move was hard to see
                                onSelect: (position) =>
                                    MapService().controller!.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            LatLng(position.latitude,
                                                position.longitude),
                                            max(
                                                MapService()
                                                        .controller!
                                                        .cameraPosition
                                                        ?.zoom ??
                                                    12,
                                                12),
                                          ),
                                        ),
                              ),
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          // How routes are worked out - for planning, so
                          // not on Published
                          if (NavigationService().page != 1) ...[
                            HelpTip(
                              helpKey: 'fab.preferences',
                              child: FloatingChecklist(
                                choices: [
                                  {'Avoid motorways': Setup().avoidMotorways},
                                  {'Avoid main roads': Setup().avoidAroads},
                                  {'Avoid ferries': Setup().avoidFerries},
                                  {'Avoid toll roads': Setup().avoidTollRoads},
                                  {'Show pubs and bars': Setup().osmPubs},
                                  {
                                    'Show cafes and restaurants':
                                        Setup().osmRestaurants
                                  },
                                  {
                                    'Show fuel and charging stations':
                                        Setup().osmFuel
                                  },
                                  {'Show toilets': Setup().osmToilets},
                                  {'Show ATMs': Setup().osmAtms},
                                  {'Show historic sites': Setup().osmHistorical}
                                ],
                                maxWidth:
                                    MediaQuery.of(context).size.width - 40,
                                onCheck: (index, value) {
                                  switch (index) {
                                    case 0:
                                      Setup().avoidMotorways = value;
                                      break;
                                    case 1:
                                      Setup().avoidAroads = value;
                                      break;
                                    case 2:
                                      Setup().avoidFerries = value;
                                      break;
                                    case 3:
                                      Setup().avoidTollRoads = value;
                                      break;
                                    case 4:
                                      Setup().osmPubs = value;
                                      break;
                                    case 5:
                                      Setup().osmRestaurants = value;
                                      break;
                                    case 6:
                                      Setup().osmFuel = value;
                                      break;
                                    case 7:
                                      Setup().osmToilets = value;
                                      break;
                                    case 8:
                                      Setup().osmAtms = value;
                                      break;
                                    case 9:
                                      Setup().osmHistorical = value;
                                      break;
                                  }
                                  osmIncludingChange = true;
                                },
                                onClose: (_) async {
                                  if (osmIncludingChange) {
                                    osmIncludingChange = false;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if ([TripState.tracking, TripState.following]
                              .contains(CurrentTripItem().tripState)) ...[
                            HelpTip(
                              helpKey: 'fab.pointOfInterest',
                              child: Material(
                                child: FloatingTextEdit(
                                  key: Key('ftepoi'),
                                  focusNode: FocusNode(),
                                  keyboardType: TextInputType.name,
                                  controller: teController,
                                  closedIcon: Icons.add_location_alt_outlined,
                                  openIcon: Icons.add_task_outlined,
                                  onOpen: (_) => CurrentTripItem().saveState(),
                                  onClose: (description, audio, images) =>
                                      addPointOfInterest(
                                          description: description,
                                          audio: audio,
                                          images: images),
                                  fillColor: Colors.white,
                                  inputBorder: _width > _height
                                      ? OutlineInputBorder()
                                      : null,
                                  hint: 'Description to edit later...',
                                  suffix: IconButton(
                                      onPressed: (() {}),
                                      icon: Icon(Icons.mic)),
                                ),
                              ),
                            ),
                            if (CurrentTripItem().isGoodRoad) ...[
                              const SizedBox(height: 10),
                              HelpTip(
                                helpKey: 'fab.greatRoad',
                                child: FloatingTextEdit(
                                  key: Key('ftegr'),
                                  maxWidth: 200,
                                  focusNode: FocusNode(),
                                  keyboardType: TextInputType.name,
                                  controller: teController,
                                  closedIcon: Icons.remove_road,
                                  openIcon: Icons.add_task_outlined,
                                  onOpen: (_) => CurrentTripItem().saveState(),
                                  onClose: (description, audio, images) =>
                                      updateRouteType(
                                          description: description,
                                          sound: audio),
                                  fillColor: Colors.white,
                                  inputBorder: _width > _height
                                      ? OutlineInputBorder()
                                      : null,
                                  hint: 'Description to edit later...',
                                  suffix: IconButton(
                                    onPressed: (() => (widget.update!(true))),
                                    icon: Icon(
                                      Icons.mic,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                            if (!CurrentTripItem().isGoodRoad) ...[
                              const SizedBox(height: 10),
                              HelpTip(
                                helpKey: 'fab.greatRoad',
                                child: FloatingActionButton(
                                  onPressed: () => updateRouteType(),
                                  heroTag: 'goodRoadOn',
                                  backgroundColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  child: Icon(
                                    Icons.add_road,
                                    color: CurrentTripItem().isTracking
                                        ? CurrentTripItem()
                                                .tripValues
                                                .autoCentre
                                            ? Colors.white
                                            : Colors.grey
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ],
                          HelpTip(
                            helpKey: 'fab.location',
                            child: FloatingActionButton(
                              onPressed: () => updatePosition(),
                              heroTag: 'mapCentre',
                              backgroundColor: Colors.blue,
                              shape: const CircleBorder(),
                              child: Icon(
                                Icons.my_location,
                                color: CurrentTripItem().isTracking
                                    ? CurrentTripItem().tripValues.autoCentre
                                        ? Colors.white
                                        : Colors.grey
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (MapService().controller != null)
                            HelpTip(
                              helpKey: 'fab.zoom',
                              child: ZoomFab(
                                controller: MapService().controller!,
                                zfController: MapService().zoomFabController!,
                                width: 55,
                                height: 125,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  /// A point of interest recorded with the FloatingTextEdit while tracking or
  /// following, where the user is. audio is the voice memo's SoundRepository
  /// key; the photos go into the ImageRepository's Hive box, the same as
  /// those added in the PointOfInterestTile.
  Future<void> addPointOfInterest(
      {String description = '',
      String audio = '',
      List<Uint8List> images = const []}) async {
    PointOfInterest pointOfInterest = PointOfInterest(
        point: CurrentTripItem().tripValues.position,
        description: description,
        sounds: audio);
    ImageRepository imageRepository = ImageRepository();
    for (Uint8List bytes in images) {
      try {
        String name = '${getUuid()}.jpg';
        var imageMap = await imageRepository.loadImage(bytes: bytes, uri: name);
        pointOfInterest.addPhoto(
            photo: Photo(
                url: name,
                caption: 'image ${pointOfInterest.photos.length + 1}',
                rotation: 0,
                key: imageMap.keys.first));
      } catch (e) {
        debugPrint('Error saving point of interest image: ${e.toString()}');
      }
    }
    CurrentTripItem().pointsOfInterest.add(pointOfInterest);
    CurrentTripItem().isSaved = false;
    // Show its shield straight away (refreshMap() also micro-nudges)
    await CurrentTripItem().refreshMap(change: MapUpdates.pointsOfInterest);
  }

  /// Centres the map on where you are. It moves straight away to the last
  /// position known, then to a fresh fix if that's somewhere else - waiting
  /// for the fix (seconds, on the web) made the button seem not to work.
  void updatePosition() async {
    CurrentTripItem().tripValues.autoCentre =
        !CurrentTripItem().tripValues.autoCentre;
    LatLng? shown;
    if (MapService().hasPosition) {
      shown = MapService().currentPosition;
      MapService().controller?.animateCamera(CameraUpdate.newLatLng(shown),
          duration: const Duration(milliseconds: 600));
    }
    Position? position = await MapService().currentPositionOrNull();
    if (position == null) return;
    LatLng fix = LatLng(position.latitude, position.longitude);
    MapService().setPosition(latLng: fix);
    if (CurrentTripItem().tripValues.autoCentre &&
        CurrentTripItem().tripState != TripState.following) {
      CurrentTripItem().tripValues.position =
          Point(position.longitude, position.latitude);
    }
    bool moved = shown == null ||
        Geolocator.distanceBetween(
                shown.latitude, shown.longitude, fix.latitude, fix.longitude) >
            30;
    if (moved) {
      MapService().controller?.animateCamera(CameraUpdate.newLatLng(fix),
          duration: const Duration(milliseconds: 600));
    }
  }

  void updateRouteType({String description = '', String sound = ''}) {
    if (CurrentTripItem().isGoodRoad) {
      CurrentTripItem().goodRoadEnd(description: description, sounds: sound);
    } else {
      CurrentTripItem().requestGreatRoad();
      if (widget.update != null) {
        widget.update!(true);
      }
    }
  }
}
