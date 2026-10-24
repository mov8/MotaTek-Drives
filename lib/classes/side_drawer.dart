import 'dart:math';
import 'package:drives/screens/screens.dart';
import '../routes/my_trips.dart';
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

  /// animate: false closes it at once - e.g. when switching to a map page,
  /// so the page doesn't appear with the drawer open and then close it
  void close({bool animate = true}) {
    try {
      _sideDrawerState?.close(animate: animate);
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

  /// Published: opens the drawer at a trip's tile, expanded - e.g. when its
  /// label on the map is tapped
  void showTrip(String uri) => _sideDrawerState?.showTrip(uri);

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

  ///
  /// The trip being planned: [openPointOfInterest] is the one to open for
  /// its details - just added - and [openHeader] opens the trip's details.
  Future<void> setContent({
    required BottomDrawerItems content,
    List? drawerItems,
    int openPointOfInterest = -1,
    bool openHeader = false,
  }) async {
    drawerItems ??= [];

    if (content != BottomDrawerItems.none || drawerItems.isNotEmpty) {
      try {
        _sideDrawerState?.setContent(
          content: content,
          drawerItems: drawerItems,
          openPointOfInterest: openPointOfInterest,
          openHeader: openHeader,
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

  BottomDrawerItems get content =>
      _sideDrawerState?._content ?? BottomDrawerItems.none;

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
  double _mapWidth = 600;
  double _maxWidth = 400;
  double _openWidth = 200;
  List<Widget> _screenCache = [];
  int delay = 500;
  bool refreshList = true;

  bool _offerRestore = false;

  final GlobalKey _animatedContainerKey = GlobalKey();
  final GlobalKey _scrollKey = GlobalKey(); // the tile open for its details
  final PointOfInterestController _pointOfInterestController =
      PointOfInterestController();
  final TripHeaderController _tripHeaderController = TripHeaderController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  BottomDrawerItems _content = BottomDrawerItems.none;
  final Directions _directions = Directions();

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
  }

  void close({bool animate = true}) {
    if (mounted) {
      if (!animate) delay = 1;
      setState(() => width = 0);
      MapService().webAppBarController?.update(); // its caption
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

  /// Contents that are a single full screen (a Scaffold) rather than a list
  /// of tiles. They fill the drawer - in the scrolling list a Scaffold has
  /// no height to lay out in.
  static const Set<BottomDrawerItems> _formContents = {
    BottomDrawerItems.settings,
    BottomDrawerItems.register,
    BottomDrawerItems.myGroups,
    BottomDrawerItems.groups,
    BottomDrawerItems.invite,
    BottomDrawerItems.myEvents,
    BottomDrawerItems.events,
    BottomDrawerItems.docs,
    BottomDrawerItems.login,
    BottomDrawerItems.transfer,
    BottomDrawerItems.markdownHome,
    BottomDrawerItems.markdownShop,
    BottomDrawerItems.messages,
    BottomDrawerItems.deleteTrips,
    BottomDrawerItems.deleteUser,
  };
  bool _singleForm = false;

  int _openPointOfInterest = -1;
  bool _openHeader = false;

  Future<void> setContent({
    required BottomDrawerItems content,
    List? drawerItems,
    int openPointOfInterest = -1,
    bool openHeader = false,
  }) async {
    drawerItems ??= [];
    try {
      _content = content;
      _openPointOfInterest = openPointOfInterest;
      _openHeader = openHeader;
      _drawerItems = drawerItems;
      _offerRestore = false; // default state
      switch (content) {
        case BottomDrawerItems.home:
          try {
            _tiles = shredMarkdownItems('home');
            if (Setup().user.type >= 3) {
              _screenCache = _tiles;
            }
          } catch (e) {
            developer.log('error shredding homeItems: ${e.toString()}',
                name: 'error');
          }
          break;
        case BottomDrawerItems.trip:
          _tiles = shredCurrentTripItemData();
          _screenCache = _tiles;
          break;
        case BottomDrawerItems.group:
          _tiles = groupTiles(); // a group drive's participants
          _offerRestore = true;
          break;
        case BottomDrawerItems.tripMessages:
          _tiles = tripMessageTiles();
          _offerRestore = true;
          break;
        case BottomDrawerItems.maneuvers:
          _tiles = shredManeuvers();
          _offerRestore = true;
          break;
        case BottomDrawerItems.cached:
          _tiles = _screenCache;
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
        case BottomDrawerItems.markdownHome:
          try {
            _tiles = [
              MarkdownForm(markdownData: {}, dataType: 'home'),
            ];
          } catch (e) {
            developer.log('SideDrawer().setContent() error: ${e.toString()}',
                name: 'error');
          }
          _offerRestore = true;
          break;
        case BottomDrawerItems.shop:
          _tiles = shredMarkdownItems('shop');
          if (Setup().user.type >= 3) {
            _offerRestore = true;
            _screenCache = _tiles;
          }
          break;
        case BottomDrawerItems.markdownShop:
          try {
            _tiles = [
              MarkdownForm(markdownData: {}, dataType: 'shop'),
            ];
          } catch (e) {
            developer.log('SideDrawer().setContent() error: ${e.toString()}',
                name: 'error');
          }
          _offerRestore = true;
          break;
        case BottomDrawerItems.docs:
          _tiles = [DocumentationForm()];
          _offerRestore = true;
          break;
        case BottomDrawerItems.deleteTrips:
          _tiles = [const DeleteTripsForm()];
          break;
        case BottomDrawerItems.deleteUser:
          _tiles = [const DeleteUserForm()];
          break;
        case BottomDrawerItems.transfer:
          // Built by MyTripTile - synchronising a trip with the phone
          _tiles = List<Widget>.from(_drawerItems!);
          break;
        case BottomDrawerItems.login:
          // Closing puts the page's own content back, and the WebAppBar
          // shows the logged-in icon
          _tiles = [
            LoginScreen(onClose: () {
              MapService().webAppBarController?.update();
              MapService().baseShellController?.refillSideDrawer();
            })
          ];
          break;
        case BottomDrawerItems.messages:
          // Built by the Messages page - the conversations, or logged out
          // the invitation to log in (Messages.sideBarItems())
          _tiles = List<Widget>.from(_drawerItems!);
          break;
        default:
          _tiles = shredCurrentTripItemData();
          break;
      }
      // so does a page's image and message when it has nothing to show
      _singleForm = _formContents.contains(content) ||
          (_tiles.length == 1 &&
              (_tiles.first is PageEmptyView ||
                  _tiles.first is MyTripsEmptyView));
      refreshList = true;
      // Show the new content - without this it only appeared when something
      // else rebuilt the drawer, so e.g. Home's tiles stayed on other pages
      if (mounted) setState(() {});
      // The WebAppBar's caption describes what's in the drawer
      MapService().webAppBarController?.update();
    } catch (e) {
      developer.log('Error setting SideDrawer setContent(): ${e.toString()}',
          name: 'error');
    }
  }

  String _openTripUri = ''; // the published trip whose tile is open

  void showTrip(String uri) {
    if (_content != BottomDrawerItems.drives) return;
    int index = (_drawerItems ?? []).indexWhere((trip) => trip.uri == uri);
    if (index < 0) return;
    _openTripUri = uri;
    setState(() {
      _tiles = shredTrips();
      width = _mapWidth * 0.4;
      _visible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollTo(index: index));
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
            imageRepository: imageRepository,
          ),
        );
      }
    }
    return tiles;
  }

  /// My Trips: a summary of each saved trip, whose arrow shows the trip's
  /// details to the right (like Home and Shop) - or, with no trips, the
  /// image and message filling the drawer
  List<Widget> shredFavourites() {
    if ((_drawerItems ?? []).isEmpty) return [const MyTripsEmptyView()];
    int selected = MapService().myTripsController?.selected ?? -1;
    return [
      for (int i = 0; i < _drawerItems!.length; i++)
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
          child: MyTripTile(
            view: MyTripTileView.summary,
            index: i,
            myTripItem: _drawerItems![i],
            selected: i == selected,
            onSelect: () => MapService().myTripsController?.select(i),
            onDeleteTrip: (_) {},
            imageRepository: imageRepository,
          ),
        ),
    ];
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

  List<Widget> shredMarkdownItems(String type) {
    List<Widget> tiles = [];
    final controller;

    controller = type == 'home'
        ? MapService().homeController
        : MapService().shopController;

    // Nothing to show - the image and message fill the drawer
    if (_drawerItems!.isEmpty) {
      return [
        type == 'home'
            ? const PageEmptyView(
                image: 'assets/images/meeting.png',
                lines: [
                  'Welcome to Drives - there is always somewhere to go.',
                  'News about Drives, and articles about great trips, will appear here.',
                  'Use Explore to plan a trip, or see the trips other drivers have Published.',
                ],
              )
            : const PageEmptyView(
                image: 'assets/images/MobileMarketing.png',
                lines: [
                  'There are no offers in the shop just now.',
                  "The shop is where businesses, clubs and events for motorists offer things that'll make your trips even better.",
                  'Please check back soon.',
                ],
              ),
      ];
    }

    for (int i = 0; i < _drawerItems!.length; i++) {
      tiles.add(
        Padding(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
          child: Card(
            elevation: 5,
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 5, 5, 5),
              child: Row(children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _drawerItems![i].heading,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        _drawerItems![i].subheading,
                        style: TextStyle(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        _drawerItems![i].author,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      Text(
                        _drawerItems![i].added,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      SizedBox(),
                      IconButton(
                        onPressed: () => setState(
                          () => controller!.update(
                            {
                              'data': _drawerItems![i].markdown,
                              'style': _drawerItems![i].style,
                              'index': i,
                            },
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_circle_right_outlined,
                          size: 40,
                          color: controller!.index == i
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return tiles;
  }

  List<Widget> shredCurrentTripItemData() {
    if (_content != BottomDrawerItems.trip) return [];
    if (_openPointOfInterest >= 0 || _openHeader) {
      // Scroll to the tile that's open for its details
      int index = _openHeader ? 0 : tripPlanTileIndex(_openPointOfInterest);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => scrollTo(index: index));
    }
    return tripPlanTiles(
      openPointOfInterest: _openPointOfInterest,
      openHeader: _openHeader,
      openKey: _scrollKey,
      headerController: _tripHeaderController,
      pointOfInterestController: _pointOfInterestController,
      imageRepository: imageRepository,
      onHeaderUpdate: headingComplete,
      onPointOfInterestUpdate: pointOfInterestComplete,
      onDelete: pointOfInterestDelete,
    );
  }

  void pointOfInterestDelete(int index, int lIndex) {
    CurrentTripItem().removePointOfInterest(index);
    setState(() => _tiles.removeAt(lIndex));
    // Like the BottomDrawer - closes once only the trip's details are left
    if (_tiles.length < 2) close();
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
    newWidth = 0.4;
    _visible = true;
    bool changed = newWidth != width; //  false;
    try {
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
  }

  void setWidth({double width = 0}) {
    width = width;
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
    // Below the WebAppBar - the whole window height cut off the bottom of
    // the drawer, e.g. a form's buttons
    double mapHeight = MediaQuery.of(context).size.height -
        (Scaffold.maybeOf(context)?.appBarMaxHeight ?? 0);

    /// Ensure a fresh set of tiles is generated to ensure the initiallyExpanded value is
    /// set to reflect the completeness of the tile's content.
    /// The flag refreshList ensures that the list is only re-built when the data has changed
    /// otherwise as Flutter calls rebuild that haven't been initiated with a setState(), and that
    /// causes problems with the focus calling the keyboard. It is only set when the controller.refresh()
    /// or controller.setContent() are called.

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
                child: PointerInterceptor(
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
                          // a full-drawer image keeps the rounded corners
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            child: Container(
                              width: width,
                              height: mapHeight,
                              color: const Color.fromRGBO(54, 143, 244, 0.411),
                              child: _singleForm && _tiles.isNotEmpty
                                  ? _tiles.first
                                  : ScrollablePositionedList.builder(
                                      itemScrollController:
                                          _itemScrollController,
                                      itemCount: _tiles.length,
                                      itemBuilder: (navContext, index) =>
                                          _tiles[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_fixed) ...[
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: AbsorbPointer(
                    child: Container(
                      color: const Color.fromARGB(30, 71, 71, 71),
                      width: dividerWidth,
                      height: mapHeight,
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 0),
                        // Points the way the drawer will go - right to open,
                        // left to close. It follows the width, so it can't
                        // get out of step however the drawer was moved.
                        child: AnimatedRotation(
                          turns: width > 20 ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.arrow_circle_right_outlined,
                            size: dividerWidth,
                            color: Colors.blueAccent,
                          ),
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
                    setState(() => width = width > 10 ? 0 : _openWidth);
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
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
