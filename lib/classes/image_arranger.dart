import 'package:flutter/material.dart';
import 'dart:io';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';

class ImageArranger extends StatefulWidget {
  final Function(String) urlChange;
  final bool showCaptions;
  final String endPoint;
  final String imageUrl;
  final List<Photo> photos;
  final double height;

  const ImageArranger({
    super.key,
    required this.urlChange,
    required this.photos,
    required this.endPoint,
    this.imageUrl = '',
    this.showCaptions = false,
    this.height = 175,
  });

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
                Uri.parse(photo.url).toString(),
                index: photo.index,
                onDelete: (idx) => onDeleteImage(idx),
              ),
            ] else ...[
              showLocalImage(photo.url, index: photo.index),
            ]
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
              widget.urlChange(urls.toString());
              //  debugPrint('reordered: ${widget.imageUrl}');
            },
          );
        },
      ),
    );
  }

  onDeleteImage(int idx) {
    //   debugPrint('delete image $idx');
    setState(() => widget.photos.removeAt(idx));
  }

  Widget showLocalImage(String url, {index = -1}) {
    return SizedBox(
      key: Key('sli$index'),
      width: 175,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: url.contains('assets/images')
            ? Image(
                image: AssetImage(url),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return const ImageMissing(width: 30);
                },
              )
            : Image.file(
                File(url),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return const ImageMissing(width: 30);
                },
              ),
      ),
    );
  }
}
