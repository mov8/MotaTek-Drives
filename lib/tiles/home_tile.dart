import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class HomeTile extends StatefulWidget {
  final HomeItem homeItem;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const HomeTile({
    super.key,
    required this.homeItem,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<HomeTile> createState() => _homeTileState();
}

class _homeTileState extends State<HomeTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 400,

                  //    if (widget.homeItem.imageUrl.isNotEmpty)
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 8,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width, // 375,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (Photo photo in photosFromJson(
                                widget.homeItem.imageUrl,
                              ))
                                showWebImage(
                                    Uri.parse(
                                            '${urlBase}v1/home_page_item/images/${widget.homeItem.uri}/${photo.url}')
                                        .toString(),
                                    width: MediaQuery.of(context).size.width -
                                        10, //400,
                                    canDelete: false)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
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
