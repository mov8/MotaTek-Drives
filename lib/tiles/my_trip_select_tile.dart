import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/models/my_trip_item.dart';

class MyTripSelectTile extends StatefulWidget {
  final MyTripItem myTripItem;
  final Future<void> Function(int) onLoadTrip;
  final Future<void> Function(int) onShareTrip;
  final Future<void> Function(int) onDeleteTrip;
  final Future<void> Function(int)? onPublishTrip;
  final void Function(int, bool)? onExpandChange;
  final int index;
  const MyTripSelectTile({
    super.key,
    required this.index,
    required this.myTripItem,
    required this.onLoadTrip,
    required this.onShareTrip,
    required this.onDeleteTrip,
    this.onPublishTrip,
    this.onExpandChange,
  });

  @override
  State<MyTripSelectTile> createState() => _myTripSelectTileState();
}

class _myTripSelectTileState extends State<MyTripSelectTile> {
  @override
  Widget build(BuildContext context) {
    List<Photo> photos = photosFromJson(widget.myTripItem.getImages());
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          title: Column(children: [
            Row(children: [
              Expanded(
                flex: 1,
                child: Text(
                  widget.myTripItem.getHeading(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                flex: 8,
                child: Text(
                  widget.myTripItem.getPublishedDate(
                      noPrompt: 'not yet published - will be if chosen'),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Row(children: [
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.route),
                    Text('${widget.myTripItem.getDistance()} miles long')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.landscape),
                    Text(
                        '${widget.myTripItem.pointsOfInterest().length} highlights')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.social_distance),
                    Text('${widget.myTripItem.getClosest()} miles away')
                  ]),
                ),
              ]),
            )
          ]),
          onExpansionChanged: (expanded) {
            widget.onExpandChange!(widget.index, expanded);
          },
          children: [
            SizedBox(
              // height: 200,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              widget.myTripItem.getSubHeading(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (widget.myTripItem.getImages().isNotEmpty)
                        Row(children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: SizedBox(
                              height: 200,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (int i = 0; i < photos.length; i++)
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          child: Image.file(
                                            File(photos[i].url),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        )
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          )
                        ]),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(widget.myTripItem.getBody(),
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                textAlign: TextAlign.left),
                          ),
                        ),
                      ),
                      if (widget.myTripItem.showMethods) ...[
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                            child: Row(children: [
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: () async =>
                                      widget.onShareTrip(widget.index),
                                  child: const Column(children: [
                                    Icon(Icons.directions_car_outlined),
                                    Text('Group Trip')
                                  ]),
                                ),
                              ),
                              if (widget.myTripItem.getPublished().isEmpty) ...[
                                Expanded(
                                  flex: 1,
                                  child: TextButton(
                                    onPressed: () async =>
                                        widget.onPublishTrip!(widget.index),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.cloud_upload_outlined),
                                        Text('Publish Trip')
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
