import 'package:flutter/material.dart';
import 'package:drives/models.dart';
// import 'package:drives/services/db_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// An example of a widget with a controller.
/// The controller allows to the widget to be controlled externally
/// In this case I wanted the widget to edit the data independantly
/// of the external data and update the external data when the save method is called
/// accessing the save method is achieved through the controller
/*

class PointOfInterestController {
  _PointOfInterestTileState? _pointOfInterestTileState;
  void _addState(_PointOfInterestTileState pointOfInterestTileState) {
    _pointOfInterestTileState = pointOfInterestTileState;
  }

  bool get isAttached => _pointOfInterestTileState != null;

  void loadImage(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _pointOfInterestTileState?.loadImage(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }

  void save(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    _pointOfInterestTileState?.save(id);
  }

  void expand(bool state, bool canEdit) {
    assert(isAttached, 'Controller must be atexpandtached to widget');
    _pointOfInterestTileState?.expand(state, canEdit);
  }
}
*/
class PointOfInterestTile extends StatefulWidget {
//  final PointOfInterestController? pointOfInterestController;
  final PointOfInterest pointOfInterest;
  final int index;
  final Function onIconTap;
  final Function onExpandChange;
  // final Key key;
  final bool expanded;
  final bool canEdit;

  const PointOfInterestTile({
    //required this.key,
    super.key,
//    required this.pointOfInterestController,
    required this.index,
    required this.pointOfInterest,
    required this.onIconTap,
    required this.onExpandChange,
    this.expanded = false,
    this.canEdit = true,
  }); // : super(key: key);
  @override
  State<PointOfInterestTile> createState() => _PointOfInterestTileState();
}

class _PointOfInterestTileState extends State<PointOfInterestTile> {
  // late String name;
  //  late String description;
  //   late int type;
  /// late String images;
  late int index;
  bool expanded = false;
  bool canEdit = true;
  // final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    //   widget.pointOfInterestController?._addState(this);

    /// add to controller if instantiated
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    //  name = widget.pointOfInterest.name;
    //  description = widget.pointOfInterest.description;
    //  type = widget.pointOfInterest.type;
    //  images = widget.pointOfInterest.images;
    // images =
    //     '[{"url":"/data/user/0/com.example.drives/app_flutter/point_of_interest_0_1.jpg","caption":"image 1"},{"url":"/data/user/0/com.example.drives/app_flutter/point_of_interest_0_1.jpg","caption":"image 1"}]';

    /*
        '''[{"url":"/data/user/0/com.example.drives/app_flutter/point_of_interest_0_1.jpg","caption":"image 1"},
           {"url":"/data/user/0/com.example.drives/app_flutter/point_of_interest_0_1.jpg","caption":"image 1"},
        {"url":"/data/user/0/com.example.drives/app_flutter/point_of_interest_0_1.jpg","caption":"image 1"}]''';
    */
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('$widget.key'),
      child: ExpansionTile(
        controller: ExpansionTileController(),

        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        title: widget.pointOfInterest.name == ''
            ? const Text(
                'Add a point of interest',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(widget.pointOfInterest.name,
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
          icon: Icon(markerIcon(widget.pointOfInterest.type)),
          onPressed: widget.onIconTap(widget.index),
        ),

        /*
        trailing: IconButton(
          iconSize: 25,
          icon: const Icon(Icons.delete),
          onPressed: widget.onIconTap(widget.index),
        ),
        */
        children: [
          SizedBox(
              // height: 200,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 30),
                  child: Column(children: <Widget>[
                    Row(children: [
                      if (canEdit) ...[
                        Expanded(
                            flex: 10,
                            child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Type',
                                ),
                                value: widget.pointOfInterest.type.toString(),
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
                                    widget.pointOfInterest.type =
                                        item == null ? -1 : int.parse(item))),
                        Expanded(
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
                        ),
                      ] else ...[
                        Expanded(
                          flex: 10,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 20),
                              child: Row(children: [
                                Icon(
                                  IconData(
                                      poiTypes[widget.pointOfInterest.type]
                                          ['iconMaterial'],
                                      fontFamily: 'MaterialIcons'),
                                  color: Color(
                                      poiTypes[widget.pointOfInterest.type]
                                          ['colourMaterial']),
                                ),
                                Text(
                                    '    ${poiTypes[widget.pointOfInterest.type]['name']}')
                              ])),
                        ),
                      ],
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 10, 10),
                                child: TextFormField(
                                    readOnly: !canEdit,
                                    initialValue: widget.pointOfInterest.name,
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
                                    onChanged: (text) =>
                                        widget.pointOfInterest.name = text)))
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
                                  //     expands: true,
                                  initialValue:
                                      widget.pointOfInterest.description,
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
                                  onChanged: (text) => widget.pointOfInterest
                                      .description = text //body = text
                                  )),
                        ),
                      ],
                    ),
                    if (widget.pointOfInterest.images.isNotEmpty)
                      Row(children: <Widget>[
                        Expanded(
                            flex: 8,
                            child: SizedBox(
                                height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int i = 0;
                                        i <
                                            photosFromJson(widget
                                                    .pointOfInterest.images)
                                                .length;
                                        i++)
                                      Row(
                                        children: [
                                          SizedBox(
                                              width: 160,
                                              child: Image.file(File(
                                                  photosFromJson(widget
                                                          .pointOfInterest
                                                          .images)[i]
                                                      .url))),
                                          const SizedBox(
                                            width: 30,
                                          )
                                        ],
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
      try {
        ImagePicker picker = ImagePicker();
        await //ImagePicker()
            picker
                .pickImage(source: ImageSource.gallery)
                .then((pickedFile) async {
          try {
            if (pickedFile != null) {
              final directory = (await getApplicationDocumentsDirectory()).path;

              /// Don't know what type of image so have to get file extension from picker file
              int num = 1;
              if (widget.pointOfInterest.images.isNotEmpty) {
                /// count number of images
                num = '{'.allMatches(widget.pointOfInterest.images).length + 1;
              }
              debugPrint('Image count: $num');
              String imagePath =
                  '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
              File(pickedFile.path).copy(imagePath);
              setState(() {
                widget.pointOfInterest.images =
                    '[${widget.pointOfInterest.images.isNotEmpty ? '${widget.pointOfInterest.images.substring(1, widget.pointOfInterest.images.length - 1)},' : ''}{"url":"$imagePath","caption":"image $num"}]';
                debugPrint('Images: $widget.pointOfInterest.images');
              });
            }
          } catch (e) {
            String err = e.toString();
            debugPrint('Error getting image: $err');
          }
        });
      } catch (e) {
        String err = e.toString();
        debugPrint('Error loading image: $err');
      }
    }
  }

  save(int id) {
    if (widget.index == id) {
      expanded = false;
      debugPrint(
          'Updating the pointofinterest: ${widget.pointOfInterest.name} [${widget.pointOfInterest.type}]');

      widget.pointOfInterest.name = widget.pointOfInterest.name;
      widget.pointOfInterest.description = widget.pointOfInterest.description;
      widget.pointOfInterest.type = widget.pointOfInterest.type;
      widget.pointOfInterest.images = widget.pointOfInterest.images;
      //   widget.pointOfInterest.iconData = markerIcon(type);
    }
  }

  expand(bool state, bool canEdit) {
    expanded = state;
  }
}
