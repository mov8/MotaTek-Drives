//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/other_models.dart';

class MyTripTile extends StatefulWidget {
  final MyTripItem myTripItem;
  final Future<void> Function(int) onLoadTrip;
  final Future<void> Function(int) onShareTrip;
  final Future<void> Function(int) onDeleteTrip;
  final Future<void> Function(int)? onPublishTrip;
  final void Function(bool)? onExpandChange;
  final int index;
  const MyTripTile({
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
  State<MyTripTile> createState() => _MyTripTileState();
}

class _MyTripTileState extends State<MyTripTile> {
  @override
  Widget build(BuildContext context) {
    List<Photo> photos = photosFromJson(widget.myTripItem.images);
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          title: Column(children: [
            Row(children: [
              Expanded(
                flex: 8,
                child: Text(
                  widget.myTripItem.heading,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                    Text('${widget.myTripItem.distance} miles long')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.landscape),
                    Text(
                        '${widget.myTripItem.pointsOfInterest.length} highlights')
                  ]),
                ),
                Expanded(
                  flex: 1,
                  child: Column(children: [
                    const Icon(Icons.social_distance),
                    Text('${widget.myTripItem.closest} miles away')
                  ]),
                ),
              ]),
            )
          ]),
          // backgroundColor: Colors.white,
          onExpansionChanged: (expanded) {
            if (widget.onExpandChange != null) {
              widget.onExpandChange!(expanded);
            }
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
                              widget.myTripItem.subHeading,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (widget.myTripItem.images.isNotEmpty)
                        Row(children: <Widget>[
                          Expanded(
                            flex: 8,
                            child: SizedBox(
                              height: 200,
                              child: ImageArranger(
                                urlChange: (_) => {},
                                photos: photos,
                                endPoint: widget.myTripItem.driveUri,
                              ),
                            ),
                          ),
                          /*
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

                              */
//),
                          //)
                        ]),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              widget.myTripItem.body,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 20),
                              textAlign: TextAlign.left,
                            ),
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
                                      widget.onLoadTrip(widget.index),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.file_open_outlined),
                                      Text('Start Trip')
                                    ],
                                  ),
                                ),
                              ),
                              /* Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: () async =>
                                      widget.onShareTrip(widget.index),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.directions_car_outlined),
                                      Text('Group Trip')
                                    ],
                                  ),
                                ),
                              ), */
                              if (widget.onPublishTrip != null) ...[
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
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: () async =>
                                      widget.onDeleteTrip(widget.index),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.delete_forever),
                                      Text('Delete Trip')
                                    ],
                                  ),
                                ),
                              )
                            ]),
                          ),
                        ),
                      ]
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
