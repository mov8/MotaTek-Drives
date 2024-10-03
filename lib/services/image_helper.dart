import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drives/models/other_models.dart';

/// https://www.youtube.com/watch?v=MSv38jO4EJk

class PoiDetails extends StatefulWidget {
  final PointOfInterest pointOfInterest;
  final double width;
  final double height;
  final Function onClose;
  final BuildContext context;
  const PoiDetails(
      {super.key,
      required this.context,
      required this.pointOfInterest,
      required this.height,
      required this.width,
      required this.onClose});
  @override
  State<PoiDetails> createState() => _PoiDetails();
}

class _PoiDetails extends State<PoiDetails> {
  final _contentControllerBody = TextEditingController();
  final _contentControllerTitle = TextEditingController();
  // File? _image;

  @override
  initState() {
    super.initState();
    _contentControllerTitle.text = widget.pointOfInterest.getDescription() == ''
        ? 'Point of interest - ${poiTypes[widget.pointOfInterest.getType()]["name"]}'
        : widget.pointOfInterest.getDescription();
    _contentControllerBody.text = widget.pointOfInterest.getDescription();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: SizedBox(
        height: widget.height,
        //  width: widget.width,
        //  color: const Color.fromARGB(255, 213, 231, 247),
        // padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
        //  child: SingleChildScrollView(
        //      child: Column(children: [
        child: ListView(
          children: [
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                        child: TextField(
                          controller: _contentControllerTitle,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Point of interest',
                              hintStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.5)),
                          maxLines: null,
                          textAlign: TextAlign.start,
                          textCapitalization: TextCapitalization.sentences,
                          // decoration: null,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      )),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        //  debugPrint('onPressed pressed');
                        widget.pointOfInterest
                            .setDescription(_contentControllerTitle.text);
                        widget.pointOfInterest
                            .setDescription(_contentControllerBody.text);
                        widget.onClose();
                      }, //widget.onClose(),
                    ),
                  ),
                ]),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: TextField(
                        controller: _contentControllerBody,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Point of interest Description',
                            hintStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                height: 1.5)),
                        maxLines: null,
                        textAlign: TextAlign.start,
                        textCapitalization: TextCapitalization.sentences,
                        // decoration: null,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                ]),
            if (widget.pointOfInterest.getImages().isNotEmpty)
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
                                photosFromJson(
                                        widget.pointOfInterest.getImages())
                                    .length;
                            i++)
                          SizedBox(
                            width: 160,
                            child: Image.file(
                              File(photosFromJson(
                                      widget.pointOfInterest.getImages())[i]
                                  .url),
                            ),
                          ),
                        const SizedBox(
                          width: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Row(children: [
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: const ContinuousRectangleBorder(),
                            elevation: 3,
                            shadowColor: Colors.grey,
                          ),
                          onPressed: () {
                            getImage(ImageSource.gallery);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.image_outlined),
                              SizedBox(
                                width: 10,
                              ),
                              Text("From gallery"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: const ContinuousRectangleBorder(),
                            elevation: 3,
                            shadowColor: Colors.grey,
                          ),
                          onPressed: () {
                            getImage(ImageSource.camera);
                            //     ImagePicker()
                            //         .pickImage(source: ImageSource.camera);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.camera_alt_outlined),
                              SizedBox(
                                width: 10,
                              ),
                              Text("From camera"),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _contentControllerTitle.dispose();
    _contentControllerBody.dispose();
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        widget.pointOfInterest.setImages(
            "${widget.pointOfInterest.getImages()}, {'url': ${pickedFile.path}, 'caption':}");
        // _image = File(pickedFile.path);
      }
    });
  }
}
