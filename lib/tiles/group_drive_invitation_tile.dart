import '/classes/classes.dart';
import '/services/services.dart';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/constants.dart';
import '/helpers/edit_helpers.dart';
import 'package:intl/intl.dart';
// import 'dart:developer' as develper;

class GroupDriveInvitationTileController {
  _GroupDriveInvitationTileState? _groupDriveInvitationTileState;
  void _addState(_GroupDriveInvitationTileState groupDriveInvitationTileState) {
    _groupDriveInvitationTileState = groupDriveInvitationTileState;
  }

  bool get isAttached => _groupDriveInvitationTileState != null;

  void contract() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _groupDriveInvitationTileState?.changeOpenState();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }
}

class GroupDriveInvitationTile extends StatefulWidget {
  final EventInvitation eventInvitation;
  final ImageRepository imageRepository;
  final GroupDriveInvitationTileController controller;
  final bool expanded;
  final TripItem? tripItem;
  final List<Photo>? photos;
  final Function(int)? onEdit;
  final Function(int)? onDownload;
  final Function(int)? onSelect;
  final Function(int, int)? onRespond;
  final Function(bool, GroupDriveInvitationTileController)? onExpandChange;

  final int index;

  const GroupDriveInvitationTile(
      {super.key,
      required this.eventInvitation,
      required this.imageRepository,
      required this.controller,
      this.tripItem,
      this.photos,
      this.expanded = false,
      this.index = 0,
      this.onEdit,
      this.onDownload,
      this.onSelect,
      this.onRespond,
      this.onExpandChange});

  @override
  State<GroupDriveInvitationTile> createState() =>
      _GroupDriveInvitationTileState();
}

class _GroupDriveInvitationTileState extends State<GroupDriveInvitationTile> {
  DateFormat dateFormat = DateFormat('d MMM y');
  final ExpansibleController _expansibleController = ExpansibleController();
  List<String> invState = ['undecided', 'declined', 'accepted', 'joined'];
  List<Photo> photos = [];

  @override
  void initState() {
    super.initState();
  }

  changeOpenState() {
    if (widget.expanded) {
      debugPrint('Controller closing tile $widget.index');
      _expansibleController.collapse();
    } else {
      debugPrint(
          'tile $widget.index is already closed - widget.expanded = false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          controller: _expansibleController,
          leading: Column(
            children: [
              Icon(
                inviteIcons[widget.eventInvitation.accepted],
                size: 30,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(invState[widget.eventInvitation.accepted]),
            ],
          ),
          //onLongPress: () => widget.onEdit!(widget.index),
          //    tileColor: Color(0xFFC2DFE7),
          //   trailing: IconButton(
          //     iconSize: 30,
          //     icon: const Icon(Icons.delete),
          //     onPressed: () => widget.onDelete,
          //   ),

          title: Text(
            widget.eventInvitation.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          //  initiallyExpanded: widget.expanded,
          subtitle: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                        'Drive date: ${dateFormat.format(widget.eventInvitation.eventDate)} ',
                        style: labelStyle(
                            context: context,
                            size: 3,
                            color:
                                Colors.black) // const TextStyle(fontSize: 16),
                        ),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                        'invited: ${dateFormat.format(widget.eventInvitation.invitationDate)}',
                        style: labelStyle(
                            context: context,
                            size: 3,
                            color:
                                Colors.black) //const TextStyle(fontSize: 16),
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                        'by: ${widget.eventInvitation.forename} ${widget.eventInvitation.surname}',
                        style: labelStyle(
                            context: context,
                            size: 2,
                            color:
                                Colors.black) //const TextStyle(fontSize: 18),
                        ),
                  ),
                ],
              ),
            ],
          ),

          onExpansionChanged: (val) {
            widget.onExpandChange!(val, widget.controller);
            photos = widget.photos ?? []; //photosFromJson(
            // photoString: widget.tripItem!.imageUrls,
            // endPoint: '$urlDriveImages/');
          }, //  getSummary(val),
          children: [
            if (widget.tripItem == null) ...[
              const Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text('Details Missing',
                        style: TextStyle(
                            fontSize: 20)), //CircularProgressIndicator(),
                  ),
                ),
              ),
            ] else ...[
              if (widget.tripItem != null &&
                  widget.tripItem!.imageUrls.isNotEmpty)
                Row(children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: SizedBox(
                      child: PhotoCarousel(
                        imageRepository: widget.imageRepository,
                        photos: widget.photos!,
                        height: 300,
                        width: MediaQuery.of(context).size.width - 50,
                      ),
                    ),
                  ),
                ]),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(children: [
                        const Icon(Icons.publish),
                        Text('published',
                            style: labelStyle(
                                context: context,
                                size: 3,
                                color: Colors.black)),
                        Text(widget.tripItem!.published,
                            style: labelStyle(
                                context: context,
                                size: 3,
                                color: Colors.black)),
                      ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.route),
                            Text(
                              '${widget.tripItem!.distance.toStringAsFixed(1)}',
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ),
                            Text(
                              'miles long',
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ) //)
                          ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.landscape),
                            Text(
                              widget.tripItem!.pointsOfInterest.toString(),
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ),
                            Text(
                              'highlights',
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ), //)
                          ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.social_distance),
                            Text(
                                (widget.tripItem!.distanceAway * metersToMiles)
                                    .toStringAsFixed(1),
                                style: labelStyle(
                                    context: context,
                                    size: 3,
                                    color: Colors.black)),
                            Text(' miles away',
                                style: labelStyle(
                                    context: context,
                                    size: 3,
                                    color: Colors.black)) //)
                          ]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      widget.tripItem!.subHeading,
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
                  child: Text(widget.tripItem!.body,
                      style: textStyle(
                          context: context, size: 3, color: Colors.black),
                      textAlign: TextAlign.left),
                ),
              )),
              if (widget.tripItem!.author.isNotEmpty)
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Text(
                            'author: ${widget.tripItem!.author}',
                            style: labelStyle(
                                context: context, size: 3, color: Colors.black),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: StarRating(
                              onRatingChanged: changeRating,
                              rating: widget.tripItem!.score),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                  child: Row(children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.directions_car),
                            onPressed: () {
                              if (widget.onSelect != null) {
                                widget.onSelect!(widget.index);
                              }
                            },
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'join trip',
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                              icon: Icon(inviteIcons[2]),
                              onPressed: () => widget.onRespond!(
                                  widget.index, 2) //respond(2),
                              ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              invState[2],
                              style: getStyle(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(inviteIcons[1]),
                            onPressed: () => widget.onRespond!(widget.index, 1),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              invState[1],
                              style: getStyle(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(inviteIcons[0]),
                            onPressed: () => widget.onRespond!(widget.index, 0),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              invState[0],
                              style: getStyle(0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => widget.onDownload!(widget.index),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'download',
                              style: labelStyle(
                                  context: context,
                                  size: 3,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    )
                  ]),
                ),
              ),
            ],
            // onLongPress: () => widget.onLongPress(widget.index),
          ],
        ),
      ),
    );
  }

  TextStyle getStyle(value) {
    TextStyle style = widget.eventInvitation.accepted == value
        ? textStyle(context: context, color: Colors.black, size: 3).copyWith(
            decoration: TextDecoration.underline, fontWeight: FontWeight.bold)
        : textStyle(context: context, color: Colors.black, size: 3).copyWith(
            decoration: TextDecoration.none, fontWeight: FontWeight.normal);
    return style;
  }
/*
  getSummary(bool val) async {
    if (widget.onExpansionChange != null) {
      widget.onExpansionChange!(widget.index, val);
    }
    if (widget.tripItem != null) {
      photos = photosFromJson(
          photoString: widget.tripItem!.imageUrls,
          endPoint: '$urlDriveImages/');
    }
  }
  */

  respond(value) async {
    widget.eventInvitation.accepted = value;
    answerInvitation(widget.eventInvitation).then((val) => setState(() {}));
  }

  changeRating(value) {
    // widget.onRatingChanged(value, widget.index);
  }
}
