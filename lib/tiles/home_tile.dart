import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/models/models.dart';
import 'dart:developer' as developer;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '/helpers/helpers.dart';
import '/constants.dart';

/// The mobile version will need the data putting in tiles, as it has no space to show a summary
/// unlike the web version that uses the side drawer.
/// The web version needs a summary tile for the side drawer - the homeItemTile - analogous to the
/// TripTile
class HomeTile extends StatefulWidget {
  final HomeItem homeItem;
  final ImageRepository imageRepository;
  final double width;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const HomeTile({
    super.key,
    required this.homeItem,
    required this.imageRepository,
    this.width = 300,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  List<Map<String, dynamic>> _images = [];

  @override
  Widget build(BuildContext context) {
    return driveDetails();
  }

  Widget driveDetails() {
    double leftPadding = 0;
    // MediaQuery.of(context).size.width * (kIsWeb ? 0.38 : 0);
    String data = widget.homeItem.markdown;
    MdStyleSheet _styleSheet =
        MdStyleSheet.fromJson(json: widget.homeItem.style ?? {});
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding + 10, 5, 10, 5), //   all(8.0),
      child: // Card(
          ClipRRect(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(10.0)),
        child: Container(
          color: Colors.white, // const Color.fromRGBO(54, 143, 244, 0.411),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: SingleChildScrollView(
              child: /* Markdown(
                data: data,
              ),*/

                  MarkdownBody(
                data: data,
                styleSheet: _styleSheet.markdownStyleSheet,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
class HomeTile extends StatefulWidget {
  final HomeItem homeItem;
  final ImageRepository imageRepository;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const HomeTile({
    super.key,
    required this.homeItem,
    required this.imageRepository,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  List<Photo> photos = [];
  String endPoint = '';
  // String endPoint = '';

  @override
  void initState() {
    super.initState();
    photos = widget.homeItem.getPhotos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  child: Expanded(
                    child: PhotoCarousel(
                      imageRepository: widget.imageRepository,
                      photos: photos,
                      height: MediaQuery.of(context).size.width * .5, // 400,
                      width: MediaQuery.of(context).size.width * .5,
                    ),
                  ),
                ),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                    child: Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(widget.homeItem.heading,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                    child: Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          widget.homeItem.subHeading,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!Setup().hasLoggedIn) Row(children: []),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                    child: Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(widget.homeItem.body,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 20),
                            textAlign: TextAlign.left),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                    child: Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => (setState(() {}))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

*/
