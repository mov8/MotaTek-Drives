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
}

class PointOfInterestTile extends StatefulWidget {
  final int index;
  PointOfInterest pointOfInterest;
  final ImageRepository imageRepository;
  final PointOfInterestController? controller;
  final ExpandNotifier? expandNotifier;
  final Function? onExpandChange;
  final Function? onIconTap;
  final Function? onDelete;
  final Function? onRated;
  final Function? onSave;
  final bool expanded;
  final bool canEdit;

  PointOfInterestTile({
    super.key,
    required this.index,
    required this.pointOfInterest,
    required this.imageRepository,
    this.controller,
    this.expandNotifier,
    this.onIconTap,
    this.onExpandChange,
    this.onDelete,
    this.onRated,
    this.onSave,
    this.expanded = false,
    this.canEdit = true,
  });
  @override
  State<PointOfInterestTile> createState() => _PointOfInterestTileState();
}

class _PointOfInterestTileState extends State<PointOfInterestTile> {
  late int index;
  late String endpoint;
  bool expanded = true;
  bool canEdit = true;
  bool isExpanded = false;
  bool _memoPlaying = false;
  final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    if (widget.expandNotifier == null) {
      debugPrint('widget.expandNotifier is null');
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing of PointOfInterestTile #$index');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return canEdit ? editableTile() : unEditableTile();
  }

  Widget editableTile() {
    return SingleChildScrollView(
      child: Card(
        child: ExpansionTile(
          title: Text(
              CurrentTripItem().pointsOfInterest[widget.index].name.isEmpty
                  ? 'Point of interest to record'
                  : CurrentTripItem().pointsOfInterest[widget.index].name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          initiallyExpanded: expanded,
          leading: Icon(
              markerIcon(
                getIconIndex(
                    iconIndex:
                        CurrentTripItem().pointsOfInterest[widget.index].type),
              ),
              color: colourList[Setup().pointOfInterestColour]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  if (canEdit) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: DropdownButtonFormField<String>(
                            style: textStyle(
                                context: context, color: Colors.black),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Type',
                              labelStyle: labelStyle(context: context),
                            ),
                            initialValue: getIconIndex(
                                    iconIndex: CurrentTripItem()
                                        .pointsOfInterest[widget.index]
                                        .type)
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
                                          style: labelStyle(
                                              context: context,
                                              color: Colors.black,
                                              size: 3),
                                        )
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (item) {
                              CurrentTripItem().pointsOfInterest[widget.index] =
                                  PointOfInterest.clone(
                                pointOfInterest: CurrentTripItem()
                                    .pointsOfInterest[widget.index],
                                type: item == null ? -1 : int.parse(item),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ActionChip(
                                  label: Text(
                                    'Image',
                                    style: labelStyle(
                                        context: context,
                                        color: Colors.white,
                                        size: 3),
                                  ),
                                  avatar: const Icon(Icons.perm_media_outlined,
                                      size: 20, color: Colors.white),
                                  onPressed: () => loadImage(index),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 20,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: TextFormField(
                                readOnly: false,
                                initialValue: CurrentTripItem()
                                    .pointsOfInterest[widget.index]
                                    .name,
                                autofocus: canEdit,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      "What is the point of interest's name...",
                                  hintStyle: hintStyle(context: context),
                                  labelText: 'Point of interest name',
                                  labelStyle: labelStyle(
                                    context: context,
                                  ),
                                ),
                                style: textStyle(
                                    context: context,
                                    color: Colors.black,
                                    size: 3),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (value) => CurrentTripItem()
                                    .pointsOfInterest[widget.index]
                                    .name = value,
                                onFieldSubmitted: (text) => CurrentTripItem()
                                    .pointsOfInterest[widget.index]
                                    .name = text),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ActionChip(
                                  label: Text(
                                    'Memo',
                                    style: labelStyle(
                                        context: context,
                                        size: 3,
                                        color: CurrentTripItem()
                                                .pointsOfInterest[widget.index]
                                                .sounds
                                                .isNotEmpty
                                            ? Colors.white
                                            : Colors.grey),
                                  ),
                                  avatar: Icon(
                                      _memoPlaying
                                          ? Icons.volume_off_outlined
                                          : Icons.volume_up_outlined,
                                      size: 20,
                                      color: CurrentTripItem()
                                              .pointsOfInterest[widget.index]
                                              .sounds
                                              .isNotEmpty
                                          ? Colors.white
                                          : Colors.grey),
                                  onPressed: () {
                                    if (!_memoPlaying) {
                                      _play();
                                    }
                                    setState(
                                        () => _memoPlaying = !_memoPlaying);
                                  },
                                  backgroundColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: TextFormField(
                              readOnly: false,
                              maxLines: null,
                              textInputAction: TextInputAction.done,
                              initialValue: CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .description,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: canEdit
                                  ? InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Describe Point of Interest...',
                                      hintStyle: hintStyle(context: context),
                                      labelText:
                                          'Point of interest description',
                                      labelStyle: labelStyle(context: context),
                                    )
                                  : null,
                              style: textStyle(
                                  context: context,
                                  color: Colors.black,
                                  size: 3),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) => CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .description = text,
                              onFieldSubmitted: (text) => CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .description = text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (CurrentTripItem()
                        .pointsOfInterest[widget.index]
                        .photos
                        .isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: ImageArranger(
                              urlChange: (url) => setState(() =>
                                  CurrentTripItem()
                                      .pointsOfInterest[widget.index]
                                      .images = url),
                              photos: CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .photos,
                              showCaptions: true,
                            ),
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        children: [
                          ActionChip(
                            label: const Text(
                              'Delete',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            avatar: const Icon(Icons.delete,
                                size: 20, color: Colors.white),
                            onPressed: () => widget.onDelete,
                            backgroundColor: Colors.blueAccent,
                          ),
                          SizedBox(width: 10),
                          ActionChip(
                            label: const Text(
                              'Save',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            avatar: const Icon(Icons.save,
                                size: 20, color: Colors.white),
                            onPressed: () => widget.onSave!(widget.index),
                            backgroundColor: Colors.blueAccent,
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 250),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _play() async {
    if (await File(CurrentTripItem().pointsOfInterest[widget.index].sounds)
        .exists()) {
      DeviceFileSource source = DeviceFileSource(
          CurrentTripItem().pointsOfInterest[widget.index].sounds);
      player.play(source);
    }
  }

  String getTitle() {
    String title = '';
    if (CurrentTripItem().pointsOfInterest[widget.index].name.isEmpty) {
      if (CurrentTripItem().pointsOfInterest[widget.index].type == 13) {
        title = 'Details of good road to record';
      } else {
        title = 'Details of point of interest to record';
      }
    } else {
      title = CurrentTripItem().pointsOfInterest[widget.index].name;
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
            child: Text(CurrentTripItem().pointsOfInterest[widget.index].name,
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
                    rating:
                        CurrentTripItem().pointsOfInterest[widget.index].score),
              ),
            ],
          ),
          Row(children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                    'published ${DateFormat("dd MMM yyyy").format(CurrentTripItem().pointsOfInterest[widget.index].published)}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
      initiallyExpanded: expanded,
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
                              initialValue: CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .description,
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
                              onFieldSubmitted: (text) => CurrentTripItem()
                                  .pointsOfInterest[widget.index]
                                  .description = text),
                        ),
                      ),
                    ],
                  ),
                  if (CurrentTripItem()
                      .pointsOfInterest[widget.index]
                      .images
                      .isNotEmpty) // &&
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
                                photos: CurrentTripItem()
                                    .pointsOfInterest[widget.index]
                                    .photos,
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
        if (File("/data/user/0/com.motatek.drives/cache/scaled_1000003608.jpg")
            .existsSync()) {
          File("/data/user/0/com.motatek.drives/cache/scaled_1000003608.jpg")
              .deleteSync();
        }
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
                if (CurrentTripItem()
                        .pointsOfInterest[widget.index]
                        .images
                        .isNotEmpty &&
                    CurrentTripItem().pointsOfInterest[widget.index].images !=
                        "[]") {
                  /// count number of images
                  num = '{'
                          .allMatches(CurrentTripItem()
                              .pointsOfInterest[widget.index]
                              .images)
                          .length +
                      1;
                }
                debugPrint('Image count: $num');
                String imagePath =
                    '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
                File(pickedFile.path).copy(imagePath);
                File(pickedFile.path).delete();
                setState(() {
                  CurrentTripItem().pointsOfInterest[widget.index].images =
                      '[${CurrentTripItem().pointsOfInterest[widget.index].images.isNotEmpty ? '${CurrentTripItem().pointsOfInterest[widget.index].images.substring(1, CurrentTripItem().pointsOfInterest[widget.index].images.length - 1)},' : ''}{"url":"$imagePath","caption":"image $num"}]';
                  CurrentTripItem().pointsOfInterest[widget.index].photos.add(
                      Photo(
                          url: imagePath,
                          index: CurrentTripItem()
                              .pointsOfInterest[widget.index]
                              .photos
                              .length));
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
    if (widget.index == id) {
      expanded = false;
    }
  }

  expand(bool state, bool canEdit) {
    if (state) {
      //  _expansionTileController.expand();
    } else {
      //  _expansionTileController.collapse();
    }
    setState(() => expanded = state);
  }

  List<String> getImageUrls(PointOfInterest pointOfInterest) {
    var pics = jsonDecode(pointOfInterest.images);
    return [
      for (var pic in pics)
        Uri.parse('$urlDrive/images${pointOfInterest.url}${pic['url']}')
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
    if (CurrentTripItem().pointsOfInterest[widget.index].url.isNotEmpty) {
      putPointOfInterestRating(
          CurrentTripItem().pointsOfInterest[widget.index].url, value);
      if (widget.onRated != null) {
        widget.onRated!(value, widget.index);
      }
      setState(() => CurrentTripItem().pointsOfInterest[widget.index].score =
          value.toDouble());
    }
  }
}
