import 'package:drives/services/services.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';

class OsmReviewTile extends StatefulWidget {
  final int index;
  final ImageRepository imageRepository;
  final List<dynamic> reviews;
  final String name;
  final String amenity;
  final String postcode;
  final int iconCodepoint;
  final Map<String, dynamic> reviewData;
  final String osmId;
  const OsmReviewTile(
      {super.key,
      required this.index,
      required this.imageRepository,
      this.reviewData = const {},
      this.reviews = const [],
      this.name = '',
      this.amenity = '',
      this.postcode = '',
      this.iconCodepoint = 0,
      this.osmId = ''});
  @override
  State<OsmReviewTile> createState() => _OsmReviewTileState();
}

class _OsmReviewTileState extends State<OsmReviewTile>
    with TickerProviderStateMixin {
  late TabController _tController;
  int _reviews = -1;
  late List<Photo> photos;

  @override
  void initState() {
    super.initState();
    _tController = TabController(length: 2, vsync: this);
    photos = [];
    //  WidgetsBinding.instance.addPostFrameCallback((_) {
    //    _reviews = widget.reviews.length;
    //    _tController.index = _reviews == 0 ? 1 : 0;
    //  });
  }

  @override
  void dispose() {
    _tController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reviews == -1) {
      _reviews = widget.reviews.length;
      _tController.index = _reviews == 0 ? 1 : 0;
    }
    return SingleChildScrollView(
        child: Column(
      children: [
        TabBar(
          controller: _tController,
          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
                icon: Icon(Icons.reviews_outlined),
                text: '$_reviews Review${_reviews == 1 ? '' : 's'}'),
            Tab(icon: Icon(Icons.star_rate_outlined), text: 'Add Review'),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height - 300,
          width: MediaQuery.of(context).size.width - 50,
          // SingleChildScrollView(
          child: TabBarView(
            controller: _tController,
            children: [
              reviews(),
              addReview(),
            ],
          ),
        ),
      ],
    ));
  }

  Widget reviews() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 400,
            width: 350,
            child: ListView.builder(
              itemCount: _reviews,
              itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                child: ExpansionTile(
                  expandedAlignment: Alignment.centerLeft,
                  title: Row(children: [
                    Expanded(
                      flex: 3,
                      child: StarRating(
                          onRatingChanged: (_) => (),
                          rating: widget.reviews[index]['rating']),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        widget.reviews[index]['rating'].toString(),
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                  subtitle: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(10, 0, 0, 0),
                      child: Text(
                          widget.reviews[index]['rated'].substring(0, 16),
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.start),
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(10, 0, 0, 0),
                        child: Text(widget.reviews[index]['comment'],
                            style: TextStyle(fontSize: 22),
                            textAlign: TextAlign.start),
                      ),
                    ),
                    PhotoCarousel(
                        width: 200,
                        height: 200,
                        photos: photosFromJson(
                            photoString: handleWebImages(
                                widget.reviews[index]['images']),
                            endPoint:
                                '$urlOsmReview/images/${widget.reviews[index]['amenity']}/${widget.reviews[index]['review_id']}/'),
                        imageRepository: widget.imageRepository),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(10, 0, 0, 0),
                        child: Text(widget.reviews[index]['rated_by'],
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.start),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget addReview() {
    return //SizedBox(
        // height: 600,
        // width: 250,
        // child:
        //   SingleChildScrollView(
        //  child:
        Column(
      //  mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Icon(
                IconData(widget.iconCodepoint, fontFamily: 'MaterialIcons'),
                color: Colors.black,
                size: 40,
              ),
            ),
            Expanded(
              flex: 8,
              child: Text(
                widget.amenity.replaceFirst(RegExp('_'), ' '),
                style: TextStyle(fontSize: 30),
              ),
            ),
          ],
        ),
        if (widget.reviews.isEmpty)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                  child: Text(
                    '${widget.name.contains('The') ? '' : 'The '}${widget.name} has not yet been rated. Review it now to help other people.',
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 20,
                      overflow: TextOverflow.ellipsis,
                    ), //, overflow: TextOverflow.visible),
                  ),
                ),
              ),
            ],
          ),
        Row(children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: TextFormField(
                    readOnly: false,
                    autofocus: true,
                    maxLines: 10,
                    minLines: 3,
                    textInputAction: TextInputAction.done,
                    initialValue: '',
                    textAlign: TextAlign.start,
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintMaxLines: 1,
                      hintText: 'Describe your experience ...',
                      labelText: 'My review',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (text) => widget.reviewData['comment'] = text,
                    onFieldSubmitted: (_) => ()) //body = text
                ),
          ),
        ]),
        Row(children: [
          Expanded(
            flex: 7,
            child: SizedBox(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ActionChip(
                  label: const Text(
                    'Image',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  avatar: const Icon(Icons.photo_album,
                      size: 20, color: Colors.white),
                  onPressed: () async {
                    widget.reviewData['imageUrls'] = await loadDeviceImage(
                        imageUrls: widget.reviewData['imageUrls'] ?? '');
                    setState(() => photos = photosFromJson(
                        photoString: widget.reviewData['imageUrls']));
                  },
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: StarRating(
                onRatingChanged: (val) => setState(
                    () => widget.reviewData['rating'] = val.toDouble()),
                rating: widget.reviewData['rating'] ?? 5),
          ),
        ]),
        SizedBox(height: 12),
        SizedBox(
          height: 200,
          width: 250,
          child: (photos.isNotEmpty)
              ? ImageArranger(
                  urlChange: (_) => {},
                  photos: photos,
                  endPoint: urlOsmReview,
                )
              : null,
        ),
      ],
      //  ),
      //  ),
    );
  }
}
