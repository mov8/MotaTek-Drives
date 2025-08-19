import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:drives/constants.dart';
import 'package:intl/intl.dart';

class GroupDriveInvitationTile extends StatefulWidget {
  final EventInvitation eventInvitation;
  final ImageRepository imageRepository;
  final Function(int)? onEdit;
  final Function(int)? onDownload;
  final Function(int)? onSelect;
  final Function(int, int)? onRespond;

  final int index;

  const GroupDriveInvitationTile(
      {super.key,
      required this.eventInvitation,
      required this.imageRepository,
      this.index = 0,
      this.onEdit,
      this.onDownload,
      this.onSelect,
      this.onRespond});

  @override
  State<GroupDriveInvitationTile> createState() =>
      _GroupDriveInvitationTileState();
}

class _GroupDriveInvitationTileState extends State<GroupDriveInvitationTile> {
  DateFormat dateFormat = DateFormat('d MMM y');
  TripItem? _tripSummary;

  List<String> invState = ['undecided', 'declined', 'accepted'];
  List<Photo> photos = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: ExpansionTile(
          leading: Column(
            children: [
              Icon(
                inviteIcons[widget.eventInvitation.accepted],
                size: 30,
              ),
              const SizedBox(
                height: 10,
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
          subtitle: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Drive date: ${dateFormat.format(widget.eventInvitation.eventDate)} ',
                      style: const TextStyle(fontSize: 16),
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
                      style: const TextStyle(fontSize: 16),
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
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onExpansionChanged: (val) => getSummary(val),
          children: [
            if (_tripSummary == null) ...[
              const Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 100,
                  height: 200,
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ] else ...[
              if (_tripSummary!.imageUrls.isNotEmpty)
                Row(children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: SizedBox(
                      child: PhotoCarousel(
                        imageRepository: widget.imageRepository,
                        photos: photos,
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
                        Text(_tripSummary!.published)
                      ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(children: [
                        const Icon(Icons.route),
                        Text('${_tripSummary!.distance} miles long')
                      ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(children: [
                        const Icon(Icons.landscape),
                        Text('${_tripSummary!.pointsOfInterest} highlights')
                      ]),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(children: [
                        const Icon(Icons.social_distance),
                        Text('${_tripSummary!.closest} miles away')
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
                      _tripSummary!.subHeading,
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
                  child: Text(_tripSummary!.body,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      textAlign: TextAlign.left),
                ),
              )),
              if (_tripSummary!.author.isNotEmpty)
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Text(
                            'author: ${_tripSummary!.author}',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: StarRating(
                              onRatingChanged: changeRating,
                              rating: _tripSummary!.score),
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
                          const Align(
                            alignment: Alignment.center,
                            child: Text('join trip'),
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
                          const Align(
                            alignment: Alignment.center,
                            child: Text('download'),
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
    return TextStyle(
        decoration: widget.eventInvitation.accepted == value
            ? TextDecoration.underline
            : TextDecoration.none,
        fontWeight: widget.eventInvitation.accepted == value
            ? FontWeight.bold
            : FontWeight.normal);
  }

  getSummary(val) async {
    if (val) {
      if (_tripSummary == null) {
        getTrip(tripId: widget.eventInvitation.driveId).then((trip) {
          if (trip != null) {
            _tripSummary = trip;
            photos =
                photosFromJson(trip.imageUrls, endPoint: '$urlDriveImages/');
            setState(() {});
          }
        });
      }
    }
  }

  respond(value) async {
    widget.eventInvitation.accepted = value;
    answerInvitation(widget.eventInvitation).then((val) => setState(() {}));
  }

  changeRating(value) {
    // widget.onRatingChanged(value, widget.index);
  }
}
