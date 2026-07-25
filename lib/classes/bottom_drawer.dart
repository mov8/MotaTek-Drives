import 'dart:math';
import '../classes/classes.dart';
import '../models/models.dart';
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

  void dockOpenTile() {
    try {
      _bottomDrawerState?.dockOpenTile();
    } catch (e) {
      debugPrint("Can't dock open tile: ${e.toString()}");
    }
  }

  void open({height = 0}) {
    try {
      _bottomDrawerState?.open(height);
    } catch (e) {
      debugPrint("Can't open bottom drawer: ${e.toString()}");
    }
  }

  /// setContent() the controller method for inserting the data into the BottomDrawer
  /// May have been also achieved through calling setState() in the parent Screen with
  /// the data to be displayed in the BottomDrawer but using a Controller is more flexible:
  /// 1 The list list of published drives for Great Drives
  /// 2 The CurrentTripItem() for My Trip

  void setContent(
      {BottomDrawerItems content = BottomDrawerItems.trip, List? drawerItems}) {
    drawerItems ??= [];
    if (content != BottomDrawerItems.none) {
      _bottomDrawerState?.setContent(content, drawerItems);
    } else {
      _bottomDrawerState?.close();
    }
  }

  double getHeight() {
    return _bottomDrawerState?.height ?? 0;
  }

  int itemsCount() {
    return _bottomDrawerState?._tiles.length ?? 0;
  }

  void setHeight(height) {
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
  // final Function(bool)? requestClose;
  final GlobalKey? globalKey;
  final BuildContext context;
  final double maxHeight;
  final double height;
  final double closedTop;
  final double dividerHeight;
  final CurrentTripItem? content;
  final BottomDrawerController? controller;
  final ImageRepository? imageRepository;

  const BottomDrawer(
      {super.key,
      required this.context,
      this.controller,
      this.globalKey,
      this.maxHeight = 0,
      this.height = 0,
      this.closedTop = 0,
      this.onChangeHeight,
      this.onOpened,
      //  this.requestClose,
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
  // List<bool> _isExpanded = [];
  int delay = 500;
  bool refreshList = true;

  final GlobalKey _animatedContainerKey = GlobalKey();
  final GlobalKey _scrollKey = GlobalKey();

  final PointOfInterestController _pointOfInterestController =
      PointOfInterestController();
  final ScrollController _scrollController = ScrollController();
  final TripHeaderController _tripHeaderController = TripHeaderController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  BottomDrawerItems _content = BottomDrawerItems.none;
  final Directions _directions = Directions();

  List? _drawerItems;

  @override
  void initState() {
    super.initState;
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
  }

/*
  @override
  void dispose() {
    super.dispose();
  }
*/
  void close() {
    if (mounted) {
      setState(() => height = 0);
    }
  }

  void refresh() {
    if (mounted) {
      refreshList = true;
      setState(() {}); // setContentBottom());
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

  List<Widget> _tiles = [];

/*
  int itemsCount() {
    return _tiles.length;
  }
*/

  void setContent(BottomDrawerItems content, List? drawerItems) {
    try {
      _content = content;
      _drawerItems = drawerItems ?? [];
      switch (content) {
        case BottomDrawerItems.trip:
          _tiles = shredCurrentTripItemData();
          break;
        case BottomDrawerItems.group:
          _tiles = shredGroup(followers: _drawerItems as List<Follower>);
          break;
        case BottomDrawerItems.maneuvers:
          _tiles = shredManeuvers();
          break;
        case BottomDrawerItems.messages:
          _tiles = shredMessages();
          break;
        case BottomDrawerItems.goodRoad:
          _tiles = shredPointsOfInterest(type: 13);
          break;
        case BottomDrawerItems.drives:
          _tiles = shredTrips();
        default:
          _tiles = shredCurrentTripItemData();
          break;
      }
      refreshList = true;
    } catch (e) {
      developer.log('Error setting BottomDrawer setContent(): ${e.toString()}',
          name: 'error');
    }
  }

  List<Widget> shredTrips() {
    List<Widget> tiles = [];
    if (_drawerItems!.isNotEmpty) {
      for (int i = 0; i < _drawerItems!.length; i++) {
        tiles.add(
          TripTile(
            index: i,
            tripItem: _drawerItems![i],
            imageRepository: ImageRepository(),
          ),
        );
      }
    }
    return tiles;
  }

  loadWebTrip(int index) async {}

  shareWebTrip(int index) async {}

  deleteWebTrip(int index) async {}

  List<Widget> shredGroup({List<Follower>? followers}) {
    followers ??= [];
    List<Widget> tiles = [];
    bool expanded = false;
    for (int i = 0; i < followers.length; i++) {
      tiles.add(Padding(
        key: expanded ? _scrollKey : Key('th1'),
        padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
        child: FollowerTile(
          follower: followers[i],
          index: i,
          onIconClick: followerIconClick,
          onLongPress: followerLongPress,
          distance: 0,
          currentPosition: CurrentTripItem().tripValues.position, // Point(
          //   CurrentTripItem().tripValues.position.x,
          //   CurrentTripItem().tripValues.pos
          //       .tripValues
          //       .position
          //       .x), // ToDo: calculate how far away
        ),
      ));
    }

    return tiles;
  }

  Future<void> followerIconClick(int index) async {
    String message = ''; // await messageGroup(index);
    if (message.isNotEmpty) {}
    return;
  }

  void followerLongPress(int index) {
    // CurrentTripItem().tripValues.showTarget = true;

    CurrentTripItem().mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble(),
          ),
        ),
        duration: Duration(milliseconds: 300));
    return;
  }

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
    // CurrentTripItem().tripValues.showTarget = true;

    CurrentTripItem().mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble(),
          ),
        ),
        duration: Duration(milliseconds: 300));

    // debugPrint('index: $index moved: ${moved ?? false}');
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
          // player.setSourceAsset(fileName);
          player.play(source); //(source);
        } catch (e) {
          debugPrint('Error : ${e.toString()}');
        }
      }
    }
    setState(() => _directions.currentIndex = index);
    return;
  }

  List<Widget> shredMessages() {
    List<Widget> tiles = [];
    for (int i = 0; i < CurrentTripItem().tripMessages.length; i++) {
      tiles.add(
        TripMessageTile(
          index: i,
          message: CurrentTripItem().tripMessages[i],
          onEdit: (_) {},
          onSelect: (_) {},
        ),
      );
    }
    return tiles;
  }

  List<Widget> shredCurrentTripItemData() {
    bool expanded = false;
    List<Widget> tiles = [];
    if (_content == BottomDrawerItems.trip) {
      expanded = CurrentTripItem().headerComplete() != 7;
      tiles.add(
        Padding(
          key: expanded ? _scrollKey : Key('th1'),
          padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
          child: TripHeaderTile(
            key: Key('tht_1'),
            index: 0,
            controller: _tripHeaderController,
            tripItem: CurrentTripItem(),
            expanded: expanded, //!headerComplete,
            appState: CurrentTripItem().appState,
            onUpdate: (complete) => headingComplete(complete),
          ),
        ),
      );
      for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
        if (![12, 14, 17, 18]
            .contains(CurrentTripItem().pointsOfInterest[i].type)) {
          bool complete = CurrentTripItem().pointsOfInterest[i].complete() == 3;
          Key tileKey = complete || expanded
              ? Key('poi$i')
              : complete
                  ? Key('poi$i')
                  : _scrollKey;
          expanded = expanded ? expanded : tileKey == _scrollKey;
          tiles.add(
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
              key: tileKey,
              child: PointOfInterestTile(
                key: Key('poit_$i'), // UniqueKey(),
                index: i + 1,
                expanded: expanded,
                controller: expanded ? _pointOfInterestController : null,
                pointOfInterest: CurrentTripItem().pointsOfInterest[i],
                imageRepository: widget.imageRepository ?? ImageRepository(),
                onUpdate: pointOfInterestComplete,
                driveId: CurrentTripItem().uri,
              ),
            ),
          );
        }
      }
    }
    return tiles;
  }

  List<Widget> shredPointsOfInterest({int type = -1}) {
    bool expanded = false;
    List<Widget> tiles = [];
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if ((![12, 14, 17, 18]
                  .contains(CurrentTripItem().pointsOfInterest[i].type) &&
              type == -1) ||
          CurrentTripItem().pointsOfInterest[i].type == type) {
        bool complete = CurrentTripItem().pointsOfInterest[i].complete() == 3;
        Key tileKey = complete || expanded
            ? Key('poi$i')
            : complete
                ? Key('poi$i')
                : _scrollKey;
        expanded = expanded ? expanded : tileKey == _scrollKey;
        tiles.add(
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
            key: tileKey,
            child: PointOfInterestTile(
              key: Key('poit_$i'), // UniqueKey(),
              index: i + 1,
              expanded: expanded,
              controller: expanded ? _pointOfInterestController : null,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              imageRepository: widget.imageRepository ?? ImageRepository(),
              driveId: CurrentTripItem().driveUri,
              onUpdate: pointOfInterestComplete,
            ),
          ),
        );
      }
    }
    return tiles;
  }

  void headingComplete(bool complete) {
    close();
  }

  void pointOfInterestComplete(bool complete) async {
    //  _pointOfInterestController.dismissKeyboard();
    CurrentTripItem()
        .refreshMap(change: MapUpdates.pointsOfInterest)
        .then((_) => close());
  }

  void open(newHeight) async {
    bool changed = false;
    try {
      setContentBottom();
      delay = 500;
      height = height == 0
          ? newHeight == 0
              ? widget.maxHeight
              : newHeight.toDouble()
          : 0;
      changed = contentHeight != height;
      contentHeight = height; // MediaQuery.of(context).size.height;
    } catch (e) {
      developer.log('Error bottom_drawer.open(): ${e.toString()}',
          name: 'error');
    }
    try {
      if (mounted && changed) {
        setState(() {});
      }
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

  void dockOpenTile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        var box = _scrollKey.currentContext!.findRenderObject() as RenderBox;
        height = box.size.height < 400 ? box.size.height + 4 : 400;
        Scrollable.ensureVisible(
          _scrollKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // 0.0 = top of screen, 0.5 = middle, 1.0 = bottom
        );
        double yPos = widgetPosition(key: _animatedContainerKey).y.toDouble();
        double yPosT = widgetPosition(key: _scrollKey).y.toDouble();
        double delta = 32 + yPosT - yPos;
        if (delta > 0) {
          _scrollController.animateTo(delta,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        }
      } catch (e) {
        developer.log('Error dockOpenTile(): ${e.toString()}', name: 'error');
      }
    });
  }

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

  void setContentBottom({double offset = 0}) {
    try {
      contentBottom = contentBottom == 0 &&
              widgetPosition(key: _animatedContainerKey).y > 300
          ? widgetPosition(key: _animatedContainerKey).y + offset
          : contentBottom;
    } catch (e) {
      developer.log('Error bottom_drawer.setContentBottom(): ${e.toString()}',
          name: 'error');
    }
    return;
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

  @override
  Widget build(BuildContext context) {
    double dividerHeight = 35;

    /// Ensure a fresh set of tiles is generated to ensure the initiallyExpanded value is
    /// set to reflect the completeness of the tile's content.
    /// The flag refreshList ensures that the list is only re-built when the data has changed
    /// otherwise as Flutter calls rebuild that haven't been initiated with a setState(), and that
    /// causes problems with the focus calling the keyboard. It is only set when the controller.refresh()
    /// or controller.setContent() are called.

    // if (refreshList) {
    //   _tiles = shredCurrentTripItemData();
    //   refreshList = false;
    // }

    return Align(
      alignment: Alignment.bottomLeft,
      child: AnimatedContainer(
        key: _animatedContainerKey,
        duration: Duration(milliseconds: delay),
        curve: Curves.easeOut, // fastOutSlowIn,
        height: height + dividerHeight,
        width: mounted ? MediaQuery.of(context).size.width : 100,
        onEnd: () async {
          contentHeight = height;
          if (widget.onOpened != null) {
            widget.onOpened!(height > 10);
          }
        },
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: AbsorbPointer(
                      child: Container(
                        color: const Color.fromARGB(255, 158, 158, 158),
                        height: dividerHeight,
                        width: MediaQuery.of(context).size.width,
                        child: Icon(
                          Icons.drag_handle,
                          size: dividerHeight,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    onTap: () => setState(() {
                      setContentBottom();
                      _pointOfInterestController.dismissKeyboard();
                      delay = 500;
                      height = height == 0 ? widget.maxHeight : 0;
                      contentHeight = height == 0 ? contentHeight : height;
                      if (height < 10 && widget.onOpened != null) {
                        height = 0;
                        widget.onOpened!(false);
                      }
                      debugPrint('height: $height');
                    }),
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      if (delay > 1) setContentBottom();
                      setState(() {
                        delay = 1;
                        height = height - details.delta.dy > 0
                            ? height - details.delta.dy
                            : 0;
                        if (widget.onChangeHeight != null) {
                          widget.onChangeHeight!(height);
                        }
                        if (height < 50) {
                          FocusScope.of(context).unfocus();
                          _pointOfInterestController.dismissKeyboard();
                        }
                      });
                    },
                  ),
                  SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Container(
                      height: contentHeight,
                      color: Colors.blue,

                      // child: ScrollablePositionedList.(itemCount: _tiles.length, itemBuilder: (context, index) => _tiles[index])),

                      child: ListView(
                        controller: _scrollController,
                        children: _tiles,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
