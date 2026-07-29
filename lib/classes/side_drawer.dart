import 'dart:math';
import 'package:drives/screens/screens.dart';
import '../routes/messages.dart';
import '../classes/classes.dart';
import '../models/models.dart';
import '../tiles/tiles.dart';
import '../services/services.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:audioplayers/audioplayers.dart';
import 'package:universal_io/universal_io.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// The Map pages SideDrawer is to allow the following data
/// Trip details on planning and saving
/// Display of waypoints and points of interest

class SideDrawerController {
  _SideDrawerState? _sideDrawerState;

  void _addState(_SideDrawerState sideDrawerState) {
    _sideDrawerState = sideDrawerState;
  }

  void close() {
    try {
      _sideDrawerState?.close();
    } catch (e) {
      debugPrint("Can't close side drawer: ${e.toString()}");
    }
  }

  void refresh() {
    try {
      _sideDrawerState?.refresh();
    } catch (e) {
      debugPrint("Can't refresh side drawer: ${e.toString()}");
    }
  }

  /* void dockOpenTile() {
    try {
      _sideDrawerState?.dockOpenTile();
    } catch (e) {
      debugPrint("Can't dock open tile: ${e.toString()}");
    }
  }
*/
  void scrollTo({int index = -1}) {
    try {
      _sideDrawerState?.scrollTo(index: index);
    } catch (e) {
      debugPrint("Can't scroll to tile[$index] - ${e.toString()}");
    }
  }

  void open({width = 0}) {
    try {
      _sideDrawerState?.open(width);
    } catch (e) {
      developer.log("Can't open side drawer: ${e.toString()}", name: 'error');
    }
  }

  /// setContent() the controller method for inserting the data into the SideDrawer
  /// May have been also achieved through calling setState() in the parent Screen with
  /// the data to be displayed in the SideDrawer but using a Controller is more flexible:
  /// 1 The list list of published drives for Great Drives
  /// 2 The CurrentTripItem() for My Trip

  Future<void> setContent({
    required BottomDrawerItems content,
    List? drawerItems,
  }) async {
    drawerItems ??= [];

    if (content != BottomDrawerItems.none || drawerItems.isNotEmpty) {
      try {
        _sideDrawerState?.setContent(
          content: content,
          drawerItems: drawerItems,
        );
      } catch (e) {
        developer.log(
            'Error trying to write to the SideDrawer: ${e.toString()}',
            name: 'error');
      }
    } else {
      _sideDrawerState?.close();
    }
  }

  BottomDrawerItems get content => _sideDrawerState!._content;

  List<Widget> get screenCache => _sideDrawerState!._screenCache;

  bool get changed => _sideDrawerState!._changed;

  bool get offerRestore => _sideDrawerState!._offerRestore;

  double getWidth() {
    return _sideDrawerState?.width ?? 0;
  }

  void clearCache() {
    _sideDrawerState?.clearCache();
  }

  int itemsCount() {
    return _sideDrawerState?._tiles.length ?? 0;
  }

  void setFixed({bool fixed = false}) {
    if (_sideDrawerState != null) {
      _sideDrawerState?._fixed = fixed;
    }
  }

  void setVisible({bool visible = true}) {
    if (_sideDrawerState != null) {
      _sideDrawerState?.changeVisibility(visible);
    }
  }

  // bool get isAttached => _sideDrawerState? != null;

  bool get isAttached => _sideDrawerState != null;

  bool get isOpen => (_sideDrawerState?.width ?? 0) > 20;

  bool get isFixed => _sideDrawerState!._fixed;

  void setWidth(width) {
    try {
      _sideDrawerState?.setWidth(width: width);
    } catch (e) {
      developer.log("Can't close side drawer: ${e.toString()}", name: 'error');
    }
  }
}

class SideDrawer extends StatefulWidget {
  final Function(double)? onChangeWidth;
  final Function(bool)? onOpened;
  final Function(BottomDrawerItems, int)? onUpdate;
  final GlobalKey? globalKey;
  final BuildContext context;
  final double maxWidth;
  final double width;
  final double closedTop;
  final double dividerWidth;
  final CurrentTripItem? content;
  SideDrawerController? controller;
  WebAppBarController? webAppBarController;
  final ImageRepository? imageRepository;
  MapLibreMapController? _mapController;

  SideDrawer(
      {super.key,
      required this.context,
      this.controller,
      this.webAppBarController,
      this.globalKey,
      this.maxWidth = 0,
      this.width = 0,
      this.closedTop = 0,
      this.onChangeWidth,
      this.onOpened,
      this.onUpdate,
      //  this.requestClose,
      this.dividerWidth = 30,
      this.content,
      this.imageRepository,
      MapLibreMapController? mapController})
      : _mapController = mapController;

  MapLibreMapController get mapController => _mapController!;

  set mapController(MapLibreMapController controller) =>
      _mapController = controller;

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> with TickerProviderStateMixin {
  double width = 0;
  double contentSide = 0;
  // double contentWidth = 100;
  double _mapWidth = 600;
  double _maxWidth = 400;
  double _openWidth = 200;
  int _messageIndex = -1;
  List<Widget> _screenCache = [];
  // List<bool> _isExpanded = [];
  int delay = 500;
  bool refreshList = true;

  bool _offerRestore = false;

  final GlobalKey _animatedContainerKey = GlobalKey();
  final GlobalKey _scrollKey = GlobalKey();
  final PointOfInterestController _pointOfInterestController =
      PointOfInterestController();
  final TripHeaderController _tripHeaderController = TripHeaderController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  BottomDrawerItems _content = BottomDrawerItems.none;
  final Directions _directions = Directions();

  late final RotatingIconController _rotatingIconController;
  late final PointOfInterestController _poiController;

  // MapLibreMapController get mapController => widget._mapController!;
  late final ImageRepository imageRepository;

  bool _changed = false;
  List? _drawerItems;

  bool _fixed = true; // going to start on the Home screen
  bool _visible = true;

  @override
  void initState() {
    super.initState;
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    imageRepository = widget.imageRepository ?? ImageRepository();
    _rotatingIconController = RotatingIconController();
    _poiController = PointOfInterestController();
    /*
      _mapWidth = MediaQuery.of(context).size.width;
      _maxWidth = _mapWidth * widget.maxWidth;
      _openWidth = _mapWidth * widget.width;
      width = _openWidth;
    */
  }

/*
  @override
  void dispose() {
    super.dispose();
  }
*/
  void close() {
    if (mounted) {
      developer.log(
          'SideDrawer().close() called BottomDrawerItems.${_content.toString()}',
          name: '_poi_');
      setState(() => width = 0);
      // }
    }
  }

  void refresh() {
    if (mounted) {
      refreshList = true;
      setState(() {}); // setContentSide());
    }
  }

  void clearCache() {
    _screenCache.clear();
  }

  void changeVisibility(bool visible) {
    width = _mapWidth * 0.4;
    setState(() => _visible = visible);
  }

  void scrollTo({int index = -1}) {
    if (index > -1) {
      _itemScrollController.scrollTo(
          index: index,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    }
  }

  /// setContent() uses BottomDrawerItems enum to determine how to shred the the CurrentTripItem() data.
  /// The data is displayed in a ListView. Can't use ListView.builder, as that causes problems scrolling
  /// to a GlobalKey, for a tile that the builder may have disposed of.
  /// The CurrentTripItem() data has to be shredded every time the side drawer gets rebuilt, as the
  /// the initiallyExpanded property is set when the tile is created.

  List<Widget> _tiles = [];

/*
  int itemsCount() {
    return _tiles.length;
  }
*/

  Future<void> setContent({
    required BottomDrawerItems content,
    List? drawerItems,
  }) async {
    drawerItems ??= [];
    try {
      _content = content;
      _drawerItems = drawerItems;
      _offerRestore = false; // default state
      switch (content) {
        case BottomDrawerItems.home:
          _tiles = List<Widget>.from(_drawerItems!);
          _screenCache = _tiles;
          break;
        case BottomDrawerItems.trip:
          _tiles = shredCurrentTripItemData();
          _screenCache = _tiles;
          break;
        case BottomDrawerItems.group:
          _tiles = shredGroup(followers: _drawerItems as List<Follower>);
          _offerRestore = true;
          break;
        case BottomDrawerItems.maneuvers:
          _tiles = shredManeuvers();
          _offerRestore = true;
          break;
        case BottomDrawerItems.cached:
          _tiles = _screenCache;
          break;
        case BottomDrawerItems.goodRoad:
          _tiles = shredPointsOfInterest(type: 13);
          _offerRestore = true;
          break;
        case BottomDrawerItems.drives:
          _tiles = shredTrips();
          _screenCache = _tiles;
          break;
        case BottomDrawerItems.favourites:
          _tiles = shredFavourites();
          _screenCache = _tiles;
          break;
        case BottomDrawerItems.settings:
          _tiles = [
            SetupView(
              onChange: (value) {
                _changed = true;
              },
            )
          ];
          _offerRestore = true;
          break;
        case BottomDrawerItems.register:
          _tiles = [SignupForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.myGroups:
          _tiles = [GroupForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.groups:
          _tiles = [MyGroupsForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.invite:
          _tiles = [IntroduceForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.myEvents:
          _tiles = [GroupDriveForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.events:
          _tiles = [InvitationsScreen()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.messages:
          _tiles = [
            Messages(
              index: _messageIndex, // <-- debugging
              onSelect: (index) => messageDetails(index),
              webAppBarController: widget.webAppBarController,
              onBackClick: () {
                setState(() => _messageIndex = -1);
              },
            ),
          ];
          _offerRestore = true;
          break;
        default:
          _tiles = shredCurrentTripItemData();
          break;
      }
      // setState(() => refreshList = true);
      refreshList = true;
    } catch (e) {
      developer.log('Error setting SideDrawer setContent(): ${e.toString()}',
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
            imageRepository: imageRepository,
          ),
        );
      }
    }
    return tiles;
  }

  void messageDetails(index) {
    setState(() {
      _messageIndex = index;
      _tiles = [
        //  SidebarMessages(),

        Messages(
          index: _messageIndex, // <-- debugging
          onSelect: (index) => messageDetails(index),
          onBackClick: () {
            setState(() => _messageIndex = -1);
          },
        ),
      ];
    });
    // widget.onUpdate!(BottomDrawerItems.messages, index);
    // _messageIndex = index;
    // setContent(BottomDrawerItems.messages, []);
  }

  List<Widget> shredFavourites() {
    List<Widget> tiles = [
      Center(
          child: Text('No information',
              style: TextStyle(fontSize: 20, color: Colors.black)))
    ];

    if ((_drawerItems ?? []).isNotEmpty) {
      tiles.clear();
      for (int i = 0; i < _drawerItems!.length; i++) {
        if (_drawerItems![i] != null) {
          try {
            tiles.add(
              MyTripTile(
                index: i,
                myTripItem: _drawerItems![i],
                onDeleteTrip: (index) =>
                    setState(() => _drawerItems!.removeAt(index)),
                imageRepository: imageRepository,
                onExpandChange: (index, expanded) =>
                    getTripDetails(index, expanded),
                mapController: MapService().controller,
                showMethods: true,
              ),
            );
          } catch (e) {
            developer.log(
                'Error adding a TripTile to the side-drawer content: ${e.toString()}',
                name: 'error');
          }
        }
      }
    }

    return tiles;
  }

  List<Widget> shredGroup({List<Follower>? followers}) {
    followers ??= [];
    List<Widget> tiles = [];
    _tiles.clear();
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

  getTripDetails(index, expanded) async {
    if (expanded && widget._mapController != null) {}
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
    _tiles.clear();
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
    ExpandNotifier expandNotifier = ExpandNotifier(1);
    bool expanded = false;
    int index = 0;
    int selected = -1;
    List<Widget> tiles = [];
    int j = 0;
    if (_content == BottomDrawerItems.trip) {
      // developer.log(
      //     'SideDrawer().shredCurrentTripItemData() called CurrentTripItem().tripState:${CurrentTripItem().tripState.toString()} CurrentTripItem().headerComplete():${CurrentTripItem().headerComplete()}',
      //     name: '_expand_');
      expanded = CurrentTripItem().headerComplete() != 7;
      tiles.add(
        Padding(
          key: Key('th1'),
          padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
          child: TripHeaderTile(
            key: Key('tht_1'),
            index: 0,
            controller: _tripHeaderController,
            tripItem: CurrentTripItem(),
            expanded: false, //!headerComplete,
            appState: CurrentTripItem().appState,
            onUpdate: (complete) => headingComplete(complete),
          ),
        ),
      );

      for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
        if (![
          12,
          14,
          17,
          18
        ] // <-- exclude waypoint, great road start, start & end
            .contains(CurrentTripItem().pointsOfInterest[i].type)) {
          bool complete = CurrentTripItem().pointsOfInterest[i].complete() == 3;
          expanded = !complete;
          tiles.add(
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
              key: Key('poi$i'),
              child: PointOfInterestTile(
                key: Key('poit_${j++}'),
                index: i, // ndex,
                listIndex: j++,
                expanded: false, //!complete || selected == i,
                //   controller: expanded ? _pointOfInterestController : null,
                pointOfInterest: CurrentTripItem().pointsOfInterest[i],
                imageRepository: imageRepository,
                onUpdate: pointOfInterestComplete,
                onDelete: (index, lIndex) =>
                    pointOfInterestDelete(index, lIndex),
                driveId: CurrentTripItem().driveUri,
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
    int j = 0;
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if ((![12, 14, 17, 18]
                  .contains(CurrentTripItem().pointsOfInterest[i].type) &&
              type == -1) ||
          CurrentTripItem().pointsOfInterest[i].type == type) {
        tiles.add(
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
            key: Key('poi$i'),
            child: PointOfInterestTile(
              key: Key('poi$i'), // UniqueKey(),
              index: i,
              listIndex: j++,
              controller: _pointOfInterestController,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              imageRepository: imageRepository,
              driveId: CurrentTripItem().driveUri,
              onDelete: (index, lIndex) => pointOfInterestDelete(index, lIndex),
              onUpdate: pointOfInterestComplete,
            ),
          ),
        );
      }
    }
    return tiles;
  }

  void pointOfInterestDelete(int index, int lIndex) {
    CurrentTripItem().pointsOfInterest.removeAt(index);
    setState(() => _tiles.removeAt(lIndex));
  }

  void headingComplete(bool complete) {
    close();
  }

  void pointOfInterestComplete(bool complete) async {
    CurrentTripItem()
        .refreshMap(change: MapUpdates.pointsOfInterest)
        .then((_) => close());
  }

  void open(newWidth) async {
    // _openWidth = width > 0 ? width : 0.4; //_openWidth;
    //  if (_fixed) {
    //    setState(() => _visible = true);
    //  } else {
    newWidth = 0.4;
    _visible = true;
    bool changed = newWidth != width; //  false;
    try {
      //   setContentSide();
      delay = 500;
      width = _mapWidth * newWidth;
    } catch (e) {
      developer.log('Error side_drawer.open(): ${e.toString()}', name: 'error');
    }
    try {
      if (mounted && changed) {
        setState(() {});
      }
    } catch (e) {
      developer.log('Error side_drawer.open(): ${e.toString()}', name: 'error');
    }
    if (!_rotatingIconController.rotated) {
      _rotatingIconController.rotate();
    }
    //  }
  }

  void setWidth({double width = 0}) {
    width = width;
  }

  /// dockOpenTile() ensures the tile to edit is visible to the user. Two issues presented themselves here while implementing
  /// this bit of code.
  /// READ THE FOLLOWING CAREFULLY IT EXPLAINS TWO IMPORTANT ISSUES -
  /// 1 When using using ExpansionTiles the initiallyExpanded value is set when the Tile is created, and doesn't change until
  ///   the tile is recreated. This means controlling the tile opening using an ordinary ListView - where the items are kept
  ///   alive is impossible.
  /// 2 Changing to a ListView builder solved issue 1, as the list is rebuilt on ever setScreen, so the initiallyExpanded is
  ///   reset. However ListView builder loads the list lazily, and using GlobalKey to identify the widget to scroll to doesn't
  ///   work, as the builder has only built the visible widgets which may not include the widget with the GlobalKey to scroll to.
  ///
  /// The dockOpenTile call can only be actioned once the tiles have been created, else the GlobalKey has no currentContext.
  /// To ensure they have been created use WidgetsBinding.instance.addPostFrameCallback(... in the dockOpenTile() method.
  ///
  /// To make sure the initiallyExpanded are not stuck in the ExpansionTiles have a key: UniqueKey() which forces Flutter
  /// to rebuild the ExpansionTile's state and so updating the initiallyExpanded state.

/*
  void dockOpenTile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // int index = _tiles.indexWhere()

        var box = _scrollKey.currentContext!.findRenderObject() as RenderBox;
        //  width = box.size.width < 400 ? box.size.width + 4 : 400;
        Scrollable.ensureVisible(
          _scrollKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // 0.0 = top of screen, 0.5 = middle, 1.0 = side
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
*/

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

  void setContentSide({double offset = 0}) {
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
  void didUpdateWidget(covariant SideDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    developer.log("DRAWER: Parent pushed new widget instance",
        name: '_keyboard_');
  }
*/

  @override
  Widget build(BuildContext context) {
    double dividerWidth = 35;
    _mapWidth = MediaQuery.of(context).size.width;
    _maxWidth = _mapWidth * widget.maxWidth;
    _openWidth = _mapWidth * widget.width;
    WidgetsBinding.instance.addPostFrameCallback((_) => openIncompleteTiles());
    double mapHeight = MediaQuery.of(context).size.height; //width;
    // MapService().mapHeight;

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
    //  width = _mapWidth * 0.4; // <-- debug
    //  _visible = true; // <-- debug
    //   _fixed = false; // <-- debug

    double leftPadding = _fixed ? 10 : 0;
    return FocusScope(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(leftPadding, 0, 0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                alignment: AlignmentDirectional(0, 0),
                key: _animatedContainerKey,
                duration: Duration(milliseconds: delay),
                curve: Curves.easeOut, // fastOutSlowIn,
                width: width >= dividerWidth ? width - dividerWidth : 0,
                height: mapHeight,
                onEnd: () async {
                  if (widget.onOpened != null) {
                    widget.onOpened!(width > 10);
                  }
                },
                //  child: PointerInterceptor(
                // absorbing: false,
                child: AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
                    child: Container(
                      width: width > dividerWidth ? width - dividerWidth : 0,
                      child: Card(
                        elevation: 7,
                        shadowColor: const Color.fromARGB(255, 99, 98, 98),
                        child: SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: Container(
                            width: width,
                            height: mapHeight,
                            color: const Color.fromRGBO(54, 143, 244, 0.411),
                            child: ScrollablePositionedList.builder(
                                itemScrollController: _itemScrollController,
                                itemCount: _tiles.length,
                                itemBuilder: (navContext, index) =>
                                    _tiles[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                //     ),
              ),
              if (!_fixed) ...[
                //     PointerInterceptor(
                //       child:
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: AbsorbPointer(
                    child: Container(
                      color: const Color.fromARGB(30, 71, 71, 71),
                      width: dividerWidth,
                      height: mapHeight,
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 0),
                        child: RotatingIcon(
                          icon: Icon(
                            Icons.arrow_circle_right_outlined,
                            size: dividerWidth,
                            color: Colors.blueAccent,
                          ),
                          controller: _rotatingIconController,
                          size: dividerWidth,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    setContentSide();
                    _pointOfInterestController.dismissKeyboard();
                    delay = 500;
                    if (widget.onOpened != null) {
                      widget.onOpened!(width > 10);
                    }
                    setState(() {
                      width = width > 10 ? 0 : _openWidth;
                      if (width == 0 && _rotatingIconController.rotated ||
                          width > 0 && !_rotatingIconController.rotated) {
                        _rotatingIconController.rotate();
                      }
                    });
                    debugPrint('onTap: => width: $width');
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    if (delay > 1) setContentSide();
                    setState(() {
                      delay = 1;
                      width = width + details.delta.dx < _maxWidth
                          ? width + details.delta.dx
                          : _maxWidth;
                      if (widget.onChangeWidth != null) {
                        widget.onChangeWidth!(width);
                      }
                      if (width < 50) {
                        // FocusScope.of(context).unfocus();
                        // _pointOfInterestController.dismissKeyboard();
                      }
                      if (width <= 20 && _rotatingIconController.rotated ||
                          width > 20 && !_rotatingIconController.rotated) {
                        _rotatingIconController.rotate();
                      }
                    });
                  },
                ),
                //    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void openIncompleteTiles() {
    /*
    int j = 0;
        if (CurrentTripItem().title.isEmpty ||
            CurrentTripItem().subTitle.isEmpty ||
            CurrentTripItem().body.isEmpty) {
          _tripHeaderController.expand();
        } else {
          _tripHeaderController.collapse();
        }
      for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++){

      }
      } else {
        (![9, 11, 12, 16, 18, 19].contains(
        Padding padding = _tiles[i] as Padding;
        PointOfInterestTile poiTile = padding!.child;
        //  PointOfInterest poi = poiTile.pointOfInterest;

        developer.log(
            'openIncompleteTiles() called on poiTile poiTile.pointOfInterest.name: ${poi.name}',
            name: '_trips_');
        if (poiTile.pointOfInterest.name.isEmpty ||
            poiTile.pointOfInterest.description.isEmpty) {
          poiTile.controller = _poiController;
          _poiController.expand();
        } else {
          _poiController.collapse();
        }
      }
    }
    */
    /*   for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
        if(![9, 11, 12, 16, 18, 19].contains(CurrentTripItem().pointsOfInterest[i].type)) {
          if (CurrentTripItem().pointsOfInterest[i].name.isEmpty || CurrentTripItem().pointsOfInterest[i].description.isEmpty) {
            CurrentTripItem().pointsOfInterest[i].
          }
        }
      }
    } */
  }
}
/*
class SidebarMessages extends StatelessWidget {
  @override
  build(BuildContext context) {
    return Column(children: [
      ScreensAppBarBottom(
        leadingButton:
            IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back)),
        prompt: 'Test message',
      ),
      Messages()
    ]);
  }
}
*/
