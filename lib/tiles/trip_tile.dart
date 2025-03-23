import 'package:flutter/material.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';
import 'package:drives/models/other_models.dart';
//import 'package:drives/tiles/tiles.dart';
import 'package:drives/services/services.dart';

class TripTile extends StatefulWidget {
  final TripItem tripItem;
  final ImageRepository imageRepository;
  final Function(int)? onGetTrip;
  final Function(int, int)? onRatingChanged;
  final ExpandNotifier? expandNotifier;
  final List<Card>? childCards;

  final int index;

  const TripTile({
    super.key,
    required this.tripItem,
    required this.imageRepository,
    required this.index,
    this.onGetTrip,
    this.onRatingChanged,
    this.expandNotifier,
    this.childCards,
  });

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  List<Photo> photos = [];
  String _photoString = '';
  bool isExpanded = false;
  late ExpandNotifier _expandNotifier;
  late final ExpansionTileController _expansionTileController; // =
  //ExpansionTileController();

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
    if (mounted) {
      expandChange(expanded: index == target);
    } else {
      debugPrint('_setExpanded not mounted index: $index  target: $target');
    }
  }

  expandChange({required bool expanded}) {
    try {
      if (expanded) {
        _expansionTileController.expand();
      } else {
        _expansionTileController.collapse();
      }
      setState(() => isExpanded = expanded);
    } catch (e) {
      debugPrint('Error tripTile expandChange: ${e.toString()} ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripItem.imageUrls != _photoString) {
      photos = photosFromJson(widget.tripItem.imageUrls,
          endPoint: '$urlDriveImages/');
      _photoString = widget.tripItem.imageUrls;
    }
    return ExpansionTile(
      controller: _expansionTileController,
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
          Row(
            children: [
              Expanded(
                flex: 1,
                child: StarRating(
                    onRatingChanged: changeRating,
                    rating: widget.tripItem.score),
              ),
              if (isExpanded)
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ActionChip(
                      visualDensity:
                          const VisualDensity(horizontal: 0.0, vertical: 0.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      label: Text(
                        'Download',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black,
                      onPressed: () =>
                          getTrip(widget.index), //widget.onGetTrip,
                      avatar: Icon(Icons.cloud_download_outlined,
                          size: 20, color: Colors.black),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.publish),
                        Text(widget.tripItem.published),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      onExpansionChanged: (expanded) => expandChange(expanded: expanded),
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
                    Row(
                      children: <Widget>[
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
                          Text('${widget.tripItem.pointsOfInterest} highlights')
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
                                child: Text(
                                    getInitials(name: widget.tripItem.author)),
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
                  /* SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: ActionChip(
                                visualDensity: const VisualDensity(
                                    horizontal: 0.0, vertical: 0.5),
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                label: Text('Download trip',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white)),
                                elevation: 5,
                                shadowColor: Colors.black,
                                onPressed: () => {},
                                avatar: Icon(Icons.cloud_download,
                                    size: 20, color: Colors.white)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => setState(() {
                                  getTrip(widget.index);
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

                        /*
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
                        ), */

                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => (setState(() {})),
                          ),
                        )
                      ]),
                    ),
                  ), */
                  if (widget.childCards != null)
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            'Points of interest...',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  if (widget.childCards != null) ...widget.childCards!,
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
      widget.onGetTrip!(widget.index);
    }
  }
}
