import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drives/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final PointOfInterest pointOfInterest;
  final ImageRepository imageRepository;
  final PointOfInterestController? controller;
  final ExpandNotifier? expandNotifier;
  final Function? onExpandChange;
  final Function? onIconTap;
  final Function? onDelete;
  final Function? onRated;
  final bool expanded;
  final bool canEdit;

  const PointOfInterestTile({
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
      child: ExpansionTile(
        title: Text(widget.pointOfInterest.getName(),
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
              getIconIndex(iconIndex: widget.pointOfInterest.getType()),
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
                      //    if (canEdit) ...[
                      Expanded(
                        flex: 10,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Type',
                          ),
                          value: getIconIndex(
                                  iconIndex: widget.pointOfInterest.getType())
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
                                      Text('    ${item['name']}')
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (item) {
                            int type = item == null ? -1 : int.parse(item);
                            widget.pointOfInterest.setType(type);
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
                                label: const Text(
                                  'Image',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
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
                              initialValue: widget.pointOfInterest.getName(),
                              autofocus: canEdit,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText:
                                    "What is the point of interest's name...",
                                labelText: 'Point of interest name',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onFieldSubmitted: (text) =>
                                  widget.pointOfInterest.setName(text)),
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
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: widget
                                              .pointOfInterest.sounds.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey),
                                ),
                                avatar: Icon(
                                    _memoPlaying
                                        ? Icons.volume_off_outlined
                                        : Icons.volume_up_outlined,
                                    size: 20,
                                    color:
                                        widget.pointOfInterest.sounds.isNotEmpty
                                            ? Colors.white
                                            : Colors.grey),
                                onPressed: () {
                                  if (!_memoPlaying) {
                                    _play();
                                  }
                                  setState(() => _memoPlaying = !_memoPlaying);
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
                              //     expands: true,
                              initialValue:
                                  widget.pointOfInterest.getDescription(),
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
                              onFieldSubmitted: (text) => widget.pointOfInterest
                                  .setDescription(text) //body = text
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pointOfInterest.photos.isNotEmpty)
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 8,
                          child: ImageArranger(
                            urlChange: (url) => setState(
                                () => widget.pointOfInterest.setImages(url)),
                            photos: widget.pointOfInterest.photos,
                            endPoint: widget.pointOfInterest.url,
                            showCaptions: true,
                          ),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: ActionChip(
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      avatar: const Icon(Icons.delete,
                          size: 20, color: Colors.white),
                      onPressed: () => widget.onDelete,
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 250),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _play() async {
    if (await File(widget.pointOfInterest.sounds).exists()) {
      DeviceFileSource source = DeviceFileSource(widget.pointOfInterest.sounds);
      player.play(source);
    }
  }

  Widget unEditableTile() {
    return ExpansionTile(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      //   controller: _expansionTileController,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(widget.pointOfInterest.getName(),
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
                    rating: widget.pointOfInterest.getScore()),
              ),
            ],
          ),
          Row(children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomLeft,
                //DateFormat("dd MMM yy HH:mm").format(DateTime.now()),
                child: Text(
                    'published ${DateFormat("dd MMM yyyy").format(widget.pointOfInterest.published)}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
      //  collapsedBackgroundColor: Colors.transparent,
      //  backgroundColor: Colors.transparent,
      initiallyExpanded: expanded,
      // onExpansionChanged: expandChange(expanded: expanded),
      /*
      leading: Icon(
          markerIcon(
            getIconIndex(iconIndex: widget.pointOfInterest.getType()),
          ),
          color: colourList[Setup().pointOfInterestColour]),
      */
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
                              //     expands: true,
                              initialValue:
                                  widget.pointOfInterest.getDescription(),
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
                              onFieldSubmitted: (text) => widget.pointOfInterest
                                  .setDescription(text) //body = text
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pointOfInterest.getImages().isNotEmpty) // &&
                    // widget.pointOfInterest.url.isEmpty)
                    Row(children: <Widget>[
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
                            //     ),
                          ),
                        ),
                      ),
                    ]),
                  /*S
                  if (widget.pointOfInterest.url.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                            child: Row(
                              children: [
                                StarRating(
                                    onRatingChanged: changeRating,
                                    rating: widget.pointOfInterest.getScore()),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '(${widget.pointOfInterest.scored})',
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 15),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () =>
                                widget.onIconTap, // () => (setState(() {}),),
                          ),
                        )
                      ],
                    ),
                  ],
                  */
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
                if (widget.pointOfInterest.getImages().isNotEmpty) {
                  /// count number of images
                  num = '{'
                          .allMatches(widget.pointOfInterest.getImages())
                          .length +
                      1;
                }
                debugPrint('Image count: $num');
                String imagePath =
                    '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
                File(pickedFile.path).copy(imagePath);
                setState(() {
                  widget.pointOfInterest.setImages(
                      '[${widget.pointOfInterest.getImages().isNotEmpty ? '${widget.pointOfInterest.getImages().substring(1, widget.pointOfInterest.getImages().length - 1)},' : ''}{"url":"$imagePath","caption":"image $num"}]');
                  widget.pointOfInterest.photos.add(Photo(
                      url: imagePath,
                      index: widget.pointOfInterest.photos.length));
                  debugPrint('Images: $widget.pointOfInterest.images');
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
    var pics = jsonDecode(pointOfInterest.getImages());
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
    if (widget.pointOfInterest.url.isNotEmpty) {
      putPointOfInterestRating(widget.pointOfInterest.url, value);
      if (widget.onRated != null) {
        widget.onRated!(value, widget.index);
      }
      setState(() => widget.pointOfInterest.setScore(value.toDouble()));
    }
  }
}
