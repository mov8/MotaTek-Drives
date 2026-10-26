import 'dart:math';
import '../classes/classes.dart';
import '../tiles/tiles.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:universal_io/universal_io.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// The Map pages BottomDrawer is to allow the following data
/// Trip details on planning and saving
/// Display of waypoints and points of interest

class BottomDrawerController {
  _BottomDrawerState? _bottomDrawerState;

  void _addState(_BottomDrawerState bottomDrawerState) {
    _bottomDrawerState = bottomDrawerState;
  }

  bool get isAttached => _bottomDrawerState != null;

  /// What the drawer is showing
  BottomDrawerItems get content =>
      _bottomDrawerState?._content ?? BottomDrawerItems.none;

  void close() {
    try {
      _bottomDrawerState?.close();
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }

  void refresh() {
    try {
      _bottomDrawerState?.refresh();
    } catch (e) {
      debugPrint("Can't refresh bottom drawer: ${e.toString()}");
    }
  }

  void open() {
    try {
      _bottomDrawerState?.open();
    } catch (e) {
      debugPrint("Can't open bottom drawer: ${e.toString()}");
    }
  }

  /// setContent() the controller method for inserting the data into the BottomDrawer
  /// May have been also achieved through calling setState() in the parent Screen with
  /// the data to be displayed in the BottomDrawer but using a Controller is more flexible:
  /// 1 The list list of published drives for Great Drives
  /// 2 The CurrentTripItem() for My Trip

  /// open: false changes what's in the drawer without opening it - e.g.
  /// the published trips, which arrive whenever the map moves
  /// Published: opens the drawer at a trip's tile, expanded - e.g. when its
  /// label on the map is tapped
  void showTrip(String uri) => _bottomDrawerState?.showTrip(uri);

  ///
  /// The trip being planned: [openPointOfInterest] is the one to open for
  /// its details - just added - and [openHeader] opens the trip's details.
  void setContent(
      {BottomDrawerItems content = BottomDrawerItems.trip,
      List? drawerItems,
      bool open = true,
      int openPointOfInterest = -1,
      bool openHeader = false}) {
    drawerItems ??= [];
    if (content != BottomDrawerItems.none) {
      _bottomDrawerState?.setContent(content, drawerItems,
          open: open,
          openPointOfInterest: openPointOfInterest,
          openHeader: openHeader);
    } else {
      _bottomDrawerState?.close();
    }
  }

  /// How much of the map the drawer covers - its bar, plus its content when
  /// open (the old height field was never set)
  double getHeight() {
    if (!(_bottomDrawerState?.mounted ?? false)) return 0;
    return _bottomDrawerState!.context.size?.height ?? 0;
  }

  int itemsCount() {
    return _bottomDrawerState?._tiles.length ?? 0;
  }

  void setHeight(double height) {
    try {
      _bottomDrawerState?.setHeight(height: height);
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }
}

class BottomDrawer extends StatefulWidget {
  final Function(double)? onChangeHeight;
  final Function(bool)? onOpened;
  final Function(bool)? onUpdate;
  final GlobalKey? globalKey;
  final BuildContext context;
  final double maxHeight;
  final double height;
  final double closedTop;
  final double dividerHeight;
  final CurrentTripItem? content;
  final BottomDrawerController? controller;

  final ImageRepository? imageRepository;

  BottomDrawer(
      {super.key,
      required this.context,
      this.globalKey,
      this.maxHeight = 0,
      this.height = 0,
      this.closedTop = 0,
      this.onChangeHeight,
      this.onUpdate,
      this.onOpened,
      this.controller,
      this.dividerHeight = 30,
      this.content,
      this.imageRepository});

  @override
  State<BottomDrawer> createState() => _BottomDrawerState();
}

class _BottomDrawerState extends State<BottomDrawer>
    with TickerProviderStateMixin {
  double height = 0;
  double contentBottom = 0;
  double contentHeight = 0;
  int delay = 500;
  bool refreshList = true;

  final GlobalKey _scrollKey = GlobalKey();

  final PointOfInterestController _pointOfInterestController =
      PointOfInterestController();
  final TripHeaderController _tripHeaderController = TripHeaderController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  BottomDrawerItems _content = BottomDrawerItems.none;
  final Directions _directions = Directions();

  List? _drawerItems;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
  }

  Future<void> close() async {
    MapService().tripHeaderController?.dismissKeyboard();
    _pointOfInterestController.dismissKeyboard();
    FocusManager.instance.primaryFocus?.unfocus();
    await _keyboardClosed();
    if (mounted) {
      setState(() => _isSheetContentExpanded = false);
    }
  }

  /// Waits for the keyboard to finish closing so the keyboard and the drawer
  /// don't animate at the same time. Gives up after a second.
  Future<void> _keyboardClosed() async {
    for (int i = 0;
        i < 50 && mounted && View.of(context).viewInsets.bottom > 0;
        i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void refresh() {
    if (mounted) {
      setState(() => refreshList = true); // setContentBottom());
    }
  }

  void scrollTo({int index = -1}) {
    _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic);
  }

  /// setContent() uses BottomDrawerItems enum to determine how to shred the the CurrentTripItem() data.
  /// The data is displayed in a ListView. Can't use ListView.builder, as that causes problems scrolling
  /// to a GlobalKey, for a tile that the builder may have disposed of.
  /// The CurrentTripItem() data has to be shredded every time the bottom drawer gets rebuilt, as the
  /// the initiallyExpanded property is set when the tile is created.

  List<Widget> _tiles = [
    Container(
      height: 400,
      width: double.infinity,
      color: Colors.blue,
      child: Center(
        child: Text('No data',
            style: TextStyle(fontSize: 22, color: Colors.white)),
      ),
    ),
  ];

  int _openPointOfInterest = -1;
  bool _openHeader = false;

  void setContent(BottomDrawerItems content, List? drawerItems,
      {bool open = true,
      int openPointOfInterest = -1,
      bool openHeader = false}) {
    try {
      _tiles.clear();
      _content = content;
      _openPointOfInterest = openPointOfInterest;
      _openHeader = openHeader;
      _drawerItems = drawerItems ?? [];
      switch (content) {
        case BottomDrawerItems.trip:
          _tiles = shredCurrentTripItemData();
          break;
        case BottomDrawerItems.group:
          _tiles = groupTiles(); // a group drive's participants
          break;
        case BottomDrawerItems.maneuvers:
          _tiles = shredManeuvers();
          break;
        case BottomDrawerItems.tripMessages:
          _tiles = tripMessageTiles();
          break;
        case BottomDrawerItems.drives:
          _tiles = shredTrips();
        case BottomDrawerItems.planner:
          _tiles = [const PlannerPanel()];
        default:
          _tiles = shredCurrentTripItemData();
          break;
      }
      refreshList = true;
      setState(() => _isSheetContentExpanded = open || _isSheetContentExpanded);
      _tiles.add(Container(
          height: 300,
          color: Colors.transparent)); // <-- add spacer for keyboard
    } catch (e) {
      developer.log('Error setting BottomDrawer setContent(): ${e.toString()}',
          name: 'error');
    }
  }

  String _openTripUri = ''; // the published trip whose tile is open

  void showTrip(String uri) {
    if (_content != BottomDrawerItems.drives) return;
    int index = (_drawerItems ?? []).indexWhere((trip) => trip.uri == uri);
    if (index < 0) return;
    _openTripUri = uri;
    setContent(BottomDrawerItems.drives, _drawerItems);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached) scrollTo(index: index);
    });
  }

  List<Widget> shredTrips() {
    List<Widget> tiles = [];
    if (_drawerItems!.isNotEmpty) {
      for (int i = 0; i < _drawerItems!.length; i++) {
        tiles.add(
          TripTile(
            // A new tile when it opens - expanded only takes effect then
            key: ValueKey(
                '${_drawerItems![i].uri}${_drawerItems![i].uri == _openTripUri}'),
            index: i,
            tripItem: _drawerItems![i],
            expanded: _drawerItems![i].uri == _openTripUri,
            imageRepository: ImageRepository(),
          ),
        );
      }
    }
    return tiles;
  }

  void loadWebTrip(int index) async {}

  void shareWebTrip(int index) async {}

  void deleteWebTrip(int index) async {}

  List<Widget> shredManeuvers() {
    List<Widget> tiles = [];
    for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
      try {
        tiles.add(
          Card(
            key: Key('mc_$i'),
            child: ManeuverTile(
                index: i,
                maneuver: CurrentTripItem().maneuvers[i],
                routes: CurrentTripItem().routes,
                onLongPress: maneuverLongPress),
          ),
        );
      } catch (e) {
        developer.log('Error preparing maneuvers cards: ${e.toString()}',
            name: 'error');
      }
    }
    return tiles;
  }

  void maneuverLongPress(int index) async {
    CurrentTripItem().mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble(),
          ),
        ),
        duration: Duration(milliseconds: 300));

    final String fileName = await getSpeech(
        text:
            'Stop the car you idiot, I want to get out', //CurrentTripItem().maneuvers[index].modifier,
        fileName: 'text.mp3');
    if (fileName.isNotEmpty) {
      final bool exists = await File(fileName).exists();
      if (exists) {
        debugPrint('File size: ${File(fileName).lengthSync}');
        DeviceFileSource source = DeviceFileSource(fileName);
        try {
          final player = AudioPlayer(); //..setReleaseMode(ReleaseMode.stop);
          player.play(source); //(source);
        } catch (e) {
          debugPrint('Error : ${e.toString()}');
        }
      }
    }
    setState(() => _directions.currentIndex = index);
    return;
  }

  List<Widget> shredCurrentTripItemData() {
    if (_content != BottomDrawerItems.trip) return [];
    if (_openPointOfInterest >= 0 || _openHeader) {
      // Scroll to the tile that's open for its details
      int index = _openHeader ? 0 : tripPlanTileIndex(_openPointOfInterest);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached) scrollTo(index: index);
      });
    }
    return tripPlanTiles(
      openPointOfInterest: _openPointOfInterest,
      openHeader: _openHeader,
      openKey: _scrollKey,
      headerController: _tripHeaderController,
      pointOfInterestController: _pointOfInterestController,
      imageRepository: widget.imageRepository ?? ImageRepository(),
      onHeaderUpdate: headingComplete,
      onPointOfInterestUpdate: pointOfInterestComplete,
      onDelete: removePointOfInterest,
    );
  }

  void removePointOfInterest(int index, int listIndex) {
    try {
      setState(() {
        _pointOfInterestController.dismissKeyboard();
        CurrentTripItem().removePointOfInterest(index);
        _tiles.removeAt(listIndex);
      });
      if (_tiles.length < 2) {
        close();
      }
    } catch (e) {
      developer.log('error removing pointOfInterest[$index]', name: 'error');
    }
  }

  void headingComplete(bool complete) async {
    setState(() => _isSheetContentExpanded = false);
  }

  void pointOfInterestComplete(bool complete) async {
    height = 0;
    // Close first so the map update doesn't compete with the drawer animation
    await close();
    await CurrentTripItem().refreshMap(change: MapUpdates.pointsOfInterest);
  }

  void open() async {
    try {
      MapService().fabsController?.hide();
      setState(() => _isSheetContentExpanded = true);
    } catch (e) {
      developer.log('Error bottom_drawer.open(): ${e.toString()}',
          name: 'error');
    }
  }

  void setHeight({double height = 0}) {
    height = height;
  }

  /// dockOpenTile() ensures the tile to edit is visible to the user. Two issues presented themselves here while implementing
  /// this bit of code.
  /// READ THE FOLLOWING CAREFULLY IT EXPLAINS TWO IMPORTANT ISSUES -
  /// 1 When using using ExpansionTiles the initiallyExpanded value is set when the Tile is created, and doesn't change until
  ///   the tile is recreated. This means controlling the tile opening using an ordinary ListView - where the items are kept
  ///   alive is impossible.
  /// 2 Changing to a ListView builder solved issue 1, as the list is rebuilt on every setScreen, so the initiallyExpanded is
  ///   reset. However ListView builder loads the list lazily, and using GlobalKey to identify the widget to scroll to doesn't
  ///   work, as the builder has only built the visible widgets which may not include the widget with the GlobalKey to scroll to.
  ///
  /// The dockOpenTile call can only be actioned once the tiles have been created, else the GlobalKey has no currentContext.
  /// To ensure they have been created use WidgetsBinding.instance.addPostFrameCallback(... in the dockOpenTile() method.
  ///
  /// To make sure the initiallyExpanded are not stuck in the ExpansionTiles have a key: UniqueKey() which forces Flutter
  /// to rebuild the ExpansionTile's state and so updating the initiallyExpanded state.

  Point widgetPosition({required GlobalKey<State<StatefulWidget>> key}) {
    Point pos = Point(0, 0);
    final bnKeyContext = key.currentContext;
    if (bnKeyContext != null) {
      final box = bnKeyContext.findRenderObject() as RenderBox;
      pos = Point(
          box.localToGlobal(Offset.zero).dx, box.localToGlobal(Offset.zero).dy);
    }
    return pos;
  }

/*
  Following two functions are useful for understanding rebuild problems - don't delete

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    developer.log("DRAWER: Dependencies changed (likely MediaQuery/Keyboard)",
        name: '_keyboard_');
  }

  @override
  void didUpdateWidget(covariant BottomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    developer.log("DRAWER: Parent pushed new widget instance",
        name: '_keyboard_');
  }
*/

  bool _isSheetContentExpanded = false;

  void _toggleSheet() {
    developer.log('BottomDrawer()._toggleSheet()', name: '_keyboard_');
    setState(() {
      _isSheetContentExpanded = !_isSheetContentExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:
          MainAxisSize.min, // Prevents taking up full screen unless open
      children: [
        // 3. THE TAPPABLE / DRAGGABLE BAR
        GestureDetector(
          onTap: _toggleSheet, // Clicking this smoothly opens/closes the drawer
          onVerticalDragEnd: (details) {
            // Quick drag gesture checking: swipe up to open, swipe down to close
            if (details.primaryVelocity! < 0 && !_isSheetContentExpanded) {
              _toggleSheet();
            } else if (details.primaryVelocity! > 0 &&
                _isSheetContentExpanded) {
              _toggleSheet();
            }
          },
          child: Container(
            width: double.infinity,
            color: Colors.blueGrey,
            // .transparent, // Ensures the entire bar width is interactive
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400], // Clean visual pill asset
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // 4. THE DATA CONTENT ZONE
        // AnimatedCrossFade handles animating your list smoothly out of view
        // without leaving weird data text fragments visible when closed.
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 500),
          crossFadeState: _isSheetContentExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          // WHAT SHOWS WHEN EXPANDED: Your full scrolling API list data
          firstChild: Container(
            constraints: BoxConstraints(
              // Locks the drawer to exactly 45% of whatever screen height they have
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            // Can scroll to a tile - e.g. a trip tapped on the map
            child: ScrollablePositionedList.builder(
                shrinkWrap: true,
                itemScrollController: _itemScrollController,
                itemCount: _tiles.length,
                itemBuilder: (context, index) => _tiles[index]),
          ),
          // WHAT SHOWS WHEN CLOSED: Absolutely nothing (SizedBox with 0 height)
          // This makes the drag bar sit flush right against your bottom navigation bar!
          secondChild: const SizedBox.shrink(),
          onEnd: () {
            if (!_isSheetContentExpanded) {
              MapService().fabsController?.show();
            } else {
              MapService().fabsController?.hide();
            }
          },
        ),
      ],
    );
  }
}
