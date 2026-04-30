import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/constants.dart';
import 'package:image_picker/image_picker.dart';
import '/helpers/edit_helpers.dart';
// import 'package:path_provider/path_provider.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;

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

  void expand(bool state, bool canEdit) {
    assert(isAttached, 'Controller must be attached to widget');
    _pointOfInterestTileState?.expand(state, canEdit);
  }

  void expandChange({required bool expanded}) {
    assert(isAttached, 'Controller must be attached to widget');
    // _pointOfInterestTileState?.expandChange(expanded: expanded);
  }

  void dismissKeyboard() {
    _pointOfInterestTileState?.dismissKeyboard();
  }

  void collapse() {
    _pointOfInterestTileState?.collapse();
  }
}

class PointOfInterestTile extends StatefulWidget {
  final int index;
  final PointOfInterest pointOfInterest;
  final ImageRepository imageRepository;
  final PointOfInterestController? controller;
  final ExpandNotifier? expandNotifier;
  Function? onExpandChange;
  final Function? onIconTap;
  final Function? onDelete;
  final Function? onRated;
  final Function? onSave;
  final Function(bool)? onUpdate;
  bool expanded;
  final bool canEdit;

  PointOfInterestTile({
    super.key,
    required this.index,
    required this.pointOfInterest,
    required this.imageRepository,
    this.controller,
    this.expandNotifier,
    this.onIconTap,
    Function? onExpandChange,
    this.onDelete,
    this.onRated,
    this.onSave,
    this.onUpdate,
    this.expanded = false,
    this.canEdit = true,
  }) : onExpandChange = onExpandChange;

  factory PointOfInterestTile.clone(
      {Key? key, required PointOfInterestTile origin, bool expanded = false}) {
    return PointOfInterestTile(
      key: key ?? UniqueKey(),
      index: origin.index,
      pointOfInterest: origin.pointOfInterest,
      imageRepository: origin.imageRepository,
      controller: origin.controller,
      expandNotifier: origin.expandNotifier,
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

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    fn1 = FocusNode();
    fn2 = FocusNode();
    canEdit = widget.canEdit;
    fn1.requestFocus();
    index = widget.index;
    _isNew = widget.pointOfInterest.name.isEmpty;
    _expandController = ExpansibleController();
    if (widget.expandNotifier == null) {
      debugPrint('widget.expandNotifier is null');
    }
  }

  @override
  void dispose() {
    fn1.unfocus();
    fn2.unfocus();
    fn1.dispose();
    fn2.dispose();
    //  _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fn1.requestFocus();
    return canEdit ? editableTile() : unEditableTile();
  }

  Widget editableTile() {
    promptIndex = widget.pointOfInterest.type == 13 ? 0 : 1;
    return SingleChildScrollView(
      //  child: Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0), // round the corners
        child: ExpansionTile(
          key: UniqueKey(), // PageStorageKey(widget.index),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          //  controller: _expandController,
          shape: const Border(), // gets rid of line at top and bottom of tile
          title: Row(children: [
            Expanded(
              flex: 10,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: InputBorder.none, //OutlineInputBorder(),
                ),
                initialValue:
                    getIconIndex(iconIndex: widget.pointOfInterest.type)
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
                                  context: context,
                                  color: Colors.black,
                                  size: 2),
                            )
                          ]),
                        ))
                    .toList(),
                onChanged: (item) {},
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(width: 20),
            ),
          ]),
          initiallyExpanded: widget.expanded,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                readOnly: false,
                initialValue: widget.pointOfInterest.name,
                //  autofocus: canEdit,
                focusNode: fn1,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: prompts["name_hint"][promptIndex],
                  hintStyle: hintStyle(context: context),
                  labelText: prompts["name_label"][promptIndex],
                  labelStyle: labelStyle(
                    context: context,
                  ),
                ),
                style:
                    textStyle(context: context, color: Colors.black, size: 3),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) => widget.pointOfInterest.name = value,
                onFieldSubmitted: (text) {
                  widget.pointOfInterest.name = text;
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
                      focusNode: fn2,
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      initialValue: widget.pointOfInterest.description,
                      textAlign: TextAlign.start,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: canEdit
                          ? InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: prompts["description_hint"]
                                  [promptIndex],
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
                        widget.pointOfInterest.description = text;
                        checkComplete();
                        // if (widget.onUpdate != null) {
                        //   widget.onUpdate!(true);
                        // }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(children: [
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
            ]),
            if (widget.pointOfInterest.photos.isNotEmpty)
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: ImageArranger(
                      urlChange: (url) =>
                          setState(() => widget.pointOfInterest.images = url),
                      photos: widget.pointOfInterest.photos,
                      showCaptions: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void checkComplete({bool close = true}) {
    if (widget.pointOfInterest.complete() == 3) {
      setState(() => dismissKeyboard());
      if (widget.onUpdate != null) {
        // update the geoJson flag to show the details
        developer.log('PointOfInterestTile.checkComplete()',
            name: '_mapUpdates_');
        CurrentTripItem().mapUpdates =
            CurrentTripItem().mapUpdates.add(MapUpdates.pointsOfInterest);

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
            name: '_keyboard_');
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
    _expandController.collapse();
  }

  String getTitle() {
    String title = '';
    if (widget.pointOfInterest.name.isEmpty) {
      if (widget.pointOfInterest.type == 13) {
        title = 'Details of good road to record';
      } else {
        title = 'Details of point of interest to record';
      }
    } else {
      title = widget.pointOfInterest.name;
    }
    return title;
  }

  Widget unEditableTile() {
    return ExpansionTile(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
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
                child: Text(
                    'published ${DateFormat("dd MMM yyyy").format(widget.pointOfInterest.published)}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
      initiallyExpanded: widget.expanded,
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
                              initialValue: widget.pointOfInterest.description,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: canEdit
                                  ? const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Describe Point of Interest...',
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
    );
  }

  loadImage(int id) async {
    if (widget.index == id) {
      try {
        /*
        if (File("/data/user/0/com.motatek.drives/cache/scaled_1000003608.jpg")
            .existsSync()) {
          File("/data/user/0/com.motatek.drives/cache/scaled_1000003608.jpg")
              .deleteSync();
        }
        */
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
                }

                String imagePath =
                    '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
                images.add({
                  "url": imagePath,
                  "caption": "image ${images.length + 1}"
                });

                /// Will have to sort this out for the web version
                /// where files can't be used.
                File(pickedFile.path).copy(imagePath);
                File(pickedFile.path).delete();
                setState(() {
                  widget.pointOfInterest.images = jsonEncode(images);

                  widget.pointOfInterest.photos.add(Photo(
                      url: imagePath,
                      index: widget.pointOfInterest.photos.length,
                      caption: "image ${images.length + 1}",
                      rotation: 0));
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
    }
  }

  save(int id) {
    //   if (widget.index == id) {
//      expanded = false;
//    }
  }

  expand(bool state, bool canEdit) {
    if (state) {
      //  _expansionTileController.expand();
    } else {
      //  _expansionTileController.collapse();
    }
//    setState(() => expanded = state);
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
      onPressed: () => widget.onDelete,
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
