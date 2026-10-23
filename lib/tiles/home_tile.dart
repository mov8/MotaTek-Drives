import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/models/models.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '/helpers/helpers.dart';

/// The mobile version will need the data putting in tiles, as it has no space to show a summary
/// unlike the web version that uses the side drawer.
/// The web version needs a summary tile for the side drawer - the homeItemTile - analogous to the
/// TripTile
class HomeTile extends StatefulWidget {
  final HomeItem homeItem;
  final ImageRepository imageRepository;
  final double width;
  final Function(int)? onSelect;
  final Function(int)? onDelete;
  final int index;

  const HomeTile({
    super.key,
    required this.homeItem,
    required this.imageRepository,
    this.width = 300,
    this.onSelect,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  @override
  Widget build(BuildContext context) {
    return driveDetails();
  }

  Widget driveDetails() {
    double leftPadding = 0;
    String data = widget.homeItem.markdown;
    MdStyleSheet _styleSheet =
        MdStyleSheet.fromJson(json: widget.homeItem.style ?? {});
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding + 10, 5, 10, 5), //   all(8.0),
      child: // Card(
          ClipRRect(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(10.0)),
        child: Container(
          color: Colors.white, // const Color.fromRGBO(54, 143, 244, 0.411),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: data,
                styleSheet: _styleSheet.markdownStyleSheet,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
