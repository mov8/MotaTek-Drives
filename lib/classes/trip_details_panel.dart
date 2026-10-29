import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/theme.dart';
import '/helpers/edit_helpers.dart';
import '/services/services.dart';

/// AI assist, to save a trip: its name, summary and details - written by
/// the user, or by Write it for me from the trip as it is now (its route
/// and points of interest). Save trip opens it (PlannerService.saving) and
/// its Save trip saves the trip; the trip's heading opens it to edit the
/// details, and then it's Done. For a trip AI assist planned, the details
/// it wrote are here to change - or to write again for the trip as changed.
class TripDetailsPanel extends StatefulWidget {
  const TripDetailsPanel({super.key});

  @override
  State<TripDetailsPanel> createState() => _TripDetailsPanelState();
}

class _TripDetailsPanelState extends State<TripDetailsPanel> {
  final CurrentTripItem _trip = CurrentTripItem();
  late final TextEditingController _title =
      TextEditingController(text: _trip.title);
  late final TextEditingController _summary =
      TextEditingController(text: _trip.subTitle);
  late final TextEditingController _details =
      TextEditingController(text: _trip.body);
  bool _writing = false;
  String _problem = '';

  @override
  void initState() {
    super.initState();
    PlannerService().checkAllowance();
  }

  @override
  void dispose() {
    for (TextEditingController c in [_title, _summary, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String label, String hint) => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
      labelText: label,
      hintText: hint);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlannerService(),
      builder: (context, _) {
        PlannerService planner = PlannerService();
        bool saving = planner.saving != null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, color: DrivesColours.current.ai),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      saving ? 'Name and describe your trip' : 'Trip details',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                  _trip.aiSuggestion
                      ? 'AI assist wrote these from its plan. Change anything '
                          "you like - if you've changed the trip, Write it for "
                          'me describes it as it is now.'
                      : 'Write your own, or Write it for me writes them from '
                          "the trip's route and its points of interest - "
                          'check them before you publish.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (!planner.canDescribe)
                _noneLeft(context, planner.describeAllowance!),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [TitleCaseFormatter()],
                decoration: _field('Trip name', 'Give your trip a name...'),
                onChanged: (text) => _changed(() => _trip.title = text),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _summary,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [SentenceCaseFormatter()],
                decoration:
                    _field('Trip summary', 'A short summary of your trip...'),
                onChanged: (text) => _changed(() => _trip.subTitle = text),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _details,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [SentenceCaseFormatter()],
                decoration: _field('Trip details', 'Describe your trip...'),
                onChanged: (text) => _changed(() => _trip.body = text),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                // AI's own colours
                Theme(
                  data: aiTheme(Theme.of(context)),
                  child: OutlinedButton.icon(
                    icon: _writing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_writing ? 'Writing...' : 'Write it for me'),
                    onPressed:
                        _writing || !planner.canDescribe ? null : _writeItForMe,
                  ),
                ),
                FilledButton.icon(
                  icon: Icon(saving ? Icons.save : Icons.check),
                  label: Text(saving ? 'Save trip' : 'Done'),
                  onPressed: _writing ? null : () => _finish(saving),
                ),
              ]),
              if (_problem.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_problem,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        );
      },
    );
  }

  /// A change to the details - the trip needs saving again
  void _changed(VoidCallback change) {
    change();
    if (_trip.isSaved) {
      _trip.isSaved = false;
      MapService().createTripStackController?.refresh();
    }
    if (_problem.isNotEmpty) setState(() => _problem = '');
  }

  /// Saves the trip (from Save trip) - or, editing the details, back to the
  /// trip, where Save trip is offered
  void _finish(bool saving) {
    if (_trip.headerComplete() != 7) {
      setState(
          () => _problem = 'A trip needs a name, a summary and details - write '
              'them, or Write it for me.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    VoidCallback? save = PlannerService().saving;
    if (saving && save != null) return save();
    BottomDrawerItems trip = BottomDrawerItems.trip;
    kIsWeb
        ? MapService().sideDrawerController?.setContent(content: trip)
        : MapService().bottomDrawerController?.setContent(content: trip);
    MapService().createTripStackController?.refresh();
  }

  /// Before they try: Write it for me has been used all it can for now
  Widget _noneLeft(BuildContext context, Map allowance) {
    DateTime? next = DateTime.tryParse(allowance['next'] ?? '');
    String when = next == null
        ? 'later'
        : '${next.day == DateTime.now().day ? 'at' : 'tomorrow at'} '
            '${next.hour.toString().padLeft(2, '0')}:'
            '${next.minute.toString().padLeft(2, '0')}';
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text("Write it for me has written all ${allowance['limit']} "
            'descriptions it can for you in 24 hours - it can write another '
            '$when. You can still write your own.'),
      ),
    );
  }

  /// Write it for me - the name, summary and details from the trip as it
  /// is now: its route (the towns and roads) and its points of interest, as
  /// the user described them
  Future<void> _writeItForMe() async {
    bool written = _trip.title.isNotEmpty ||
        _trip.subTitle.isNotEmpty ||
        _trip.body.isNotEmpty;
    if (written && !await _replaceConfirmed()) return;
    setState(() => _writing = true);
    var (fields, problem) = await describeTrip(_trip);
    PlannerService().checkAllowance();
    if (!mounted) return;
    setState(() => _writing = false);
    if (fields == null) return setState(() => _problem = problem ?? '');
    _changed(() {
      _trip.title = fields['title'] ?? _trip.title;
      _trip.subTitle = fields['summary'] ?? _trip.subTitle;
      _trip.body = fields['description'] ?? _trip.body;
    });
    setState(() {
      _title.text = _trip.title;
      _summary.text = _trip.subTitle;
      _details.text = _trip.body;
    });
  }

  Future<bool> _replaceConfirmed() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace the trip details?'),
          content: const Text(
              'Drives will write a new name, summary and details from the '
              "trip as it is now. What's there now will be replaced."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Write it')),
          ],
        ),
      ) ??
      false;
}
