import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller

class ShopItemTile extends StatefulWidget {
//  final PointOfInterestController? pointOfInterestController;
//  final BuildContext context;
  final ShopItem shopItem;
  final int index;
  final Function(int)? onIconTap;
  final Function(int)? onExpandChange;
  final Function(int)? onDelete;
  final Function(int, int)? onRated;
  final Function(int)? onSelect; // final Key key;
  final bool expanded;
  final bool canEdit;

  const ShopItemTile(
      {super.key,
      // required this.context,
      required this.index,
      required this.shopItem,
      this.onIconTap,
      this.onExpandChange,
      this.onDelete,
      this.onRated,
      this.expanded = false,
      this.canEdit = true,
      this.onSelect});
  @override
  State<ShopItemTile> createState() => _ShopItemTileState();
}

class _ShopItemTileState extends State<ShopItemTile> {
  late int index;
  int imageUrlLength = 0;
  int _links = 0;
  bool expanded = true;
  bool canEdit = true;
  DateFormat dateFormat = DateFormat("dd MMM yy");
  List<Photo> photos = [];
  List<String> covers = [
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
    dropDownMenuItems = covers
        .map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shopItem.imageUrl.length != imageUrlLength) {
      photos = photosFromJson(widget.shopItem.imageUrl);
      imageUrlLength = widget.shopItem.imageUrl.length;
    }
    _links = widget.shopItem.url1.isNotEmpty ? 1 : 0;
    _links = widget.shopItem.url2.isNotEmpty ? 2 : _links;
    return Card(
      key: Key('$widget.key'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          controller: ExpansionTileController(),
          title: widget.shopItem.heading == ''
              ? const Text(
                  'Add a home page item',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  widget.shopItem.heading,
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
            onPressed: widget.onIconTap!(widget.index),
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
                          value: widget.shopItem.coverage,
                          items: dropDownMenuItems,
                          onChanged: (item) {
                            widget.shopItem.coverage = item ?? 'all';
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
                              initialValue: widget.shopItem.score.toString(),
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: const TextInputType
                                  .numberWithOptions(), //for(i = -1; i < 100; i++) i.toString()],
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "-1 invisible higher the better",
                                labelText: 'Ad ranking',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) =>
                                  widget.shopItem.heading = text),
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
                              initialValue: widget.shopItem.heading,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "What is the shop item's heading...",
                                labelText: 'Shop item heading',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) =>
                                  widget.shopItem.heading = text),
                        ),
                      ),
                      /*   Expanded(
                        flex: 8,
                        child: SizedBox(
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ActionChip(
                                  label: const Text(
                                    'Image',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                  avatar: const Icon(Icons.photo_album,
                                      size: 20, color: Colors.white),
                                  onPressed: () => loadImage(index),
                                  backgroundColor: Colors.blueAccent,
                                ))),
                      ), */
                    ]),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: TextFormField(
                                readOnly: !canEdit,
                                initialValue: widget.shopItem.subHeading,
                                autofocus: canEdit,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      "What is the shop item's sub-heading...",
                                  labelText: 'Shop item sub-heading',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) =>
                                    widget.shopItem.subHeading = text),
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
                                initialValue: widget.shopItem.body,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Ad content...',
                                  labelText: 'Adverisment body',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) => widget.shopItem.body = text
                                //body = text
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.shopItem.imageUrl.isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: SizedBox(
                              height: 175,
                              child: ReorderableListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (Photo photo in photos)
                                    if (photo.url.contains('drives')) ...[
                                      showLocalImage(photo.url)
                                    ] else ...[
                                      showWebImage(
                                        context: context,
                                        Uri.parse(
                                                '${urlBase}v1/shop_item/images/${widget.shopItem.uri}/${photo.url}')
                                            .toString(),
                                        // canDelete: true,
                                        index: photo.index,
                                        onDelete: (idx) => onDeleteImage(idx),
                                      ), //        {debugPrint('onDelete $idx')})
                                    ]
                                ],
                                onReorder: (int oldIndex, int newIndex) {
                                  setState(() {
                                    if (oldIndex < newIndex) {
                                      newIndex -= 1;
                                    }
                                    final Photo item =
                                        photos.removeAt(oldIndex);
                                    photos.insert(newIndex, item);
                                    List<String> urls = [
                                      for (Photo photo in photos)
                                        photo.toMapString()
                                    ];
                                    widget.shopItem.imageUrl = urls.toString();
                                    debugPrint(
                                        'reordered: ${widget.shopItem.imageUrl}');
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (widget.shopItem.links > 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: TextFormField(
                                  readOnly: !canEdit,
                                  initialValue: widget.shopItem.buttonText1,
                                  autofocus: canEdit,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.streetAddress,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "Link button label",
                                    labelText: 'Button 1 label',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) =>
                                      widget.shopItem.buttonText1 = text),
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
                                  initialValue: widget.shopItem.url1,
                                  autofocus: canEdit,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.url,
                                  textCapitalization: TextCapitalization.none,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText:
                                        "What is the link url for button 1",
                                    labelText: 'Link 1 url',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) =>
                                      widget.shopItem.url1 = text),
                            ),
                          )
                        ],
                      ),
                    ],
                    if (widget.shopItem.links > 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: TextFormField(
                                  readOnly: !canEdit,
                                  initialValue: widget.shopItem.buttonText1,
                                  autofocus: canEdit,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.streetAddress,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "Link button label",
                                    labelText: 'Button 2 label',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) =>
                                      widget.shopItem.buttonText2 = text),
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
                                  initialValue: widget.shopItem.url1,
                                  autofocus: canEdit,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.streetAddress,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText:
                                        "What is the link url for button 2",
                                    labelText: 'Link 2 url',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) =>
                                      widget.shopItem.url2 = text),
                            ),
                          )
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  loadImage(int id) async {
    if (widget.index == id) {
      try {
        ImagePicker picker = ImagePicker();
        await //ImagePicker()
            picker.pickImage(source: ImageSource.gallery).then(
          (pickedFile) async {
            try {
              if (pickedFile != null) {
                final directory =
                    (await getApplicationDocumentsDirectory()).path;

                /// Don't know what type of image so have to get file extension from picker file
                int num = 1;
                if (widget.shopItem.imageUrl.isNotEmpty) {
                  /// count number of images
                  num = '{'.allMatches(widget.shopItem.imageUrl).length + 1;
                }
                debugPrint('Image count: $num');
                String imagePath =
                    '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
                File(pickedFile.path).copy(imagePath);
                setState(() {
                  widget.shopItem.imageUrl =
                      '[${widget.shopItem.imageUrl.isNotEmpty ? '${widget.shopItem.imageUrl.substring(1, widget.shopItem.imageUrl.length - 1)},' : ''},{"url":"$imagePath","caption":"image $num"}]';
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

  onDeleteImage(int idx) {
    debugPrint('delete image $idx');
    setState(() => photos.removeAt(idx));
  }

  expand(bool state, bool canEdit) {
    expanded = state;
  }

  List<String> getImageUrls(PointOfInterest pointOfInterest) {
    var pics = jsonDecode(pointOfInterest.getImages());
    return [
      for (String pic in pics)
        Uri.parse('${urlBase}v1/drive/images${pointOfInterest.url}$pic')
            .toString()
    ];
  }

  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
        key: Key('sli$index'), width: 160, child: Image.file(File(url)));
  }

  changeRating(value) {
    widget.onRated!(value, widget.index);
    setState(() => widget.shopItem.score = value.toDouble());
  }
}
