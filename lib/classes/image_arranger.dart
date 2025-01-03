import 'package:flutter/material.dart';
import 'dart:io';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';

class ImageArranger extends StatefulWidget {
  final bool canEdit;
  final bool showCaptions;
  final String endPoint;
  String imageUrl;
  final List<Photo> photos;
  final int webUrlMaxLength;
  final double height;
  final double width;
  //int imageIndex = 0;
  final Color selectedColor;
  final Color unSelectedColor;

  ImageArranger(
      {super.key,
      required this.photos,
      required this.endPoint,
      this.imageUrl = '',
      this.canEdit = false,
      this.showCaptions = false,
      this.webUrlMaxLength = 40,
      this.height = 450,
      this.width = 0,
      this.selectedColor = Colors.blueAccent,
      this.unSelectedColor = Colors.grey});

  @override
  State<ImageArranger> createState() => _ImageArrangerState();
}

class _ImageArrangerState extends State<ImageArranger> {
  int imageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (Photo photo in widget.photos)
            if (photo.url.contains('http')) ...[
              showWebImage(
                context: context,
                Uri.parse('${widget.endPoint}/${photo.url}').toString(),
                // canDelete: true,
                index: photo.index,
                onDelete: (idx) => onDeleteImage(idx),
              ),
            ] else ...[
              showLocalImage(photo.url, index: photo.index),
            ]

          //  {debugPrint('onDelete $idx')}
        ],
        onReorder: (int oldIndex, int newIndex) {
          setState(
            () {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final Photo item = widget.photos.removeAt(oldIndex);
              widget.photos.insert(newIndex, item);
              List<String> urls = [
                for (Photo photo in widget.photos) photo.toMapString()
              ];
              widget.imageUrl = urls.toString();
              debugPrint('reordered: ${widget.imageUrl}');
            },
          );
        },
      ),
    );
  }

  onDeleteImage(int idx) {
    debugPrint('delete image $idx');
    setState(() => widget.photos.removeAt(idx));
  }

  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
      key: Key('sli$index'),

      width: 175,
      // height: 170,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: url.contains('assets/images')
            ? Image(
                image: AssetImage(url),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return const ImageMissing(width: 30);
                },
                //  width: 30,
              )
            : Image.file(
                File(url),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return const ImageMissing(width: 30);
                },
                // width: 30,
              ),
      ),
    );
  }
}
