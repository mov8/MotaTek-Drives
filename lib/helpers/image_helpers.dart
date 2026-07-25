import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'create_trip_helpers.dart';
import '/models/other_models.dart';
import '../classes/classes.dart';
import '../constants.dart';

// import '/helpers/edit_helpers.dart';

/// https://www.youtube.com/watch?v=MSv38jO4EJk

/// ImagesTempStore is a singleton to allow the holding of images before they are
/// saved either locally on Android iOS, or to the api for the Web.
///
class ImageTempStore {
  static final ImageTempStore _instance = ImageTempStore._internal();
  factory ImageTempStore() => _instance;
  ImageTempStore._internal();

  List<Map<String, dynamic>> images = [];

  add(
      {required String name,
      required Uint8List imageBytes,
      int rotation = 0,
      String caption = ''}) {
    images.add({'key': name, 'value': imageBytes});
  }

  List<Map<String, dynamic>> get all => images;

  int get count => images.length;

  Map<String, dynamic> named({String name = ''}) {
    for (int i = 0; i < images.length; i++) {
      if (images[i]['name'] == name) {
        return images[i];
      }
    }
    return {};
  }

  clear() => images.clear;

  String url = '';
}

/// ImageInMemory will be used to allow images to be stored temporarily in the file - free Web version for:
///   1 Drive map.png
///   2 Point Of Interest image.jpgs
///   3 Homepage images
///   4 Shop images
/// They will be held in their parent objects so their origin will be maintained.
/*
class ImageInMemory {
  final String name;
  Uint8List? _imageBytes;
  String caption = '';
  int rotation = 0;
  ImageInMemory({
    this.name = '',
    Uint8List? imageBytes,
  }) : _imageBytes = imageBytes ?? Uint8List(0);
  
  String get asString =>
      jsonEncode({'url': name, 'caption': caption, 'rotation': rotation});
  Map<String, dynamic> get asJson =>
      {'url': name, 'caption': caption, 'rotation': rotation};

  Uint8List get imageBytes => _imageBytes ?? Uint8List(0);
  set imageBytes(Uint8List imageBytes) => _imageBytes;

  Photo get asPhoto => Photo(url: name, endPoint: 'memory');
}
*/
class ImageInMemory {
  final String name;
  Uint8List imageBytes;
  String caption = '';
  int rotation = 0;
  ImageInMemory({
    this.name = '',
    required this.imageBytes,
  });

  String get asString =>
      jsonEncode({'url': name, 'caption': caption, 'rotation': rotation});
  Map<String, dynamic> get asJson =>
      {'url': name, 'caption': caption, 'rotation': rotation};

  // Uint8List get imageBytes => _imageBytes ?? Uint8List(0);
  // set imageBytes(Uint8List imageBytes) => _imageBytes;

  Photo get asPhoto => Photo(url: name, endPoint: 'memory');
}

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
                                  photoString: widget.pointOfInterest.images,
                                ).length;
                            i++)
                          SizedBox(
                            width: 160,
                            child: Image.file(
                              File(photosFromJson(
                                photoString: widget.pointOfInterest.images,
                              )[i]
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

Future<bool> isImageValid({List<int>? rawList, Uint8List? uInt8List}) async {
  if (uInt8List == null && rawList != null) {
    uInt8List = rawList is Uint8List ? rawList : Uint8List.fromList(rawList);
  }
  try {
    final codec =
        await ui.instantiateImageCodec(uInt8List!); //, targetWidth: 32);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image.width > 0;
  } catch (e) {
    return false;
  }
}

/// loadDeviceImage handles the loading of images from camera or gallery
/// Because there is no file system in the Web version the images are held
/// in the ImageTempStore() singleton. This prevents the image being lost
/// if the user refreshes the browser. The browser does supply a url for
/// any image selected, but that is a sandboxed url that is refreshed with F5
///
/// The imageUrl is of the form:
/// [{url: ___, caption: ___, rotation:_ },{...] which is modified through the
/// imageUrls

Future<String> loadDeviceImage(
    {required String imageUrls,
    int itemIndex = 0,
    imageFolder = 'point_of_interest'}) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ImageTempStore()
          .add(name: image.name, imageBytes: await image.readAsBytes());
    }
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

String getFileName({required String url}) {
  String uName = url;
  if (uName.contains('/')) {
    uName = uName.split('/').last;
  }
  if (uName.contains('\\')) {
    uName = uName.split('\\').last;
  }
  if (uName.contains('.')) {
    List aName = uName.split('.');
    if (aName.length > 1) {
      uName = aName[aName.length - 2];
    }
  }
  uName = uName.isNotEmpty ? uName : getUuid();
  return uName;
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

List<Photo> photosFromJson({
  String photoString = '',
  String endPoint = '',
  int id = -1,
}) {
  if (photoString.isNotEmpty) {
    int index = 0;
    try {
      /// 1st jsonDecode() converts sent escaped String to a List or Map of JsonString
      dynamic jsonPhotos = jsonDecode(photoString);

      /// As jsonDecode returns either a List or a Map have to ensure a map is created
      jsonPhotos = jsonPhotos is Map ? [jsonPhotos] : jsonPhotos;
      List<Photo> photos = [];
      endPoint = Setup().serverUp && (!photoString.contains('assets/'))
          ? endPoint
          : '';

      for (int i = 0; i < jsonPhotos.length; i++) {
        photos.add(
          Photo.fromJson(
            jsonPhotos[i] is String ? jsonDecode(jsonPhotos[i]) : jsonPhotos[i],
            endPoint: endPoint,
            index: index++,
          ),
        );

// Test image that's reachable https://drives.motatek.com/static/images/019ec4cde8777c45b07c7ec4fa9e1324/019ec4cdb93d7f878fba2e8166f9cc21.jpg
      }
      return photos;
    } catch (e) {
      debugPrint('Error photosFromJsonL ${e.toString()}');
    }
  }
  return [];
}

/// photosFromJsonObject converts the following formats to a list of Photo
/// 1 as a String '['{'url': '...', 'caption': '....', 'rotation': 0}', {...}]'
/// 2 as a List ['{'url': '...', 'caption': '....', 'rotation': 0}', {...}]
/// 3 as a Map {'url': '...', 'caption': '....', 'rotation': 0}
/// The endpoint has to be supplied regardless of it's inclusion in the above
/// The Photo.url is the full url including the endpoint
/// The key is always cleared - there's never a route imageRepository -> json -> imageRepository
List<Photo> photosFromJsonObject(
    {required var images, required String endpoint}) {
  images = images is String ? jsonDecode(images) : images;
  images = images is List ? images : [images];
  List<Photo> photos = [];
  // String endpoint = '${urlBase}static/images/${jsonObject['uri'] ?? ''}';
  for (int i = 0; i < images.length; i++) {
    if (images[i] is Map && images[i].isNotEmpty) {
      photos.add(
        Photo(
          url: '$endpoint/${images[i]['url'].split('/').last}',
          caption: images[i]['caption'],
          rotation: images[i]['rotation'],
          key: '',
          endPoint: endpoint,
        ),
      );
    }
  }
  return photos;
}

List<Photo> photosFromImages({Map? map, String folder = '', file = ''}) {
  List<Photo> photos = [];
  if (map != null) {
    List images = jsonDecode(map['images']);
    String dir = folder.isEmpty ? '' : '/$folder';
    for (int i = 0; i < images.length; i++) {
      images[i]['url'] = '$staticImagesFolder$dir/$file.jpg';
      photos.add(Photo.fromJson(images[i]));
    }
  }
  return photos;
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

Future<Image> getImageFromPhoto(
    {required Photo photo, required ImageRepository imageRepository}) async {
  if (photo.url.contains('assets/images')) {
    return Image(
        image: AssetImage('assets/images/${photo.url.split('/').last}'));
  } else {
    Map<String, Image> image = await imageRepository.loadImage(
        key: photo.key, id: photo.id, uri: photo.url);
    return image.values.first;
  }
}
