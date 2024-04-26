import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller

class PointOfInterestController {
  _PointOfInterestTileState? _pointOfInterestTileState;
  void _addState(_PointOfInterestTileState pointOfInterestTileState) {
    _pointOfInterestTileState = pointOfInterestTileState;
  }

  bool get isAttached => _pointOfInterestTileState != null;

  void loadImage(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    _pointOfInterestTileState?.loadImage(id);
  }

  void save(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    _pointOfInterestTileState?.save(id);
  }

  void expand(bool state) {
    assert(isAttached, 'Controller must be atexpandtached to widget');
    _pointOfInterestTileState?.expand(state);
  }
}

class PointOfInterestTile extends StatefulWidget {
  final PointOfInterestController? pointOfInterestController;
  final PointOfInterest pointOfInterest;
  final int index;
  final Function onIconTap;
  final Function onExpandChange;
  final Key key;
  final bool expanded;

  const PointOfInterestTile(
      {required this.key,
      required this.pointOfInterestController,
      required this.index,
      required this.pointOfInterest,
      required this.onIconTap,
      required this.onExpandChange,
      this.expanded = false})
      : super(key: key);
  @override
  State<PointOfInterestTile> createState() => _PointOfInterestTileState();
}

class _PointOfInterestTileState extends State<PointOfInterestTile> {
  late String name;
  late String description;
  late int type;
  late String images;
  late int index;
  bool expanded = false;
  // final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.pointOfInterestController?._addState(this);

    /// add to controller if instantiated
    expanded = widget.expanded;
    index = widget.index;
    name = widget.pointOfInterest.name;
    description = widget.pointOfInterest.description;
    type = widget.pointOfInterest.type;
    images = widget.pointOfInterest.images;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('$widget.key'),
      child: ExpansionTile(
        controller: ExpansionTileController(),

        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        title: name == ''
            ? const Text(
                'Add a point of interest',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(name,
                style: const TextStyle(
                    color: Colors.black)), //getTitles(index)[0]),
        collapsedBackgroundColor: widget.index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        backgroundColor: Colors.white,
        initiallyExpanded: expanded,
        onExpansionChanged: (expanded) {
          setState(() {
            widget.onExpandChange(expanded ? index : -1);
          });
        },
        leading: IconButton(
          iconSize: 25,
          icon: Icon(markerIcon(type)),
          onPressed: widget.onIconTap(widget.index),
        ),
        children: [
          SizedBox(
              // height: 200,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 30),
                  child: Column(children: <Widget>[
                    Row(children: [
                      Expanded(
                          flex: 10,
                          child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Type',
                              ),
                              value: type.toString(),
                              items: poiTypes
                                  .map((item) => DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Row(children: [
                                          Icon(
                                            IconData(item['iconMaterial'],
                                                fontFamily: 'MaterialIcons'),
                                            color:
                                                Color(item['colourMaterial']),
                                          ),
                                          Text('    ${item['name']}')
                                        ]),
                                      ))
                                  .toList(),
                              onChanged: (item) =>
                                  type = item == null ? -1 : int.parse(item))),
                      const Expanded(
                        flex: 8,
                        child: SizedBox(),
                      ),
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 10, 10),
                                child: TextFormField(
                                    initialValue: name,
                                    textAlign: TextAlign.start,
                                    keyboardType: TextInputType.streetAddress,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText:
                                          "What is the point of interest's name...",
                                      labelText: 'Point of interest name',
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    onChanged: (text) => name = text)))
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: TextFormField(
                                  initialValue: description,
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.streetAddress,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Describe Point of Interest...',
                                    labelText: 'Point of interest description',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) =>
                                      description = text //body = text
                                  )),
                        ),
                      ],
                    ),
                    if (images.isNotEmpty)
                      Row(children: <Widget>[
                        Expanded(
                            flex: 8,
                            child: SizedBox(
                                height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int i = 0;
                                        i < photosFromJson(images).length;
                                        i++)
                                      SizedBox(
                                          width: 160,
                                          child: Image.file(File(
                                              photosFromJson(images)[i].url))),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                  ],
                                )))
                      ]),
                  ]))),
        ],
      ),
    );
  }

  loadImage(int id) async {
    if (widget.index == id) {
      await ImagePicker()
          .pickImage(source: ImageSource.gallery)
          .then((pickedFile) {
        try {
          if (pickedFile != null) {
            images = "$images, {'url': ${pickedFile.path}, 'caption:'}";
          }
        } catch (e) {
          debugPrint('Error getting image: ${e.toString()}');
        }
      });
    }
  }

  save(int id) {
    if (widget.index == id) {
      expanded = false;
      debugPrint('Updating the pointofinterest: $name [$type]');

      widget.pointOfInterest.name = name;
      widget.pointOfInterest.description = description;
      widget.pointOfInterest.type = type;
      widget.pointOfInterest.images = images;
      widget.pointOfInterest.iconData = markerIcon(type);
    }
  }

  expand(bool state) {
    expanded = state;
  }
}
