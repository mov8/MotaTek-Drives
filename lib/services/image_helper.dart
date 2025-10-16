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
    _contentControllerTitle.text = widget.pointOfInterest.description == ''
        ? 'Point of interest - ${poiTypes[widget.pointOfInterest.type]["name"]}'
        : widget.pointOfInterest.description;
    _contentControllerBody.text = widget.pointOfInterest.description;
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
                        widget.pointOfInterest.description =
                            _contentControllerTitle.text;
                        widget.pointOfInterest.description =
                            _contentControllerBody.text;
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
                                photosFromJson(
                                        photoString:
                                            widget.pointOfInterest.images)
                                    .length;
                            i++)
                          SizedBox(
                            width: 160,
                            child: Image.file(
                              File(photosFromJson(
                                      photoString:
                                          widget.pointOfInterest.images)[i]
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
        widget.pointOfInterest.images =
            ("${widget.pointOfInterest.images}, {'url': ${pickedFile.path}, 'caption':}");
        // _image = File(pickedFile.path);
      }
    });
  }
}

/// loadDeviceImage handles the loading of images from camara or gallary
/// The imageUrl is of the form:
/// [{url: ___, caption: ___, rotation:_ },{...] which is modified throuh th
/// imageUrls

Future<String> loadDeviceImage(
    {required String imageUrls,
    int itemIndex = 0,
    imageFolder = 'point_of_interest'}) async {
  try {
    ImagePicker picker = ImagePicker();
    await //ImagePicker()
        picker.pickImage(source: ImageSource.gallery, imageQuality: 10).then(
      (pickedFile) async {
        try {
          if (pickedFile != null) {
            final directory = Setup().appDocumentDirectory;

            /// Don't know what type of image so have to get file extension from picker file
            int num = 1;
            if (imageUrls.isNotEmpty) {
              /// count number of images
              num = '{'.allMatches(imageUrls).length + 1;
            }
            debugPrint('Image count: $num');
            String imagePath =
                '$directory/${imageFolder}_${itemIndex}_$num.${pickedFile.path.split('.').last}';

            File image = File(pickedFile.path);
            image.copy(imagePath);

            var decodedImage =
                await decodeImageFromList(image.readAsBytesSync());
            int rotate = decodedImage.width > decodedImage.height ? 3 : 0;

            imageUrls =
                '[${imageUrls.isNotEmpty ? '${imageUrls.substring(1, imageUrls.length - 1)},' : ''}{"url":"$imagePath","caption":"image $num","rotation":$rotate}]';
            debugPrint('Images: $imageUrls');
            return imageUrls;
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
  return imageUrls;
}
