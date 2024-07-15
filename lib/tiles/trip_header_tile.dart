import 'package:drives/main.dart';
import 'package:flutter/material.dart';
import 'package:drives/models.dart';

class TripHeaderTile extends StatefulWidget {
  final TripItem tripItem;
  final Function(int) onUpdate;
  final int index;
  final AppState appState;

  const TripHeaderTile({
    super.key,
    required this.index,
    required this.tripItem,
    required this.appState,
    required this.onUpdate,
  });

  @override
  State<TripHeaderTile> createState() => _tripHeaderTileState();
}

class _tripHeaderTileState extends State<TripHeaderTile> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: TextFormField(
            readOnly: widget.appState == AppState.driveTrip,
            //    enabled: _appState != AppState.driveTrip,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Give your trip a name...',
              labelText: 'Trip name',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: widget.tripItem.heading,
            onChanged: (text) => setState(() {
                  widget.tripItem.heading = text;
                })),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextFormField(
            readOnly: widget.appState == AppState.driveTrip,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            spellCheckConfiguration: const SpellCheckConfiguration(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a short summary of your trip...',
              labelText: 'Trip summary',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: widget.tripItem.subHeading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (text) => setState(() {
                  widget.tripItem.subHeading = text;
                })),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextFormField(
            readOnly: widget.appState == AppState.driveTrip,
            // enabled: _appState != AppState.driveTrip,
            textAlign: TextAlign.start,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            spellCheckConfiguration: const SpellCheckConfiguration(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Describe details of your trip...',
              labelText: 'Trip details',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: widget.tripItem.body,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (text) => setState(() {
                  widget.tripItem.body = text;
                })),
      ),
    ]);
  }
}
