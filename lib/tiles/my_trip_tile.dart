//import 'package:universal_io/universal_io.dart';
import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/helpers/helpers.dart';
import '/constants.dart';

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
    List<Photo> photos = photosFromJson(photoString: widget.myTripItem.images);
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          title: Column(
            children: [
              Row(children: [
                Expanded(
                  flex: 8,
                  child: Text(widget.myTripItem.heading,
                      style: headlineStyle(
                          context: context, color: Colors.black, size: 2)),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route),
                          Text(
                            'Distance',
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            '${widget.myTripItem.distance.toStringAsFixed(1)} miles',
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.landscape),
                          Text(
                            '${widget.myTripItem.pointsOfInterest.length}',
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            'highlights',
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.social_distance),
                          Text(
                            (widget.myTripItem.distanceAway * metersToMiles)
                                .toStringAsFixed(1),
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            'miles away',
                            style: labelStyle(
                                context: context, color: Colors.black, size: 3),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
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
                              style: titleStyle(
                                  context: context, color: Colors.black),
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
                              style: textStyle(
                                  context: context, color: Colors.black),
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
                                  child: Column(
                                    children: [
                                      Icon(Icons.file_open_outlined, size: 30),
                                      Text('Load Trip',
                                          style: textStyle(
                                              context: context,
                                              color: Colors.black,
                                              size: 3))
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.onPublishTrip != null) ...[
                                Expanded(
                                  flex: 1,
                                  child: TextButton(
                                    onPressed: () async =>
                                        widget.onPublishTrip!(widget.index),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 30,
                                        ),
                                        Text(
                                          'Publish Trip',
                                          style: labelStyle(
                                              context: context,
                                              color: Colors.black,
                                              size: 3),
                                        ),
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
                                  child: Column(
                                    children: [
                                      Icon(Icons.delete_forever, size: 30),
                                      Text(
                                        'Delete Trip',
                                        style: labelStyle(
                                            context: context,
                                            color: Colors.black,
                                            size: 3),
                                      )
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
