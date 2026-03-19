import 'package:flutter/material.dart';
import '/classes/classes.dart';
import 'package:latlong2/latlong.dart';
import '/constants.dart';
import '/models/other_models.dart';
import '/helpers/edit_helpers.dart';
import '/tiles/tiles.dart';
import '/services/services.dart';
import 'dart:developer' as developer;

class TripTile extends StatefulWidget {
  final TripItem tripItem;
  final ImageRepository imageRepository;
  final Function(int, String)? onGetTrip;
  final Function(int, int)? onRatingChanged;
  final Function(int)? onExpand;
  bool expanded;

  final int index;

  TripTile({
    super.key,
    required this.tripItem,
    required this.imageRepository,
    required this.index,
    this.onGetTrip,
    this.onRatingChanged,
    this.onExpand,
    this.expanded = false,
  });

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  List<Photo> photos = [];
  // String _photoString = '';
  bool isExpanded = false;
  bool expanded = true;
  late List<Card> _childCards;
  @override
  void initState() {
    super.initState();
    _childCards = [];
    expanded = widget.expanded;
    photos = photosFromJson(
        photoString: widget.tripItem.imageUrls,
        endPoint: '${widget.tripItem.uri}/');
  }

  expandChange({required bool expanded}) async {
    try {
      if (expanded) {
        await getDetails();
        widget.expanded = true;
        if (mounted) {
          setState(() => ());
        }
        if (widget.onExpand != null) {
          widget.onExpand!(widget.index);
        }
      } else {
        //  _expansionTileController.collapse();
      }
      //  setState(() => isExpanded = expanded);
    } catch (e) {
      debugPrint('Error tripTile expandChange: ${e.toString()} ');
    }
  }

  getDetails() async {
    if (_childCards.isEmpty) {
      var details = await getTripDetails(uuid: widget.tripItem.driveUri);
      widget.tripItem.body = details["body"];
      widget.tripItem.subTitle = details["sub_title"];
      for (int i = 0; i < details["points_of_interest"].length; i++) {
        Map<String, dynamic> poi = details["points_of_interest"][i];
        PointOfInterest pointOfInterest = PointOfInterest(
          type: poi["type"],
          //  point: LatLng(poi["lat"], poi["lng"]),
          name: poi["name"],
          description: poi["description"],
          // imageUrls: poi["images"],
        );
        _childCards.add(
          Card(
            child: PointOfInterestTile(
                index: i,
                canEdit: false,
                pointOfInterest: pointOfInterest,
                imageRepository: widget.imageRepository),
          ),
        );
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    /*
    if (widget.tripItem.imageUrls != _photoString) {
      photos = photosFromJson(
          photoString: widget.tripItem.imageUrls, endPoint: '$urlDriveImages/');
      _photoString = widget.tripItem.imageUrls;
    }
    */

    return ExpansionTile(
      title: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(
              widget.tripItem.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => getTrip(widget.index),
                      child: Row(children: [
                        IconButton(
                          onPressed: () => getTrip(widget.index),
                          icon: Icon(
                            Icons.cloud_download_outlined,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Download',
                          style: textStyle(
                              context: context, color: Colors.black, size: 2),
                        ),
                      ]),
                    ),
                    Expanded(
                      flex: 6,
                      child: StarRating(
                          onRatingChanged: changeRating,
                          rating: widget.tripItem.score),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      initiallyExpanded: expanded,
      onExpansionChanged: (value) => expandChange(expanded: value),
      leading: Icon(Icons.route,
          size: 25, color: colourList[Setup().publishedTripColour]),
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (widget.tripItem.imageUrls.isNotEmpty)
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            // height: 350,
                            child: PhotoCarousel(
                              imageRepository: widget.imageRepository,
                              photos: widget.tripItem.photos,
                              height: 300,
                              width: MediaQuery.of(context).size.width - 50,
                            ),
                          ),
                        )
                      ],
                    ),
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
                          Text(
                            widget.tripItem.added,
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          )
                        ]),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(children: [
                          const Icon(Icons.route),
                          Text(
                            widget.tripItem.distance.toStringAsFixed(1),
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            'miles long',
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                        ]),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(children: [
                          const Icon(Icons.landscape),
                          Text(
                            widget.tripItem.pointsOfInterestCount.toString(),
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            ' highlights',
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          )
                        ]),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(children: [
                          const Icon(Icons.social_distance),
                          Text(
                            (widget.tripItem.distanceAway * metersToMiles)
                                .toString(),
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          ),
                          Text(
                            'miles away',
                            style: textStyle(
                                context: context, color: Colors.black, size: 3),
                          )
                        ]),
                      ),
                    ]),
                  ),
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          widget.tripItem.subTitle,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
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
                    ),
                  ),
                  if (widget.tripItem.author.isNotEmpty)
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                    getInitials(name: widget.tripItem.author)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 7,
                              child: Text(widget.tripItem.author,
                                  style: textStyle(
                                      context: context, color: Colors.black)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.group_add),
                                    onPressed: () => (setState(() {})),
                                  ),
                                  //   const Text('follow'),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  if (_childCards.isNotEmpty)
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text('Points of interest...',
                              style: titleStyle(
                                  context: context, color: Colors.black)),
                        ),
                      ],
                    ),
                  ..._childCards,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  changeRating(value) {
    if (widget.tripItem.uri.isNotEmpty) {
      putDriveRating(widget.tripItem.uri, value);
      if (widget.onRatingChanged != null) {
        widget.onRatingChanged!(value, widget.index);
      }
      setState(() => widget.tripItem.score = value.toDouble());
    }
  }

  getTrip(value) {
    if (widget.onGetTrip != null) {
      widget.onGetTrip!(widget.index, widget.tripItem.uri);
    }
  }
}
