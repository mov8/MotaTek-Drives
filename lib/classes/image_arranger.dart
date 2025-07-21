import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:drives/models/models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';

class ImageArranger extends StatefulWidget {
  final Function(String) urlChange;
  final Function(int)? onChange;
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
    this.onChange,
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
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (Photo photo in widget.photos)
                InkWell(
                  key: Key('tr${photo.index}'),
                  onTap: () {
                    if (widget.onChange != null) {
                      widget.onChange!(photo.index);
                      imageIndex = photo.index;
                      developer.log('InkWell onTap image: ${photo.index}',
                          name: '_image');
                    }
                  },
                  child: Transform.rotate(
                    angle: pi * photo.rotation * 0.5,
                    child: photo.url.contains('http')
                        ? showWebImage(
                            context: context,
                            Uri.parse(photo.url).toString(),
                            index: photo.index,
                            onDelete: (idx) => onDeleteImage(idx),
                          )
                        : showLocalImage(photo.url, index: photo.index),
                  ),
                ),
            ],
            onReorder: (int oldIndex, int newIndex) {
              setState(
                () {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final Photo item = widget.photos.removeAt(oldIndex);
                  widget.photos.insert(newIndex, item);
                  updateWidgetUris();
                },
              );
            },
          ),
        ),
        if (widget.showCaptions) ...[
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                  child: TextFormField(
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      //     expands: true,
                      initialValue: widget.photos[imageIndex].caption,
                      textAlign: TextAlign.start,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Image caption',
                          labelText: 'Image ${imageIndex + 1} caption',
                          prefixIcon: IconButton(
                            onPressed: () => setState(() {
                              widget.photos[imageIndex].rotation =
                                  widget.photos[imageIndex].rotation < 3
                                      ? ++widget.photos[imageIndex].rotation
                                      : 0;
                              updateWidgetUris();
                            }),
                            icon: Icon(Icons.rotate_90_degrees_cw_outlined),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              if (widget.photos.isNotEmpty) {
                                widget.photos.removeAt(imageIndex);
                                updateWidgetUris();
                              }
                            },
                            icon: Icon(Icons.delete_outlined),
                          )),
                      style: Theme.of(context).textTheme.bodyLarge,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (text) =>
                          (widget.photos[imageIndex].caption = text)
                      //body = text
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  updateWidgetUris() {
    List<String> urls = [
      for (Photo photo in widget.photos) photo.toMapString()
    ];
    widget.urlChange(urls.toString());
  }

  onDeleteImage(int idx) {
    widget.photos.removeAt(idx);
    setState(() => updateWidgetUris());
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
