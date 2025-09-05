import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/constants.dart';

class HomeTile extends StatefulWidget {
  final HomeItem homeItem;
  final ImageRepository imageRepository;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const HomeTile({
    super.key,
    required this.homeItem,
    required this.imageRepository,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  List<Photo> photos = [];
  String endPoint = '';
  // String endPoint = '';

  @override
  void initState() {
    super.initState();
    photos = photosFromJson(
        photoString: widget.homeItem.imageUrls,
        endPoint:
            //     '${urlBase.contains('motatek') ? uploadHttps : uploadHttps}/${widget.homeItem.uri}/');
            '$urlHomePageItem/images/${widget.homeItem.uri}/'); //images/${widget.homeItem.uri}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                child: PhotoCarousel(
                  imageRepository: widget.imageRepository,
                  photos: photos,
                  height: MediaQuery.of(context).size.width - 20, // 400,
                  width: MediaQuery.of(context).size.width - 20,
                ),
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(widget.homeItem.heading,
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
                      widget.homeItem.subHeading,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
              if (!Setup().hasLoggedIn) Row(children: []),
              SizedBox(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(widget.homeItem.body,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      textAlign: TextAlign.left),
                ),
              )),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => (setState(() {}))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
