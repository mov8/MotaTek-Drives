import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import 'package:universal_io/universal_io.dart';
import 'package:intl/intl.dart';
import '/helpers/helpers.dart';
import '/constants.dart';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller

class HomeItemTileController {
  _HomeItemTileState? _homeItemTileState;

  void _addState(_HomeItemTileState homeItemTileState) {
    _homeItemTileState = homeItemTileState;
  }

  bool get isAttached => _homeItemTileState != null;
  void contract() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _homeItemTileState?.changeOpenState();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void updatePhotos() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _homeItemTileState?.getPhotos();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error getting photos: $err');
    }
  }
}

class HomeItemTile extends StatefulWidget {
//  final PointOfInterestController? pointOfInterestController;
  final HomeItem homeItem;
  final HomeItemTileController controller;
  final int index;
  final Function(int)? onIconTap;
  final Function(bool, HomeItemTileController)? onExpandChange;
  final Function(int)? onDelete;
  final Function(int)? onAddImage;
  final Function(int, int)? onRated;
  final Function(int)? onChange;
  final Function(int)? onSelect; // final Key key;
  final bool expanded;
  final bool canEdit;

  HomeItemTile(
      {super.key,
      required this.index,
      required this.homeItem,
      required this.controller,
      this.onIconTap,
      this.onExpandChange,
      this.onDelete,
      this.onAddImage,
      this.onChange,
      this.onRated,
      this.expanded = false,
      this.canEdit = true,
      this.onSelect});
  @override
  State<HomeItemTile> createState() => _HomeItemTileState();
}

class _HomeItemTileState extends State<HomeItemTile> {
  late int index;
  int imageUrlLength = 0;
  int imageIndex = 0;
  bool expanded = true;
  bool canEdit = true;
  DateFormat dateFormat = DateFormat("dd MMM yy");
  List<Photo> photos = [];
  final List<String> covers = [
    'all',
    'North',
    'North West',
    'North East',
    'West',
    'East',
    'South',
    'South West',
    'South East'
  ];

  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  ExpansibleController _expansibleController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    photos = photosFromJson(
        photoString: widget.homeItem.imageUrls,
        endPoint: '$urlHomePageItem/images/${widget.homeItem.uri}/');
    dropDownMenuItems = covers
        .map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        )
        .toList();
  }

  changeOpenState() {
    if (widget.expanded) {
      debugPrint('Controller closing tile $index');
      _expansibleController.collapse();
    } else {
      debugPrint('tile $index is already closed - widget.expanded = false');
    }
  }

  getPhotos() {
    try {
      photos = photosFromJson(
          photoString: widget.homeItem.imageUrls,
          endPoint: '$urlHomePageItem/images/${widget.homeItem.uri}/');
      imageUrlLength = widget.homeItem.imageUrls.length;
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeItem.imageUrls.length != imageUrlLength) {
      getPhotos();
    }
    return Card(
      key: Key('$widget.key'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          controller: _expansibleController,
          title: widget.homeItem.heading == ''
              ? Text(
                  'Add a home page item',
                  style: headlineStyle(
                      context: context, size: 2, color: Colors.black),
                )
              : Text(
                  widget.homeItem.heading,
                  style: headlineStyle(
                      context: context, size: 2, color: Colors.black),
                ),
          subtitle: Row(children: [
            Expanded(
                flex: 1,
                child: Text(
                  'pub ${dateFormat.format(DateTime.now())}',
                  style:
                      textStyle(context: context, size: 3, color: Colors.black),
                )),
            const Expanded(flex: 1, child: Text('rank 0'))
          ]),
          initiallyExpanded: expanded,
          onExpansionChanged: (expanded) =>
              widget.onExpandChange!(expanded, widget.controller),
          leading: IconButton(
            iconSize: 25,
            icon: const Icon(Icons.newspaper_outlined),
            onPressed: () => (),
          ),
          children: [
            SizedBox(
              height: 950,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 0, 30),
                child: Column(
                  children: <Widget>[
                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Coverage',
                            labelStyle: labelStyle(
                                context: context, size: 2, color: Colors.black),
                            hintStyle: hintStyle(
                                context: context, color: Colors.blueGrey),
                          ),
                          initialValue: widget.homeItem.coverage,
                          items: dropDownMenuItems,
                          style: textStyle(
                              context: context, color: Colors.black, size: 2),
                          onChanged: (item) {
                            widget.homeItem.coverage = item ?? 'all';
                            widget.onChange!(index);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                          child: TextFormField(
                              //   readOnly: !canEdit,
                              initialValue: widget.homeItem.score.toString(),
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: const TextInputType
                                  .numberWithOptions(), //for(i = -1; i < 100; i++) i.toString()],
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "-1 invisible higher the better",
                                labelText: 'Article ranking',
                                labelStyle: labelStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                              ),
                              style: textStyle(
                                  context: context,
                                  size: 2,
                                  color: Colors.black),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) {
                                widget.onChange!(index);
                                widget.homeItem.heading = text;
                              }),
                        ),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                          child: TextFormField(
                              //   readOnly: !canEdit,
                              initialValue: widget.homeItem.heading,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "What is the home item's heading...",
                                labelText: 'Home item heading',
                                labelStyle: labelStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                              ),
                              style: textStyle(
                                  context: context,
                                  size: 2,
                                  color: Colors.black),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) {
                                widget.homeItem.heading = text;
                                widget.onChange!(index);
                              }),
                        ),
                      ),
                    ]),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: TextFormField(
                                readOnly: !canEdit,
                                initialValue: widget.homeItem.subHeading,
                                autofocus: canEdit,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      "What is the home item's sub-heading...",
                                  labelText: 'Home item sub-heading',
                                  labelStyle: labelStyle(
                                      context: context,
                                      size: 2,
                                      color: Colors.black),
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.homeItem.subHeading = text;
                                  widget.onChange!(index);
                                }),
                          ),
                        )
                      ],
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
                                initialValue: widget.homeItem.body,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Article content...',
                                  labelText: 'Home page article',
                                  labelStyle: labelStyle(
                                      context: context,
                                      size: 2,
                                      color: Colors.black),
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.homeItem.body = text;
                                  widget.onChange!(index);
                                }
                                //body = text
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.homeItem.imageUrls.isNotEmpty)
                      Column(
                        children: [
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 8,
                                child: ImageArranger(
                                  onChange: (idx) =>
                                      setState(() => imageIndex = idx),
                                  urlChange: (imageUrls) =>
                                      widget.homeItem.imageUrls = imageUrls,
                                  photos: photos,
                                  endPoint: '', // widget.homeItem.uri,
                                  showCaptions: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  save(int id) {
    if (widget.index == id) {
      expanded = false;
    }
  }

  onDeleteImage(int idx) {
    debugPrint('delete image $idx');
    setState(() => photos.removeAt(idx));
  }

  expand(bool state, bool canEdit) {
    expanded = state;
  }

/*
  List<String> getImageUrls(PointOfInterest pointOfInterest) {
    var pics = jsonDecode(pointOfInterest.getImages());
    return [
      for (String pic in pics)
        Uri.parse('${urlBase}v1/drive/images${pointOfInterest.url}$pic')
            .toString()
    ];
  }
*/
/*
  Widget showLocalImage(String url) {
    return SizedBox(width: 160, child: Image.file(File(url)));
  }
*/
  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
        key: Key('sli$index'), width: 160, child: Image.file(File(url)));
  }

  changeRating(value) {
    widget.onRated!(value, widget.index);
    setState(() => widget.homeItem.score = value.toDouble());
  }
}
