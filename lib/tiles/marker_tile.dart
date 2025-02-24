import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart';

import 'package:drives/classes/classes.dart'; //star_ratings.dart';

class MarkerTile extends StatefulWidget {
  final int index;
  final Function onRated;
  final bool expanded;
  final bool canEdit;
  String name;
  String description;
  String images;
  String url;
  List<String> imageUrls;
  int type;
  double score;
  int scored;

  MarkerTile({
    super.key,
    required this.index,
    this.name = '',
    this.description = '',
    this.images = '',
    this.url = '',
    this.imageUrls = const [],
    this.type = 0,
    this.score = 0,
    this.scored = 0,
    required this.onRated,
    this.expanded = false,
    this.canEdit = true,
  });
  @override
  State<MarkerTile> createState() => _MarkerTileState();
}

class _MarkerTileState extends State<MarkerTile> {
  late int index;
  bool expanded = true;
  bool canEdit = true;
  double score = 0;
  int scored = 0;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
    canEdit = widget.canEdit;
    index = widget.index;
    getRating(); //widget.score;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('$widget.key'),
      child: ExpansionTile(
        controller: ExpansionTileController(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        title: Text(
          '${poiTypes[widget.type]['name']}',
          style: const TextStyle(fontSize: 16),
        ),
        collapsedBackgroundColor: widget.index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        backgroundColor: Colors.white,
        initiallyExpanded: expanded,
        leading: IconButton(
          iconSize: 25,
          icon: Icon(
            markerIcon(
              widget.type,
            ),
          ),
          onPressed: () => {},
        ),
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Text(
                          widget.description.isEmpty
                              ? 'No description'
                              : widget.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.imageUrls.isNotEmpty && widget.url.isNotEmpty)
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 8,
                        child: SizedBox(
                          width: 200,
                          height: 175,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.imageUrls.length,
                              itemBuilder: (BuildContext context, int index) {
                                return showWebImage(widget.imageUrls[index]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                        child: Row(
                          children: [
                            StarRating(
                                onRatingChanged: changeRating, rating: score),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '($scored)',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 15),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10)
              ],
            ),
          )
        ],
      ),
    );
  }

  expand(bool state, bool canEdit) {
    expanded = state;
  }

  getRating() async {
    getPointOfInterestRating(widget.url).then((ratingMap) {
      setState(() {
        score = ratingMap['rating'];
        scored = ratingMap['scored'];
      });
    });
  }

  changeRating(value) {
    setState(() => score = value.toDouble());
    putPointOfInterestRating(widget.url, value);
  }
}

//https://nominatim.openstreetmap.org/search/?q=staines&format=json
//https://nominatim.openstreetmap.org/search?addressdetails=1&q=bakery+in+berlin+wedding&format=jsonv2&limit=1
//https://nominatim.org/release-docs/latest/api/Search/