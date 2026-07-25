import 'package:flutter/material.dart';
import 'dart:math';
import '/classes/classes.dart';
import '/models/models.dart';

class PhotoCarousel extends StatefulWidget {
  final bool canEdit;
  final bool showCaptions;
  final List<Photo> photos;
  final int webUrlMaxLength;
  final double height;
  final double width;
  final Color selectedColor;
  final Color unSelectedColor;
  final ImageRepository imageRepository;

  const PhotoCarousel(
      {super.key,
      required this.photos,
      required this.imageRepository,
      this.canEdit = false,
      this.showCaptions = false,
      this.webUrlMaxLength = 40,
      this.height = 450,
      this.width = 100,
      this.selectedColor = Colors.blueAccent,
      this.unSelectedColor = Colors.grey});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int imageIndex = 0;
  double screenWidth = 0;
  late final Future<List<Image>> _imagesLoaded;
  final PageController _pageController = PageController();
  final ImageListIndicatorController _imageListIndicatorController =
      ImageListIndicatorController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() => pageControlListener());
    _imagesLoaded = getImageList(photos: widget.photos);
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
                            child: FutureBuilder(
                              future:
                                  _imagesLoaded, //   getImageList(photos: widget.photos),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  debugPrint(
                                    'Snapshot error: ${snapshot.error.toString()}',
                                  );
                                  return const ImageMissing(width: 400);
                                } else if (snapshot.hasData) {
                                  return getPageView(
                                      snapshot.data!, widget.photos);
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
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

  Future<List<Image>> getImageList({required List<Photo> photos}) async {
    List<Image> images = [];

    for (int i = 0; i < photos.length; i++) {
      if (photos[i].url.contains('assets/images')) {
        try {
          images.add(
            Image(
              image:
                  AssetImage('assets/images/${photos[i].url.split('/').last}'),
            ),
          );
        } catch (e) {
          debugPrint('error ${e.toString()}');
        }
      } else {
        Map<String, Image> imageMap = await widget.imageRepository.loadImage(
          key: photos[i].key,
          id: photos[i].id,
          uri: photos[i].url,
        );
        photos[i].key = imageMap.keys.first;
        images.add(imageMap.values.first);
      }
    }
    return images;
  }

  Widget getPageView(List<Image> imageList, List<Photo> photos) {
    return PageView.builder(
      itemCount: widget.photos.length,
      scrollDirection: Axis.horizontal,
      controller: _pageController,
      itemBuilder: (BuildContext context, int index) {
        /// angle is in radians 2 Pi radians = 360 degrees clockwise 0.5 1 1.5
        // return Stack(
        return Column(
          children: [
            Expanded(
              flex: 11,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: Transform.rotate(
                  angle: pi * photos[index].rotation * 0.5,
                  child: InkWell(
                    onTap: () => _pageController.animateToPage(
                        index == photos.length - 1 ? 0 : ++index,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.bounceInOut),
                    child: ClipRRect(
                        borderRadius:
                            BorderRadiusGeometry.all(Radius.circular(10.0)),
                        child: imageList[index]),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text(
                  photos[index].caption,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  onDeleteImage(int index) {}

  deleteWebImage(String url) {}
}
