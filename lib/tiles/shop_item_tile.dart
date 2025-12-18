import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import 'package:universal_io/universal_io.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '/helpers/helpers.dart';

class ShopItemTileController {
  _ShopItemTileState? _shopItemTileState;

  void _addState(_ShopItemTileState shopItemTileState) {
    _shopItemTileState = shopItemTileState;
  }

  bool get isAttached => _shopItemTileState != null;
  void contract() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _shopItemTileState?.changeOpenState();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void updatePhotos() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _shopItemTileState?.getPhotos();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error getting photos: $err');
    }
  }

  void addLink() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _shopItemTileState?.addLink();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error getting photos: $err');
    }
  }
}

class ShopItemTile extends StatefulWidget {
  final ShopItem shopItem;
  final ShopItemTileController controller;
  final int index;
  final Function(bool, ShopItemTileController)? onExpandChange;
  final Function(int, int)? onRated;
  final Function(int)? onChange;
  final bool expanded;
  final bool canEdit;
  bool? changed;
  ShopItemTile({
    super.key,
    required this.controller,
    required this.index,
    required this.shopItem,
    this.onExpandChange,
    this.onRated,
    this.onChange,
    this.expanded = false,
    this.canEdit = true,
  });
//      this.onSelect});
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
  int imageIndex = 0;
  List<DropdownMenuItem<String>> dropDownMenuItems = [];
  ExpansibleController _expansibleController = ExpansibleController();
  List<FocusNode> linkNodes = [FocusNode(), FocusNode()];

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    developer.log('ShopItemTile initState called', name: '_groupTile');
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    dropDownMenuItems = covers
        .map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        )
        .toList();
    _links = widget.shopItem.url1.isNotEmpty ? 1 : 0;
    _links = widget.shopItem.url2.isNotEmpty ? 2 : _links;
    //  getPhotos();
  }

  @override
  void dispose() {
    linkNodes[0].dispose();
    linkNodes[1].dispose();
    developer.log('ShopItemTile dispose called', name: '_groupTile');
    super.dispose();
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
      imageUrlLength = widget.shopItem.imageUrls.length;
      photos = photosFromJson(
          photoString: widget.shopItem.imageUrls,
          endPoint: '$urlShopItem/images/${widget.shopItem.uri}/');
      imageIndex = 0;
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  addLink() {
    if (_links < 2) {
      _links++;
      setState(() => linkNodes[_links - 1].requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shopItem.imageUrls.length != imageUrlLength) {
      getPhotos();
    }

    return Card(
      key: Key('$widget.key'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          controller: _expansibleController,
          title: widget.shopItem.heading == ''
              ? Text(
                  'Add a home page item',
                  style: headlineStyle(
                      context: context, size: 2, color: Colors.black),
                )
              : Text(
                  widget.shopItem.heading,
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
            Expanded(
                flex: 1,
                child: Text('rank 0',
                    style: textStyle(
                        context: context, size: 3, color: Colors.black)))
          ]),
          onExpansionChanged: (expanded) =>
              widget.onExpandChange!(expanded, widget.controller),
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
                            labelStyle: labelStyle(
                                context: context, color: Colors.black, size: 2),
                            labelText: 'Coverage',
                            hintStyle: hintStyle(
                                context: context, color: Colors.blueGrey),
                          ),
                          initialValue: widget.shopItem.coverage,
                          items: dropDownMenuItems,
                          style: textStyle(
                              context: context, color: Colors.black, size: 2),
                          onChanged: (item) {
                            widget.shopItem.coverage = item ?? 'all';
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
                              initialValue: widget.shopItem.score.toString(),
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: const TextInputType
                                  .numberWithOptions(), //for(i = -1; i < 100; i++) i.toString()],
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "-1 invisible higher the better",
                                labelText: 'Ad ranking',
                                labelStyle: labelStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                              ),
                              style: textStyle(
                                  context: context,
                                  size: 2,
                                  color: Colors
                                      .black), //Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) {
                                widget.onChange!(index);
                                widget.shopItem.heading = text;
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
                              initialValue: widget.shopItem.heading,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "What is the promotion's heading...",
                                labelText: 'Promotion heading',
                                labelStyle: labelStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                              ),
                              style: textStyle(
                                  context: context,
                                  size: 2,
                                  color: Colors
                                      .black), //Theme.of(context).textTheme.bodyLarge,
                              //   style:Theme.of(context).textTheme.bodyLarge,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (text) {
                                widget.onChange!(index);
                                widget.shopItem.heading = text;
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
                                initialValue: widget.shopItem.subHeading,
                                autofocus: canEdit,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      "What is the shop item's sub-heading...",
                                  labelText: 'Shop item sub-heading',
                                  labelStyle: labelStyle(
                                      context: context,
                                      size: 2,
                                      color: Colors.black),
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors
                                        .black), //Theme.of(context).textTheme.bodyLarge,
                                //style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.subHeading = text;
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
                                initialValue: widget.shopItem.body,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Promo content...',
                                  labelText: 'Promotion body',
                                  labelStyle: labelStyle(
                                      context: context,
                                      size: 2,
                                      color: Colors.black),
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors
                                        .black), //Theme.of(context).textTheme.bodyLarge,
                                // style: Theme.of(context).textTheme.bodyLarge,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.body = text;
                                }
                                //body = text
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.shopItem.imageUrls.isNotEmpty)
                      Column(
                        children: [
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 8,
                                child: ImageArranger(
                                  onChange: (idx) => setState(() {
                                    widget.onChange!(index);
                                    imageIndex = idx;
                                  }),
                                  //  urlChange: (_) => (),
                                  urlChange: (imageUrls) =>
                                      widget.shopItem.imageUrls = imageUrls,
                                  photos: photos,
                                  endPoint: '', // widget.homeItem.uri,
                                  showCaptions: true,
                                ),
                              ),
                            ],
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
                                focusNode: linkNodes[0],
                                initialValue: widget.shopItem.buttonText1,
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
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.buttonText1 = text;
                                },
                              ),
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
                                //  readOnly: !canEdit,
                                initialValue: widget.shopItem.url1,
                                textInputAction: _links > 1
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.url,
                                textCapitalization: TextCapitalization.none,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "What is the link url for button 1",
                                  labelText: 'Link 1 url',
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.url1 = text;
                                },
                              ),
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
                                initialValue: widget.shopItem.buttonText1,
                                focusNode: linkNodes[1],
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
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.buttonText2 = text;
                                },
                              ),
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
                                initialValue: widget.shopItem.url1,
                                textInputAction: TextInputAction.done,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "What is the link url for button 2",
                                  labelText: 'Link 2 url',
                                ),
                                style: textStyle(
                                    context: context,
                                    size: 2,
                                    color: Colors.black),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (text) {
                                  widget.onChange!(index);
                                  widget.shopItem.url2 = text;
                                },
                              ),
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

  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
        key: Key('sli$index'), width: 160, child: Image.file(File(url)));
  }

  changeRating(value) {
    widget.onRated!(value, widget.index);
    setState(() => widget.shopItem.score = value.toDouble());
  }
}
