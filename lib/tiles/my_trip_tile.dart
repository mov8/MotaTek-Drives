// import 'dart:convert';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';

class MyTripTile extends StatefulWidget {
  final MyTripItem myTripItem;
  // final AsyncCallback onLoadTrip;
  final Future<void> Function(int) onLoadTrip;
  final Future<void> Function(int) onShareTrip;
  final Future<void> Function(int) onDeleteTrip;
  final Future<void> Function(int)? onPublishTrip;
  final int index;
  const MyTripTile({
    super.key,
    required this.index,
    required this.myTripItem,
    required this.onLoadTrip,
    required this.onShareTrip,
    required this.onDeleteTrip,
    this.onPublishTrip,
  });

  @override
  State<MyTripTile> createState() => _myTripTileState();
}

class _myTripTileState extends State<MyTripTile> {
  @override
  Widget build(BuildContext context) {
    List<Photo> photos = photosFromJson(widget.myTripItem.getImages());
    return SingleChildScrollView(
        child: Material(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                //   child: Container(
                /*
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
              */
                child: ExpansionTile(
                    //   collapsedShape: const RoundedRectangleBorder(
                    //       side: BorderSide(style: BorderStyle.solid),
                    //       borderRadius: BorderRadius.all(Radius.circular(10))),
                    title: Column(children: [
                      Row(children: [
                        /* const Expanded(
                            flex: 5,
                            child: SizedBox(
                                width: 200,
                                child: Image(
                                    image:
                                        AssetImage('assets/images/map.png')))),
                                        */
                        Expanded(
                            flex: 8,
                            child: Text(widget.myTripItem.getHeading(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold))),
                      ]),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                          child: Row(children: [
                            Expanded(
                              flex: 1,
                              child: Column(children: [
                                const Icon(Icons.route),
                                Text(
                                    '${widget.myTripItem.getDistance()} miles long')
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
                                Text(
                                    '${widget.myTripItem.getClosest()} miles away')
                              ]),
                            ),
                          ]))
                    ]),
                    backgroundColor: Colors.white,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        // _scrollReorderListView = expanded;
                      });
                    },
                    children: [
                      SizedBox(
                          // height: 200,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                              child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      5, 0, 5, 10),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  widget.myTripItem
                                                      .getSubHeading(),
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.left,
                                                ),
                                              )),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        if (widget.myTripItem
                                            .getImages()
                                            .isNotEmpty)
                                          Row(children: <Widget>[
                                            Expanded(
                                                flex: 8,
                                                child: SizedBox(
                                                    height: 200,
                                                    child: ListView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      children: [
                                                        for (int i = 0;
                                                            i < photos.length;
                                                            i++)
                                                          Row(children: [
                                                            SizedBox(
                                                                width: 200,
                                                                child: Image.file(
                                                                    File(photos[
                                                                            i]
                                                                        .url))),
                                                            const SizedBox(
                                                              width: 20,
                                                            )
                                                          ]),
                                                      ],
                                                    )))
                                          ]),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                            child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 0, 5, 10),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                                widget.myTripItem.getBody(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20),
                                                textAlign: TextAlign.left),
                                          ),
                                        )),
                                        if (widget.myTripItem.showMethods) ...[
                                          SizedBox(
                                              child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 0, 5, 10),
                                            child: Row(children: [
                                              Expanded(
                                                flex: 1,
                                                // alignment: Alignment.topLeft,
                                                child: TextButton(
                                                  onPressed: () async => widget
                                                      .onLoadTrip(widget.index),
                                                  child: const Column(
                                                      children: [
                                                        Icon(Icons
                                                            .file_open_outlined),
                                                        Text('Load Trip')
                                                      ]),

                                                  // icon: const Icon(Icons.upload),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                // alignment: Alignment.topLeft,
                                                child: TextButton(
                                                  onPressed: () async =>
                                                      widget.onShareTrip(
                                                          widget.index),
                                                  child: const Column(
                                                      children: [
                                                        Icon(Icons
                                                            .directions_car_outlined),
                                                        Text('Group Trip')
                                                      ]),

                                                  // icon: const Icon(Icons.upload),
                                                ),
                                              ),
                                              if (widget.onPublishTrip !=
                                                  null) ...[
                                                Expanded(
                                                  flex: 1,
                                                  // alignment: Alignment.topLeft,
                                                  child: TextButton(
                                                    onPressed: () async =>
                                                        widget.onPublishTrip!(
                                                            widget.index),
                                                    child: const Column(
                                                        children: [
                                                          Icon(Icons
                                                              .cloud_upload_outlined),
                                                          Text('Publish Trip')
                                                        ]),

                                                    // icon: const Icon(Icons.upload),
                                                  ),
                                                )
                                              ],
                                              Expanded(
                                                flex: 1,
                                                // alignment: Alignment.topLeft,
                                                child: TextButton(
                                                  onPressed: () async =>
                                                      widget.onDeleteTrip(
                                                          widget.index),
                                                  child:
                                                      const Column(children: [
                                                    Icon(Icons.delete_forever),
                                                    Text('Delete Trip')
                                                  ]),

                                                  // icon: const Icon(Icons.upload),
                                                ),
                                              )
                                            ]),
                                          )),
                                        ]
                                      ]))))
                    ]) /*)*/)));
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
