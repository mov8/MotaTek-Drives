import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/universal_io.dart';
import 'dart:math';
import 'dart:async';
import 'dart:developer' as developer;
import '/models/models.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '/helpers/helpers.dart';

class ImageArranger extends StatefulWidget {
  final Function(String) urlChange;
  final Function(int)? onChange;
  final bool showCaptions;
  final String endPoint;
  final String imageUrl;
  final List<Photo> photos;
  final ImageRepository? imageRepository;
  final double height;

  ImageArranger({
    super.key,
    required this.urlChange,
    required this.photos,
    this.imageRepository,
    this.endPoint = '',
    this.imageUrl = '',
    this.showCaptions = false,
    this.height = 125, //175,
    this.onChange,
  });

  @override
  State<ImageArranger> createState() => _ImageArrangerState();
}

class _ImageArrangerState extends State<ImageArranger> {
  int imageIndex = 0;
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
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
              for (int i = 0;
                  i < widget.photos.length;
                  i++) //(Photo photo in widget.photos)
                Padding(
                  key: Key('trp$i'), //{photo.index}'),
                  padding: EdgeInsetsGeometry.fromLTRB(0, 10, 10, 10),
                  child: InkWell(
                    key: Key('tr${widget.photos[i].index}'),
                    onTap: () {
                      if (widget.onChange != null) {
                        widget.onChange!(widget.photos[i].index);
                      }
                      imageIndex = widget.photos[i].index;
                      setState(() => _captionController.text =
                          widget.photos[imageIndex].caption);
                    },
                    child: Transform.rotate(
                      angle: pi * widget.photos[i].rotation * 0.5,
                      child: widget.photos[i].url.contains('http')
                          ? showWebImage(
                              context: context,
                              Uri.parse(widget.photos[i].url).toString(),
                              index: widget.photos[i].index,
                              onDelete: (idx) => onDeleteImage(idx),
                            )
                          : FutureBuilder<Image>(
                              future: getImage(
                                  url: widget.photos[i].url,
                                  cacheKey: widget.photos[i].key),
                              builder: (BuildContext context,
                                  AsyncSnapshot<Image> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return ImageMissing(
                                      width: 50,
                                    );
                                  case ConnectionState.waiting:
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  default:
                                    if (snapshot.hasError) {
                                      return ImageMissing(
                                        width: 50,
                                      );
                                    } else {
                                      return snapshot.data as Image;
                                    }
                                }
                              },
                            ),
                    ),
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
                    controller: _captionController,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.start,
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.sentences,
                    style: textStyle(
                        context: context, color: Colors.black, size: 2),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Image caption',
                      hintStyle: hintStyle(context: context),
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
                            if (!kIsWeb) {
                              if (File(widget.photos[imageIndex].url)
                                  .existsSync()) {
                                File(widget.photos[imageIndex].url)
                                    .deleteSync();
                              }
                            }
                            widget.photos.removeAt(imageIndex);
                            updateWidgetUris();
                          }
                        },
                        icon: Icon(Icons.delete_outlined),
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (text) {
                      widget.photos[imageIndex].caption = text;
                      debugPrint(
                          'index: $imageIndex caption is: ${widget.photos[imageIndex].caption}');
                    },
                  ),
                  //body = text
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  updateWidgetUris() {
    String urlString = '';
    if (widget.photos.isNotEmpty) {
      List<String> urls = [
        for (Photo photo in widget.photos) photo.toMapString()
      ];
      urlString = urls.toString();
    }
    setState(() => widget.urlChange(urlString));
    debugPrint('urls: $urlString');
  }

  onDeleteImage(int idx) {
    widget.photos.removeAt(idx);
    setState(() => updateWidgetUris());
  }

  Future<Image> getImage({String url = '', String? cacheKey}) async {
    if (url.contains('assets/images')) {
      return Image(
        image: AssetImage(url),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const ImageMissing(width: 30);
        },
      );
    } else if (widget.imageRepository != null) {
      cacheKey ??= getFileName(url: url);
      Map<String, dynamic> cachedImage =
          await widget.imageRepository!.loadImage(key: cacheKey);
      return cachedImage[cacheKey];
    } else {
      return Image.file(
        File(url),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const ImageMissing(width: 30);
        },
      );
    }
  }
}
