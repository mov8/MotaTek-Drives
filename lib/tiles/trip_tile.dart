import 'package:drives/classes/caches.dart';
import 'package:drives/classes/notifiers.dart';
import 'package:drives/classes/photo_carousel.dart';
import 'package:drives/classes/utilities.dart';
import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/star_ratings.dart';
// import 'package:drives/services/web_helper.dart';

class TripTile extends StatefulWidget {
  final TripItem tripItem;
  final ImageRepository imageRepository;
  final Future<void> Function(int) onGetTrip;
  final Function(int, int) onRatingChanged;
  final ExpandNotifier? expandNotifier;

  final int index;

  const TripTile({
    super.key,
    required this.tripItem,
    required this.imageRepository,
    required this.index,
    required this.onGetTrip,
    required this.onRatingChanged,
    this.expandNotifier,
  });

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  List<Photo> photos = [];
  String _photoString = '';
  bool isExpanded = false;
  late ExpandNotifier _expandNotifier;
  late final ExpansionTileController _expansionTileController;

  @override
  void initState() {
    super.initState();
    photos = photosFromJson(widget.tripItem.imageUrls,
        endPoint: '${widget.tripItem.uri}/');

    _expansionTileController = ExpansionTileController();
    _expandNotifier = widget.expandNotifier ?? ExpandNotifier(-1);
    _expandNotifier.addListener(() {
      _setExpanded(index: widget.index, target: _expandNotifier.value);
    });
  }

  _setExpanded({required int index, required int target}) {
    debugPrint('~~~~~ _setExpanded index: $index  target: $target');
    expandChange(expanded: index == target);
  }

  expandChange({required bool expanded}) {
    debugPrint(
        '+++ pointOfInterestTile[${widget.index}].expandChange(${expanded ? 'expand' : 'collapse'}) called');
    if (expanded) {
      _expansionTileController.expand();
    } else {
      _expansionTileController.collapse();
    }
    setState(() => isExpanded = expanded);
  }

//"[{"url": "d663bed13ef54cd386bc8e5582803c80/65e84e4ba58a49a7aa020a55a42c12db/bdb84cab-351c-48f0-ba4c-d6a46a560bc0.jpg", "caption"…"
  @override
  Widget build(BuildContext context) {
    if (widget.tripItem.imageUrls != _photoString) {
      photos = photosFromJson(widget.tripItem.imageUrls,
          //endPoint: '${widget.tripItem.uri}/');
          endPoint: '$urlDriveImages/');
      _photoString = widget.tripItem.imageUrls;
    }
    return ExpansionTile(
        title: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                widget.tripItem.heading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(children: [
              Expanded(
                flex: 1,
                child: StarRating(
                    onRatingChanged: () {}, rating: widget.tripItem.score),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('published ${widget.tripItem.published}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        ),
        leading: Icon(Icons.route_outlined,
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
                      Row(children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            // height: 350,
                            child: PhotoCarousel(
                              imageRepository: widget.imageRepository,
                              photos: photos,
                              height: 300,
                              width: MediaQuery.of(context).size.width - 50,
                            ),
                          ),
                        )
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
                            Text(widget.tripItem.published)
                          ]),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(children: [
                            const Icon(Icons.route),
                            Text('${widget.tripItem.distance} miles long')
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
                            Text('${widget.tripItem.closest} miles away')
                          ]),
                        ),
                      ]),
                    ),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(widget.tripItem.heading,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left),
                        ),
                      ),
                    ),
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
                                  child: Text(getInitials(
                                      name: widget.tripItem.author)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 7,
                                child: Text(
                                  widget.tripItem.author,
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 20),
                                ),
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
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                        child: Row(children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => setState(() {
                                    widget.onGetTrip(widget.index);
                                  }),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text('(${widget.tripItem.downloads})',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 15)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                              child: Row(
                                children: [
                                  StarRating(
                                      onRatingChanged: changeRating,
                                      rating: widget.tripItem.score),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      '(${widget.tripItem.scored})',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () => (setState(() {})),
                            ),
                          )
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]);
  }

  changeRating(value) {
    widget.onRatingChanged(value, widget.index);
  }
}
