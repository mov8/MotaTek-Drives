import 'package:flutter/material.dart';
import 'dart:io';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/services/services.dart';
// import 'package:drives/classes/image_list_indicator.dart';

class PhotoCarousel extends StatefulWidget {
  final bool canEdit;
  final bool showCaptions;
  final String endPoint;
  final List<Photo> photos;
  final int webUrlMaxLength;
  final double height;
  final double width;
  //final int imageIndex = 0;
  final Color selectedColor;
  final Color unSelectedColor;
  final ImageRepository imageRepository;

  const PhotoCarousel(
      {super.key,
      required this.photos,
      required this.imageRepository,
      this.endPoint = ' ',
      this.canEdit = false,
      this.showCaptions = false,
      this.webUrlMaxLength = 40,
      this.height = 450,
      this.width = 0,
      this.selectedColor = Colors.blueAccent,
      this.unSelectedColor = Colors.grey});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int imageIndex = 0;
  double screenWidth = 0;

  final PageController _pageController = PageController();
  final ImageListIndicatorController _imageListIndicatorController =
      ImageListIndicatorController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() => pageControlListener());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  pageControlListener() {
    setState(() => _imageListIndicatorController
        .changeImageIndex(_pageController.page!.round()));
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Column(children: [
      SizedBox(
        height: widget.height > 0 ? widget.height : null,
        width: widget.width > 0 ? widget.width : null,
        child: Row(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: SizedBox(
                    width: widget.width -
                        15, // MediaQuery.of(context).size.width - 20,
                    height: widget.height - 45,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 8,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width, // 375,
                            child: PageView.builder(
                              itemCount: widget.photos.length,
                              scrollDirection: Axis.horizontal,
                              controller: _pageController,
                              itemBuilder: (BuildContext context, int index) {
                                imageIndex = index;
                                return getImages(
                                    index: index, photos: widget.photos);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ImageListIndicator(
                  controller: _imageListIndicatorController,
                  photos: widget.photos,
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  getImages(
      {required int index, required List<Photo> photos, double width = 400}) {
    try {
      //Future<Map<int, Image>> imageMap =
      Map<int, Image> imageMap = widget.imageRepository.loadImage(
          key: photos[index].key, id: photos[index].id, uri: photos[index].url);

      photos[index].key = imageMap.keys.first;
      Image? image = imageMap.values.first;
      return SizedBox(
        key: Key('sli$index'),
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: image, // ?? ImageMissing(width: width),
        ),
      );
    } catch (e) {
      debugPrint('getImages error: ${e.toString()}');
    }
    /*
    return const Icon(
      Icons.no_photography,
      size: 100,
    );
    */
    return ImageMissing(width: width);
  }

  getImages2(String url, int index) {
    // debugPrint('getImages() called - url: $url');
    try {
      if (widget.endPoint.contains('http')) {
        return showWebImage(
          '${widget.endPoint}${widget.photos[index].url}',
          width: screenWidth - 10, //400,
          onDelete: (response) => debugPrint('Response: $response'),
        );
      } else {
        return showLocalImage(widget.endPoint, widget.photos[index].url,
            index: index, width: screenWidth - 10);
      }
    } catch (e) {
      return const Icon(
        Icons.no_photography,
        size: 100,
      );
    }
  }

  onDeleteImage(int index) {}

  deleteWebImage(String url) {}

  Widget showLocalImage(String url, String image,
      {int index = -1, double width = 400}) {
    debugPrint('Local url: $url');
    try {
      return SizedBox(
        key: Key('sli$index'),
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: url.contains('assets')
              ? Image(
                  image: AssetImage('$url$image'),
                )
              : Image.file(
                  File('$url$image'),
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return ImageMissing(width: width);
                  },
                ),
        ),
      );
    } catch (e) {
      return const Icon(
        Icons.no_photography,
        size: 100,
      );
    }
  }
}
