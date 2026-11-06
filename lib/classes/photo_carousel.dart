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
  final Color? selectedColor; // the brand colour, unless set
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
      this.selectedColor,
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

  /// The photos, their captions, and the dots for which is showing. Each
  /// photo sits on the same line, its caption just below it and the dots
  /// just below that - whatever the photo's shape. (A photo was pinned to
  /// the top, so a landscape one left a gap above its caption and the dots.)
  /// No wider than the space it's given - the web's drawer is narrower than
  /// the screen.
  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return LayoutBuilder(builder: (context, box) {
      double width = widget.width > 0
          ? (box.hasBoundedWidth
              ? min(widget.width, box.maxWidth)
              : widget.width)
          : (box.hasBoundedWidth ? box.maxWidth : screenWidth);
      return SizedBox(
        height: widget.height > 0 ? widget.height : 450,
        width: width,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: _imagesLoaded,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                      'Snapshot error: ${snapshot.error.toString()}',
                    );
                    return const ImageMissing(width: 400);
                  } else if (snapshot.hasData) {
                    return getPageView(snapshot.data!, widget.photos);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 6),
            ImageListIndicator(
              controller: _imageListIndicatorController,
              photos: widget.photos,
            ),
          ],
        ),
      );
    });
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

  /// Each page: the photo at the bottom of its space, so its bottom edge -
  /// and the caption under it - are in the same place for every photo
  Widget getPageView(List<Image> imageList, List<Photo> photos) {
    return PageView.builder(
      itemCount: widget.photos.length,
      scrollDirection: Axis.horizontal,
      controller: _pageController,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                // quarter turns - laid out turned, unlike Transform.rotate,
                // so a turned photo's bottom is where it's drawn
                child: RotatedBox(
                  quarterTurns: photos[index].rotation,
                  child: InkWell(
                    onTap: () => _pageController.animateToPage(
                        index == photos.length - 1 ? 0 : index + 1,
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
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: Text(
                photos[index].caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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
