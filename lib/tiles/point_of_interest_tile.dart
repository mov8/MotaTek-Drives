import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
// import 'package:intl/intl.dart';
import '/constants.dart';
import 'package:image_picker/image_picker.dart';
import '/helpers/helpers.dart';
// import 'package:path_provider/path_provider.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller

//class ExpandNotifier extends ValueNotifier<int> {//
// ExpandNotifier(super.value);
//  void targetValue({int target = -1}) {/
//    value = target;
//  }
//}

class PointOfInterestController {
  _PointOfInterestTileState? _pointOfInterestTileState;
  void _addState(_PointOfInterestTileState pointOfInterestTileState) {
    _pointOfInterestTileState = pointOfInterestTileState;
  }

  bool get isAttached => _pointOfInterestTileState != null;

  void expand({bool state = true, bool canEdit = false}) {
    assert(isAttached, 'Controller must be attached to widget');
    developer.log('PointOfInterestController expand called', name: '_expand_');
    _pointOfInterestTileState?.expand(state, canEdit);
  }

  void collapse() {
    developer.log('PointOfInterestController collapse called',
        name: '_expand_');
    _pointOfInterestTileState?.collapse();
  }

  void expandChange({required bool expanded}) {
    developer.log(
        'PointOfInterestController expandChange called expanded: $expanded',
        name: '_expand_');
    assert(isAttached, 'Controller must be attached to widget');
    // _pointOfInterestTileState?.expandChange(expanded: expanded);
  }

  void dismissKeyboard() {
    _pointOfInterestTileState?.dismissKeyboard();
  }
}

class PointOfInterestTile extends StatefulWidget {
  final int index;
  int? listIndex;
  final PointOfInterest pointOfInterest;
  final ImageRepository imageRepository;
  PointOfInterestController? controller;
  final MapLibreMapController? mapController;
  // final ExpandNotifier? expandNotifier;
  Function? onExpandChange;
  final Function? onIconTap;
  final Function(int, int)? onDelete;
  final Function? onRated;
  final Function? onSave;
  String? driveId;
  final Function(bool)? onUpdate;
  bool expanded;
  final bool canEdit;
  final Color backgroundColor;

  PointOfInterestTile({
    super.key,
    required this.index,
    this.listIndex,
    String? driveId,
    required this.pointOfInterest,
    required this.imageRepository,
    this.controller,
    //  this.expandNotifier,
    this.onIconTap,
    Function? onExpandChange,
    this.onDelete,
    this.onRated,
    this.onSave,
    this.onUpdate,
    this.expanded = false,
    this.canEdit = true,
    this.backgroundColor = Colors.white,
    this.mapController,
  })  : onExpandChange = onExpandChange,
        driveId = driveId ??= CurrentTripItem().driveUri;

  factory PointOfInterestTile.clone(
      {Key? key, required PointOfInterestTile origin, bool expanded = false}) {
    return PointOfInterestTile(
      key: key ?? UniqueKey(),
      index: origin.index,
      driveId: origin.driveId,
      pointOfInterest: origin.pointOfInterest,
      imageRepository: origin.imageRepository,
      controller: origin.controller,
      // expandNotifier: origin.expandNotifier,
      onIconTap: origin.onIconTap,
      onExpandChange: origin.onExpandChange,
      onDelete: origin.onDelete,
      onRated: origin.onRated,
      onSave: origin.onSave,
      onUpdate: origin.onUpdate,
      expanded: expanded,
      canEdit: origin.canEdit,
    );
  }

  @override
  State<PointOfInterestTile> createState() => _PointOfInterestTileState();
}

class _PointOfInterestTileState extends State<PointOfInterestTile> {
  late int index;
  late String endpoint;
  bool canEdit = true;
  bool isExpanded = false;
  bool _memoPlaying = false;
  bool _isNew = true;
  late FocusNode fn1;
  late FocusNode fn2;
  final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  late ExpansibleController _expandController;
  final TextEditingController _textEditingControllerName =
      TextEditingController();
  final TextEditingController _textEditingControllerDescription =
      TextEditingController();
  Map<String, dynamic> prompts = {
    "save": ["Publish", "Save"],
    "title": ['Describe new great road', 'Details of new point of interest'],
    "name_hint": [
      "What is this road called?",
      "What is the point of interest's name?"
    ],
    "name_label": ["Road name", "Point of interest name"],
    "description_hint": ["Describe the road", "Describe point of interest"],
    "description_label": ["Road description", "Point of interest description"],
  };

  int promptIndex = 1;

  bool _menuExists = false;
  final GlobalKey _menuButtonKey = GlobalKey();
  IconData _typeIcon = Icons.ac_unit;
  String _typeName = '';
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    fn1 = FocusNode();
    fn2 = FocusNode();
    canEdit = widget.canEdit;
    fn1.requestFocus();
    index = widget.index;
    _expanded = false;
    _isNew = widget.pointOfInterest.name.isEmpty;
    _textEditingControllerName.text = widget.pointOfInterest.name;
    _textEditingControllerDescription.text = widget.pointOfInterest.description;
    _expandController = ExpansibleController();
    _typeIcon = getTypeIcon();
    _typeName = getTitle();
  }

  @override
  void dispose() {
    fn1.unfocus();
    fn2.unfocus();
    fn1.dispose();
    fn2.dispose();
    _expandController.dispose();
    _textEditingControllerName.dispose();
    _textEditingControllerDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('PointOfInterestTile().build() _expand: $_expanded',
        name: '_poi_');
    if (widget.pointOfInterest.name.isEmpty ||
        widget.pointOfInterest.description.isEmpty) {
      // if (CurrentTripItem().pointsOfInterest[widget.index].name.isEmpty ||
      //     CurrentTripItem().pointsOfInterest[widget.index].description.isEmpty) {
      _expandController.expand();
    } else if (_expanded == false) {
      // <-- only force a collapse if user taps tile
      _expandController.collapse();
    }

    if (widget.pointOfInterest.images.isNotEmpty &&
        widget.pointOfInterest.photos.isEmpty) {
      List<Photo> photos = photosFromJson(
          photoString: widget.pointOfInterest.images,
          endPoint: '$staticImagesFolder/${widget.driveId}/');
      widget.pointOfInterest.photos = photos;
    }
    fn1.requestFocus();
    return canEdit ? editableTile() : unEditableTile();
  }

  Widget editableTile() {
    promptIndex = widget.pointOfInterest.type == 13 ? 0 : 1;
    return RrExpansionTile(
      context: context,
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        initiallyExpanded: widget.expanded,
        controller: _expandController,

        title: Row(children: [
          if (kIsWeb) ...[
            Row(children: [
              Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(0, 0, 10, 0),
                  child: Icon(_typeIcon /*getTypeIcon() */,
                      size: 30, color: Colors.black)),
              Text(_typeName, style: TextStyle(fontSize: 20)),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: _menuButtonKey,
                  icon: Icon(Icons.arrow_drop_down_circle_outlined,
                      color: Colors.black),
                  onPressed: () => setState(() => _showCustomMenu(context)),
                ),
              ),
            ]),
          ],
          if (!kIsWeb) ...[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: InputBorder.none, //OutlineInputBorder(),
              ),
              initialValue: getIconIndex(iconIndex: widget.pointOfInterest.type)
                  .toString(),
              items: poiTypes
                  .map((item) => DropdownMenuItem<String>(
                        value: item['id'].toString(),
                        child: Row(children: [
                          Icon(
                            IconData(item['iconMaterial'],
                                fontFamily: 'MaterialIcons'),
                            color: Color(item['colourMaterial']),
                          ),
                          Text(
                            '    ${item['name']}',
                            style: titleStyle(
                                context: context, color: Colors.black, size: 2),
                          )
                        ]),
                      ))
                  .toList(),
              onChanged: (item) {},
            ),
          ],
          //  ],
          Expanded(
            flex: 2,
            child: SizedBox(width: 20),
          ),
        ]), //  Text('Test Name'),
        onExpansionChanged: (value) {
          _expanded = value; // <-- Important allows ExpansionController to work
          if (widget.pointOfInterest.complete() == 3) {}
        },
        children: [
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 10),
            child: TextFormField(
              readOnly: false,
              focusNode: fn1,
              controller: _textEditingControllerName,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [TitleCaseFormatter()],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: prompts["name_hint"][promptIndex],
                hintStyle: hintStyle(context: context),
                labelText: prompts["name_label"][promptIndex],
                labelStyle: labelStyle(
                  context: context,
                ),
              ),
              style: textStyle(context: context, color: Colors.black, size: 3),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) => widget.pointOfInterest.name = value,
              onFieldSubmitted: (text) {
                checkComplete();
                fn2.requestFocus();
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: TextFormField(
                    readOnly: false,
                    controller: _textEditingControllerDescription,
                    focusNode: fn2,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.start,
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [SentenceCaseFormatter()],
                    decoration: canEdit
                        ? InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: prompts["description_hint"][promptIndex],
                            hintStyle: hintStyle(context: context),
                            labelText: prompts["description_label"]
                                [promptIndex],
                            labelStyle: labelStyle(context: context),
                          )
                        : null,
                    style: textStyle(
                        context: context, color: Colors.black, size: 3),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (text) =>
                        widget.pointOfInterest.description = text,
                    onFieldSubmitted: (text) {
                      checkComplete();
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: imageChip(),
              ),
              Expanded(
                flex: 7,
                child: memoChip(),
              ),
              Expanded(
                flex: 7,
                child: deleteChip(),
              ),
              Expanded(
                flex: 6,
                child: saveChip(),
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          if (widget.pointOfInterest.photos.isNotEmpty) ...[
            //images.isNotEmpty) ...[
            Row(
              children: <Widget>[
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: ImageArranger(
                      urlChange: (url) => updateImages(url),
                      photos: widget.pointOfInterest.photos, //getPhotos(
                      // driveId: widget.driveId ?? CurrentTripItem().uri,
                      //   ),
                      showCaptions: true,
                      imageRepository: widget.imageRepository,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void updateImages(url) {
    developer.log('PointOfInterestTile().udateImages($url)', name: '_poi_');
    setState(() => widget.pointOfInterest.images = url);
  }

  void checkComplete({String text = '', bool close = true}) {
    developer.log(
        'PointOfInterestTile().checkComplete($close) text: $text widget.pointOfInterest.complete(): ${widget.pointOfInterest.complete()}',
        name: '_poi_');
    if (widget.pointOfInterest.complete() == 3) {
      setState(() => dismissKeyboard());

      // update the geoJson flag to show the details
      CurrentTripItem().mapUpdates =
          CurrentTripItem().mapUpdates.add(MapUpdates.pointsOfInterest);
      //  MapService().controller.upda
      if (widget.onUpdate != null) {
        widget.onUpdate!(true);
      }
    }
  }

  void dismissKeyboard() {
    if (mounted) {
      try {
        fn1.unfocus();
        fn2.unfocus();
        FocusScope.of(context).unfocus();
      } catch (e) {
        developer.log(
            'Error point_of_interest_tile.dart dismissKeyboard(): ${e.toString}',
            name: 'error');
      }
    }
  }

  Future<void> _play() async {
    if (await File(widget.pointOfInterest.sounds).exists()) {
      DeviceFileSource source = DeviceFileSource(widget.pointOfInterest.sounds);
      player.play(source);
    }
  }

  void collapse() {
    dismissKeyboard();
    developer.log('PointOfInterestTile().collapse() called', name: '_expand_');
    _expandController.collapse();
  }

  String getTitle() {
    developer.log('PointOfInterestTile().getTitle() called', name: '_poi_');
    int type = _typeName.isEmpty ? 15 : widget.pointOfInterest.type;
    setState(() => _typeName = poiTypes.toList()[type]['name']);
    return _typeName;
  }

  IconData getTypeIcon() {
    int type = _typeName.isEmpty ? 15 : widget.pointOfInterest.type;
    setState(() => _typeIcon = IconData(poiTypes.toList()[type]['iconMaterial'],
        fontFamily: 'MaterialIcons'));
    return _typeIcon;
  }

  Widget unEditableTile() {
    return RrExpansionTile(
      context: context, // round the corners
      child: ExpansionTile(
        backgroundColor: widget.backgroundColor,
        collapsedBackgroundColor: widget.backgroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(widget.pointOfInterest.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left),
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: StarRating(
                      onRatingChanged: changeRating,
                      rating: widget.pointOfInterest.score),
                ),
              ],
            ),
            Row(children: [
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('N/A',
                      //  'published ${DateFormat("dd MMM yyyy").format(widget.pointOfInterest.published)}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        ),
        initiallyExpanded: widget.pointOfInterest.name.isEmpty ||
            widget.pointOfInterest.description.isEmpty,
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Text(
                          'Description:',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: TextFormField(
                                readOnly: !canEdit,
                                maxLines: null,
                                textInputAction: TextInputAction.done,
                                controller: _textEditingControllerDescription,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                inputFormatters: [SentenceCaseFormatter()],
                                decoration: canEdit
                                    ? const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Describe Point of Interest...',
                                        labelText:
                                            'Point of interest description',
                                      )
                                    : null,
                                style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onFieldSubmitted: (text) =>
                                    widget.pointOfInterest.description = text),
                          ),
                        ),
                      ],
                    ),
                    if (widget.pointOfInterest.images.isNotEmpty) // &&
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: SizedBox(
                              height: 350,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: PhotoCarousel(
                                  imageRepository: widget.imageRepository,
                                  photos: widget.pointOfInterest.photos,
                                  //  .getPhotos(driveId: widget.driveId ?? ''),
                                  height: 300,
                                  width: 300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  loadImage(int id) async {
    if (widget.index == id) {
      int imageCount = widget.pointOfInterest.photos.length + 1;
      final ImagePicker picker = ImagePicker();
      final XFile? xImage = await picker.pickImage(source: ImageSource.gallery);
      if (xImage != null) {
        try {
          String name = '${getUuid()}.${xImage.name.split(".").last}';
          Uint8List bytes = await xImage.readAsBytes();
          var imageMap =
              await widget.imageRepository.loadImage(bytes: bytes, uri: name);
          // get the new key's value to access the image
          String key = imageMap.keys.first;
          Photo newPhoto = Photo(
              url: name, caption: 'image $imageCount', rotation: 0, key: key);

          setState(() => widget.pointOfInterest.addPhoto(photo: newPhoto));
        } catch (e) {
          debugPrint('Error saving temporary image: ${e.toString()}');
        }
      }
    }
  }

  void _showCustomMenu(BuildContext context) async {
    if (!_menuExists) {
      _menuExists = true;
      // 1. Find the position of the button on the screen
      final RenderBox button =
          _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
      final RenderBox overlay = NavigationService()
          .key
          .currentContext!
          .findRenderObject() as RenderBox;
      // Calculate the position for the menu to appear
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          //  button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(Offset(550, 0), ancestor: overlay),
          button.localToGlobal(
              button.size.bottomRight(Offset(500, 0)), // .zero),
              ancestor: overlay),
        ),
        Offset(0, 0) /*.zero */ & overlay.size,
      );
      // 2. Use showMenu with the ROOT navigator's context
      final String? selected = await showMenu<String>(
        constraints: BoxConstraints(minWidth: 250),
        context: NavigationService()
            .key
            .currentContext!, // BREAK OUT: Use the main navigator!
        position: position,
        items: getPopupMenuItems().toList(),
      );
    }
    _menuExists = false;
  }

  List<PopupMenuEntry<String>> getPopupMenuItems() {
    try {
      List<PopupMenuEntry<String>>
          menuItems = /*[
        PopupMenuItem(onTap: () {}, value: ' ', child: Text('Child'))
      ].toList(); */
          poiTypes
              .where(
                (map) => (![9, 11, 12, 16, 18, 19].contains(map['id'])),
              )
              .map<PopupMenuEntry<String>>(
                (e) => PopupMenuItem(
                  onTap: () => changeType(e['id']),
                  value: e['id'].toString(),
                  //   child: PointerInterceptor(
                  child: Row(
                    children: [
                      Icon(
                        // Icons.access_alarms
                        IconData(e['iconMaterial'],
                            fontFamily: 'MaterialIcons'),
                        color: Color(e['colourMaterial']),
                      ),
                      Text(
                        '    ${e['name'] ?? 'Er'} (${e['id']})',
                        style: titleStyle(
                            context: context, color: Colors.black, size: 2),
                      )
                    ],
                  ),
                  //    ),
                ),
              )
              .toList();
      return menuItems;
    } catch (e) {
      developer.log('Error getting Popup data error: ${e.toString()}',
          name: 'error');
    }
    return [];
  }

  void changeType(int type) {
    widget.pointOfInterest.type = type;
    getTypeIcon();
    setState(() => getTitle());
  }

/*
      try {
        ImagePicker picker = ImagePicker();
        await //ImagePicker()
            picker
                .pickImage(source: ImageSource.gallery, imageQuality: 10)
                .then(
          (pickedFile) async {
            try {
              if (pickedFile != null) {
                final directory = Setup().appDocumentDirectory;

                /// Don't know what type of image so have to get file extension from picker file
                int num = 1;
                List<Map<String, dynamic>> images = [];
                if (widget.pointOfInterest.images.isNotEmpty) {
                  images = jsonDecode(widget.pointOfInterest.images);
                  num = images.length + 1;
                }
                String imagePath =
                    '$directory/${widget.pointOfInterest.uuid}_$num.${pickedFile.path.split('.').last}';
                //$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
                images.add({
                  "url": imagePath,
                  "caption": "image ${images.length + 1}",
                  "rotation": 0,
                });

                /// Will have to sort this out for the web version
                /// where files can't be used.
                File(pickedFile.path).copy(imagePath);
                File(pickedFile.path).delete();
                setState(() {
                  widget.pointOfInterest.images = jsonEncode(images);
                  widget.pointOfInterest.photos.add(
                    Photo.fromJsonMap(images.last as Map<String, String>),
                  );
                  /*
                  widget.pointOfInterest.photos.add(Photo(
                      url: imagePath,
                      index: widget.pointOfInterest.photos.length,
                      caption: "image ${images.length + 1}",
                      rotation: 0));
                  */
                  // debugPrint('Images: $widget.pointOfInterest.images');
                });
              }
            } catch (e) {
              String err = e.toString();
              debugPrint('Error getting image: $err');
            }
          },
        );
      } catch (e) {
        String err = e.toString();
        debugPrint('Error loading image: $err');
      }
      */

  save(int id) {
    //   if (widget.index == id) {
//      expanded = false;
//    }
  }

  expandChange(index, expanded) async {
    developer.log(
        'PontOfInterestTile().expansionChange() index:$index, expanded:$expanded',
        name: '_expand_');
    if (expanded) {
      // _expandController.expand();
      if (MapService().controller != null) {
        try {
          List<Map<String, dynamic>> jsonPointsOfInterest =
              pointsOfInterestToGeoJson(
                  pointsOfInterest: [widget.pointOfInterest]);
          await MapService()
              .controller!
              .setGeoJsonSource("point-of-interest-data", {
            "type": "FeatureCollection",
            "features": jsonPointsOfInterest,
          });
          MapService().controller!.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(
                    widget.pointOfInterest.point.y.toDouble(),
                    widget.pointOfInterest.point.x.toDouble(),
                  ),
                ),
                duration: Duration(seconds: 1),
              );
        } catch (e) {
          developer.log(
              'Error PointOfInterestTile().expandChange() showing routes: ${e.toString()}',
              name: 'error');
        }
      }
    }
  }

  expand(bool state, bool canEdit) {
    if (state) {
      _expandController.expand();
    } else {
      _expandController.collapse();
    }
  }

  ActionChip imageChip() {
    return ActionChip(
      label: Text(
        'Image',
        style: labelStyle(context: context, color: Colors.white, size: 3),
      ),
      avatar:
          const Icon(Icons.perm_media_outlined, size: 20, color: Colors.white),
      onPressed: () => loadImage(index),
      backgroundColor: Colors.blueAccent,
    );
  }

  ActionChip memoChip() {
    return ActionChip(
      label: Text(
        'Memo',
        style: labelStyle(
            context: context,
            size: 3,
            color: widget.pointOfInterest.sounds.isNotEmpty
                ? Colors.white
                : Colors.grey),
      ),
      avatar: Icon(
          _memoPlaying ? Icons.volume_off_outlined : Icons.volume_up_outlined,
          size: 20,
          color: widget.pointOfInterest.sounds.isNotEmpty
              ? Colors.white
              : Colors.grey),
      onPressed: () {
        if (!_memoPlaying) {
          _play();
        }
        setState(() => _memoPlaying = !_memoPlaying);
      },
      backgroundColor: Colors.blueAccent,
    );
  }

  ActionChip deleteChip() {
    return ActionChip(
      label: Text(
        _isNew ? 'Cancel' : 'Delete',
        style: labelStyle(context: context, color: Colors.white, size: 3),
      ),
      avatar: const Icon(Icons.delete, size: 20, color: Colors.white),
      onPressed: () {
        if (widget.onDelete != null) {
          developer.log('PointOfInterestTile().onDelete() called',
              name: '_poi_');
          widget.onDelete!(widget.index, widget.listIndex ?? -1);
        }
      },
      backgroundColor: Colors.blueAccent,
    );
  }

  ActionChip saveChip() {
    return ActionChip(
      label: Text(
        prompts['save'][promptIndex],
        style: labelStyle(context: context, color: Colors.white, size: 3),
      ),
      avatar: Icon(promptIndex == 0 ? Icons.publish : Icons.save,
          size: 20, color: Colors.white),
      onPressed: () =>
          CurrentTripItem().refreshMap(change: MapUpdates.pointsOfInterest),
      //  widget.onSave != null ? widget.onSave!(widget.index) : null,
      backgroundColor: Colors.blueAccent,
    );
  }

  List<String> getImageUrls(PointOfInterest pointOfInterest) {
    var pics = jsonDecode(pointOfInterest.images);
    return [
      for (var pic in pics)
        Uri.parse('$urlDrive/images${pointOfInterest.uuid}${pic['url']}')
            .toString()
    ];
  }

  int getIconIndex({required int iconIndex, int fallback = 0}) {
    if (iconIndex == -1) {
      iconIndex = fallback;
    }
    return iconIndex;
  }

  Widget showLocalImage(String url) {
    return SizedBox(width: 160, child: Image.file(File(url)));
  }

  changeRating(value) {
    if (widget.pointOfInterest.uuid.isNotEmpty) {
      putPointOfInterestRating(widget.pointOfInterest.uuid, value);
      if (widget.onRated != null) {
        widget.onRated!(value, widget.index);
      }
      setState(() => widget.pointOfInterest.score = value.toDouble());
    }
  }
}
