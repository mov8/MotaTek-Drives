import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';

class ShopTile extends StatefulWidget {
  final ShopItem shopItem;
  final ImageRepository imageRepository;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const ShopTile({
    super.key,
    required this.shopItem,
    required this.imageRepository,
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
  final PageController _pageController = PageController();
  final ImageListIndicatorController _imageListIndicatorController =
      ImageListIndicatorController();

  @override
  void initState() {
    super.initState();
    photos = photosFromJson(
        photoString: widget.shopItem.imageUrls,
        endPoint: '${widget.shopItem.uri}/');
    _pageController.addListener(() => pageControlListener());
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  pageControlListener() {
    setState(
      () => _imageListIndicatorController
          .changeImageIndex(_pageController.page!.round()),
    );
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
              PhotoCarousel(
                imageRepository: widget.imageRepository,
                photos: photos,
                // endPoint: '$urlShopItem/images/${widget.shopItem.uri}/',
                height: MediaQuery.of(context).size.width - 20,
                width: MediaQuery.of(context).size.width - 20,
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      widget.shopItem.heading,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20),
                        textAlign: TextAlign.left),
                  ),
                ),
              ),
              if (widget.shopItem.url1.isNotEmpty) ...[
                ActionChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () async {
                    Setup().bottomNavIndex = 4;
                    await Setup().setupToDb();
                    launchUrl(
                      Uri.parse(widget.shopItem.url1),
                      mode: LaunchMode.inAppBrowserView,
                    );
                  },
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
