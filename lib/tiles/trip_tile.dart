import 'package:drives/utilities.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';
import 'package:drives/screens/star_ratings.dart';
// import 'dart:io';

class TripTile extends StatefulWidget {
  final TripItem tripItem;

  const TripTile({
    super.key,
    required this.tripItem,
  });

  @override
  State<TripTile> createState() => _tripTileState();
}

class _tripTileState extends State<TripTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Card(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (widget.tripItem.imageUrls.isNotEmpty)
                            Row(children: <Widget>[
                              Expanded(
                                  flex: 8,
                                  child: SizedBox(
                                      height: 200,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          for (int i = 0;
                                              i <
                                                  widget.tripItem.imageUrls
                                                      .length;
                                              i++)
                                            SizedBox(
                                                width: 200,
                                                child: Image(
                                                    image: AssetImage(widget
                                                        .tripItem
                                                        .imageUrls[i]))),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                        ],
                                      )))
                            ]),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                              child: Row(children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.publish),
                                    Text('from ${widget.tripItem.published}')
                                  ]),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.route),
                                    Text(
                                        '${widget.tripItem.distance} miles long')
                                  ]),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.landscape),
                                    Text(
                                        '${widget.tripItem.pointsOfInterest} highlights')
                                  ]),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.social_distance),
                                    Text(
                                        '${widget.tripItem.closest} miles away')
                                  ]),
                                ),
                              ])),
                          SizedBox(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 0, 5, 10),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(widget.tripItem.heading,
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.left),
                                  ))),
                          SizedBox(
                            child: Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    widget.tripItem.subHeading,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                  ),
                                )),
                          ),
                          SizedBox(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(widget.tripItem.body,
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 20),
                                  textAlign: TextAlign.left),
                            ),
                          )),
                          if (widget.tripItem.author != '')
                            SizedBox(
                                child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(5, 0, 5, 15),
                                    child: Row(children: [
                                      Expanded(
                                          flex: 1,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            child: Text(getInitials(
                                                name: widget.tripItem.author)),
                                          )),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          flex: 7,
                                          child: Text(widget.tripItem.author,
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 20))),
                                      Expanded(
                                          flex: 2,
                                          child: Column(children: [
                                            IconButton(
                                                icon:
                                                    const Icon(Icons.group_add),
                                                onPressed: () =>
                                                    (setState(() {}))),
                                            //   const Text('follow'),
                                          ]))
                                    ]))),
                          SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                              child: Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(children: [
                                      IconButton(
                                          icon: const Icon(Icons.download),
                                          onPressed: () => (setState(() {}))),
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                            '(${widget.tripItem.downloads})',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15)),
                                      ),
                                    ])),
                                Expanded(
                                    flex: 3,
                                    child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 0, 5, 0),
                                        child: Row(children: [
                                          StarRating(
                                              onRatingChanged: changeRating,
                                              rating: widget.tripItem.score),
                                          Align(
                                              alignment: Alignment.topLeft,
                                              child: Text(
                                                  '(${widget.tripItem.scored})',
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15)))
                                        ]))),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () => (setState(() {}))),
                                )
                              ]),
                            ),
                          ),
                        ])))));
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
