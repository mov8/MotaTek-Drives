import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:drives/classes/classes.dart';

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
  int imageIndex = 0;
  List<Photo> photos = [];
  String endPoint = '';
  final PageController _pageController = PageController();
  final ImageListIndicatorController _imageListIndicatorController =
      ImageListIndicatorController();

  @override
  void initState() {
    super.initState();
    photos = photosFromJson(widget.shopItem.imageUrl);
    endPoint = '${urlBase}v1/shop_item/images/${widget.shopItem.uri}/';
    _pageController.addListener(() => pageControlListener());
  }

  @override
  void dispose() {
    _pageController.dispose();
    // _imageListIndicatorController.dispose();
    super.dispose();
  }

  pageControlListener() {
    setState(() => _imageListIndicatorController
        .changeImageIndex(_pageController.page!.round()));
    // setState(() => imageIndex = _pageController.page!.round());
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
                          child: PageView.builder(
                            itemCount: photos.length,
                            scrollDirection: Axis.horizontal,
                            controller: _pageController,
                            itemBuilder: (BuildContext context, int index) {
                              imageIndex = index;
                              return showWebImage(
                                  '$endPoint${photos[index].url}',
                                  width: MediaQuery.of(context).size.width -
                                      10, //400,
                                  onDelete: (response) =>
                                      debugPrint('Response: $response'));
                              //   ],
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ImageListIndicator(
                  controller: _imageListIndicatorController, photos: photos),
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
              if (widget.shopItem.url1.isNotEmpty) ...[
                ActionChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => launchUrl(Uri.parse(widget.shopItem.url1),
                      mode: LaunchMode.inAppBrowserView),
                  //  forceSafariVC: false, forceWebView: false),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(
                    Icons.link,
                    color: Colors.white,
                  ),
                  label: Text(
                    widget.shopItem.buttonText1, // - ${_action.toString()}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
