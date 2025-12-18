import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/constants.dart';

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
  State<TripHeaderTile> createState() => _TripHeaderTileState();
}

class _TripHeaderTileState extends State<TripHeaderTile> {
  FocusNode fn1 = FocusNode();

  @override
  void initState() {
    super.initState();
    fn1.requestFocus();
  }

  @override
  void dispose() {
    fn1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextFormField(
                readOnly: widget.appState == AppState.driveTrip,
                focusNode: fn1,
                //    enabled: _appState != AppState.driveTrip,
                // autofocus: true,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
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
                // autofocus: true,
                readOnly: widget.appState == AppState.driveTrip,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
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
                // autofocus: true,
                textAlign: TextAlign.start,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
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
        ],
      ),
    );
  }
}
