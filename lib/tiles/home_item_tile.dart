import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'dart:io';
import 'package:intl/intl.dart';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller

class HomeItemTile extends StatefulWidget {
//  final PointOfInterestController? pointOfInterestController;
  final HomeItem homeItem;
  final int index;
  final Function(int)? onIconTap;
  final Function(int)? onExpandChange;
  final Function(int)? onDelete;
  final Function(int)? onAddImage;
  final Function(int, int)? onRated;
  final Function(int)? onSelect; // final Key key;
  final bool expanded;
  final bool canEdit;

  const HomeItemTile(
      {super.key,
      required this.index,
      required this.homeItem,
      this.onIconTap,
      this.onExpandChange,
      this.onDelete,
      this.onAddImage,
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

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    photos = photosFromJson(widget.homeItem.imageUrls,
        endPoint: '${widget.homeItem.uri}/');
    dropDownMenuItems = covers
        .map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeItem.imageUrls.length != imageUrlLength) {
      photos = photosFromJson(widget.homeItem.imageUrls,
          endPoint: '${widget.homeItem.uri}/');
      imageUrlLength = widget.homeItem.imageUrls.length;
    }
    return Card(
      key: Key('$widget.key'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          //   controller: ExpansionTileController(),
          title: widget.homeItem.heading == ''
              ? const Text(
                  'Add a home page item',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  widget.homeItem.heading,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
          subtitle: Row(children: [
            Expanded(
                flex: 1,
                child: Text('pub ${dateFormat.format(DateTime.now())}')),
            const Expanded(flex: 1, child: Text('rank 0'))
          ]),
          initiallyExpanded: expanded,
          onExpansionChanged: (expanded) {
            setState(() {
              widget.onExpandChange!(expanded ? index : -1);
            });
          },
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Coverage',
                          ),
                          value: widget.homeItem.coverage,
                          items: dropDownMenuItems,
                          onChanged: (item) {
                            widget.homeItem.coverage = item ?? 'all';
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
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "-1 invisible higher the better",
                                labelText: 'Article ranking',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) =>
                                  widget.homeItem.heading = text),
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
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "What is the home item's heading...",
                                labelText: 'Home item heading',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) =>
                                  widget.homeItem.heading = text),
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
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      "What is the home item's sub-heading...",
                                  labelText: 'Home item sub-heading',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) =>
                                    widget.homeItem.subHeading = text),
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
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Article content...',
                                  labelText: 'Home page article',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) => widget.homeItem.body = text
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
                    Wrap(
                      spacing: 5,
                      children: [
                        if (widget.onDelete != null)
                          ActionChip(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () =>
                                widget.onDelete!(widget.index), //_action = 2),
                            backgroundColor: Colors.blue,
                            avatar: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Delete", // - ${_action.toString()}',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        if (widget.onAddImage != null)
                          ActionChip(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => widget
                                .onAddImage!(widget.index), //_action = 2),
                            backgroundColor: Colors.blue,
                            avatar: const Icon(
                              Icons.image,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Add image", // - ${_action.toString()}',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        if (widget.onSelect != null)
                          ActionChip(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () =>
                                widget.onSelect!(widget.index), //_action = 2),
                            backgroundColor: Colors.blue,
                            avatar: const Icon(
                              Icons.cloud_upload,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Publish", // - ${_action.toString()}',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    )
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
