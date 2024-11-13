import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class ShopTile extends StatefulWidget {
  final ShopItem shopItem;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const ShopTile({
    super.key,
    required this.shopItem,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<ShopTile> createState() => _ShopTileState();
}

class _ShopTileState extends State<ShopTile> {
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

                  //    if (widget.shopItem.imageUrl.isNotEmpty)
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
                                widget.shopItem.imageUrl,
                              ))
                                showWebImage(
                                    Uri.parse(
                                            '${urlBase}v1/home_page_item/images/${widget.shopItem.uri}/${photo.url}')
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
                    child: Text(widget.shopItem.heading,
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
                      widget.shopItem.subHeading,
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
                  child: Text(widget.shopItem.body,
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
