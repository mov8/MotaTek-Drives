import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '/models/other_models.dart';
import '/helpers/edit_helpers.dart';

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

/// getDeviceImage() is a streamlined method for getting images from
/// a device
///   index is the position in any list of photos
///   fileName is the file path/name without the extension

Future<Photo?> getDeviceImage(
    {int index = 0,
    String folder = '',
    String fileName = 'image',
    ImageSource source = ImageSource.gallery}) async {
  ImagePicker picker = ImagePicker();
  try {
    XFile? image = await picker.pickImage(source: source, imageQuality: 10);
    if (image != null) {
      Directory targetDirectory =
          Directory('${Setup().appDocumentDirectory}/$folder');
      if (!await targetDirectory.exists()) {
        await targetDirectory.create();
      }
      final target =
          '${targetDirectory.path}/$fileName.${image.path.split('.').last}';
      File(image.path).copy(target);
      File(image.path).delete();
      return Photo(url: target, index: index);
    }
  } catch (e) {
    debugPrint('Error getting image from gallery: ${e.toString()}');
  }
  return null;
}

/// Creates a list of photos from a json string of the following format:
///  '[{"url": "assets/images/map.png", "caption": ""}, {"url": "assets/images/splash.png", "caption": ""},
///   {"url": "assets/images/CarGroup.png", "caption": "" }]',
///  post-constructor function handleWebImages converts a simple image file name to a map to reduce web traffic
///  for some strange reason the string must start with a single quote.
///
/// The photoString comes directly from the api. It is an escaped string with all embedded "s escaped with a \ ie \"
///    ["{\"url\":\"4ecb1d1f-ed47-4e4d-9614-d1a4bc398b15.jpg\",\"caption\":\"image1\",\"rotation\":0}"]
///   1st jsonDecode turns it ito jsonPhotos a list of Flutter Strings ie.
///     [0]{"url":"4ecb1d1f-ed47-4e4d-9614-d1a4bc398b15.jpg","caption":"image1","rotation":0} <-- JsonString - length 82
///   2nd jsonDecode on the jsonString converts it to a Map (Photo) with keys url: caption: rotation:
///
///

List<Photo> photosFromJson({String photoString = '', String endPoint = ''}) {
  if (photoString.isNotEmpty) {
    int index = 0;
    try {
      /// 1st jsonDecode() converts sent escaped String to a list of JsonString
      dynamic jsonPhotos = jsonDecode(photoString);
      if (jsonPhotos is String) {
        jsonPhotos = jsonDecode(jsonPhotos);
      }
      List<Photo> photos = [];
      endPoint =
          Setup().serverUp && !photoString.contains('assets/') ? endPoint : '';
      for (dynamic jsonPhoto in jsonPhotos) {
        jsonPhoto =
            photoString.contains('[{') ? jsonPhoto : jsonDecode(jsonPhoto);
        photos
            .add(Photo.fromJson(jsonPhoto, endPoint: endPoint, index: index++));
      }
      return photos;
    } catch (e) {
      debugPrint('Error photosFromJsonL ${e.toString()}');
    }
  }
  return [];
}

String photosToString({required List<Photo> photos}) {
  String uriString = '';
  String delim = '';
  for (int i = 0; i < photos.length; i++) {
    uriString =
        '$uriString$delim{"url":\"${photos[i].url}\","caption":\"${photos[i].caption}\","rotation":${photos[i].rotation}}';
    delim = ',';
  }
  return '[$uriString]';
}

List<Photo> photosFromMap(String photoString) {
  List<Photo> photos = [
    for (Map<String, String> url in jsonDecode(photoString)) Photo.fromJson(url)
  ];
  return photos;
}

String photosToJson(List<Photo> photos) {
  String photoString = '';
  for (int i = 0; i < photos.length; i++) {
    photoString = '$photoString, ${photos[i].toJson()} ';
  }
  photoString = '[${photoString.substring(1, photoString.length)}]';
  return photoString;
}
