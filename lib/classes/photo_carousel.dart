import 'package:flutter/material.dart';
import 'dart:io';
import 'package:drives/models/models.dart';
import 'package:drives/screens/dialogs.dart';

class PhotoCarousel extends StatelessWidget {
  final bool canEdit;
  final bool shoCaptions;
  final String endPoint;
  final List<Photo> photos;
  final int webUrlMaxLength;
  final double height;
  final double width;
  final int imageIndex = 0;
  final Color selectedColor;
  final Color unSelectedColor;

  const PhotoCarousel(
      {super.key,
      required this.photos,
      required this.endPoint,
      this.canEdit = false,
      this.shoCaptions = false,
      this.webUrlMaxLength = 40,
      this.height = 175,
      this.width = 0,
      this.selectedColor = Colors.blueAccent,
      this.unSelectedColor = Colors.grey});

  Widget buildIndicator(BuildContext context, int index) {
    return SizedBox(
      width: photos.length * 20,
      child: Row(
        children: List.generate(
          photos.length,
          (index) => Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color:
                        index == imageIndex ? selectedColor : unSelectedColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: height > 0 ? height : null,
        width: width > 0 ? width : null,
        child: ReorderableListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (Photo photo in photos)
              if (photo.url.length > webUrlMaxLength) ...[
                showLocalImage(photo.url, index: photo.index)
              ] else ...[
                showWebImage(
                  context: context,
                  Uri.parse('$endPoint/${photo.url}').toString(),
                  // canDelete: true,
                  index: photo.index,
                  onDelete: (idx) => onDeleteImage(idx),
                ), //        {debugPrint('onDelete $idx')})
              ]
          ],
          onReorder: (int oldIndex, int newIndex) {
            //    setState(
            //      () {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final Photo item = photos.removeAt(oldIndex);
            photos.insert(newIndex, item);
            //      List<String> urls = [
            //        for (Photo photo in photos) photo.toMapString()
            //      ];
            //    widget.homeItem.imageUrl = urls.toString();
            //    debugPrint('reordered: ${widget.homeItem.imageUrl}');
            //       },
            //     );
          },
        ),
      ),
      SizedBox(
          height: 30,
          child: Align(
            child: buildIndicator(context, imageIndex),
          ))
    ]);
    //   children: List.generate(
    //     starCount,
    //     (index) => buildStar(context, index),
    //   ),
    // );
  }
}

onDeleteImage(int index) {}

deleteWebImage(String url) {}

Widget showWebImage(String imageUrl,
    {BuildContext? context,
    double width = 200,
    int index = -1,
    Function(int)? onDelete}) {
  return SizedBox(
    key: Key('swi$index'),
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onDoubleTap: () async {
          if (onDelete != null && index > -1) {
            if (context != null) {
              bool? canDelete = await showDialog<bool>(
                context: context,
                builder: (context) => const OkCancelAlert(
                  title: 'Remove image?',
                  message: 'Deletes image on server ',
                ),
              );
              if (canDelete!) {
                deleteWebImage(imageUrl);
                onDelete(index);
              }
            } else {
              deleteWebImage(imageUrl);
              onDelete(index);
            }
          }
        },
        //  String imageUrl = 'http://10.101.1.150:5001/v1/shop_item/images/0673901ecf1e761f8000b9ac02b722d7/6eec1ec3-2c5b-4d7e-9c3b-5a28d1016bd9.jpg';
        child: Image.network(
          imageUrl,
          //   "http://10.101.1.150:5001/v1/shop_item/images/0673901ecf1e761f8000b9ac02b722d7/6eec1ec3-2c5b-4d7e-9c3b-5a28d1016bd9.jpg", //imageUrl,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
        ),
      ),
    ),
  );
}

Widget showLocalImage(String url, {index = -1}) {
  return SizedBox(
      key: Key('sli$index'), width: 160, child: Image.file(File(url)));
}
