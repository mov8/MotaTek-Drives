import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/classes/classes.dart';
import '/services/services.dart';

/// Drives staff (web): every club, as summary tiles in the SideDrawer - so
/// a club that hasn't paid, has no admin, or has used a lot of AI stands
/// out - sorted as chosen. The selected club's details are to the right
/// (SideDrawerController.setDetails), where its contact, payment and admin
/// are changed. See api/v1/console.py.
class ConsoleForm extends StatefulWidget {
  const ConsoleForm({super.key});

  @override
  State<ConsoleForm> createState() => _ConsoleFormState();
}

final NumberFormat _dollars = NumberFormat.currency(symbol: '\$');

String _plural(int count, String word) =>
    '$count $word${count == 1 ? '' : 's'}';

class _ConsoleFormState extends State<ConsoleForm> {
  List<Map> _clubs = [];
  String? _problem;
  String _sortBy = 'name';
  String? _selected; // the club whose details are showing

  // what each sort puts first
  static final Map<String, (String, int Function(Map, Map))> _sorts = {
    'name': (
      'Name',
      (a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['name'] ?? '').toString().toLowerCase())
    ),
    'unpaid': (
      'Not paid',
      (a, b) => (a['paid_until'] ?? '').compareTo(b['paid_until'] ?? '')
    ),
    'members': ('Members', (a, b) => (b['members'] ?? 0) - (a['members'] ?? 0)),
    'ai': (
      'AI this month',
      (a, b) => ((b['ai_month_cost'] ?? 0) as num)
          .compareTo((a['ai_month_cost'] ?? 0) as num)
    ),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async => _show(await ClubService().consoleClubs());

  /// Every console call comes back as the whole list
  void _show((dynamic, String?) result, {String? select}) {
    var (clubs, problem) = result;
    if (!mounted) return;
    setState(() {
      _problem = problem;
      if (clubs is List) {
        _clubs = List<Map>.from(clubs)..sort(_sorts[_sortBy]!.$2);
      }
    });
    String? id = select ?? _selected;
    if (_clubs.isEmpty) {
      return MapService().sideDrawerController?.setDetails(null);
    }
    _select(_clubs.firstWhere((club) => club['id'] == id,
        orElse: () => _clubs.first));
  }

  void _select(Map club) {
    setState(() => _selected = club['id']);
    MapService().sideDrawerController?.setDetails(_ClubDetails(
          key: ValueKey(club['id']),
          club: club,
          onChanged: (result) => _show(result, select: club['id']),
        ));
  }

  void _say(String? problem) {
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    int unpaid = _clubs.where((club) => club['paid'] != true).length;
    double aiMonth =
        _clubs.fold(0.0, (total, club) => total + (club['ai_month_cost'] ?? 0));
    return ScreensAppBarBottom(
      heading: 'Clubs console',
      prompt: 'Every club - payment, members, AI usage',
      textColor: const Color.fromRGBO(1, 29, 51, 1),
      content: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(10), children: [
          Row(children: [
            Expanded(
              child: Text(
                  _problem ??
                      '${_plural(_clubs.length, 'club')}, $unpaid not paid. '
                          'AI this month ${_dollars.format(aiMonth)}',
                  style: const TextStyle(fontSize: 15)),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New club'),
              onPressed: _newClub,
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (var MapEntry(key: key, value: (label, _)) in _sorts.entries)
              ChoiceChip(
                label: Text(label),
                selected: _sortBy == key,
                onSelected: (_) => setState(() {
                  _sortBy = key;
                  _clubs.sort(_sorts[key]!.$2);
                }),
              ),
          ]),
          const SizedBox(height: 6),
          for (Map club in _clubs) _tile(club),
        ]),
      ),
    );
  }

  Widget _tile(Map club) {
    bool paid = club['paid'] == true;
    TextStyle warning = TextStyle(color: Colors.red.shade700);
    return Card(
      color: club['id'] == _selected ? Colors.blue.shade50 : null,
      child: ListTile(
        onTap: () => _select(club),
        title: Text(club['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_plural(club['members'] ?? 0, 'member')} - AI '
                '${_dollars.format(club['ai_month_cost'] ?? 0)} this month'),
            if (club['admins'] == null) Text('No admin yet', style: warning),
          ],
        ),
        trailing: Chip(
          label: Text(paid ? 'Paid' : 'Not paid',
              style: TextStyle(
                  color: paid ? Colors.green.shade800 : Colors.red.shade700)),
          side: BorderSide(
              color: paid ? Colors.green.shade800 : Colors.red.shade700),
        ),
      ),
    );
  }

  Future<void> _newClub() async {
    TextEditingController name = TextEditingController();
    String? chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A new club'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "The club's name"),
          onSubmitted: (text) => Navigator.pop(context, text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, name.text),
              child: const Text('Add')),
        ],
      ),
    );
    name.dispose();
    if ((chosen ?? '').trim().isEmpty) return;
    var result = await ClubService().newClub(chosen!.trim());
    _say(result.$2);
    String? id = result.$1 is List
        ? (result.$1 as List).firstWhere(
            (club) => club['name'] == chosen.trim(),
            orElse: () => {})['id']
        : null;
    _show(result, select: id);
  }
}

/// The selected club, to the right of the drawer: how it's doing, and its
/// contact, payment and admin to change
class _ClubDetails extends StatefulWidget {
  final Map club;
  final Function((dynamic, String?)) onChanged; // the list, changed
  const _ClubDetails({super.key, required this.club, required this.onChanged});

  @override
  State<_ClubDetails> createState() => _ClubDetailsState();
}

class _ClubDetailsState extends State<_ClubDetails> {
  late final Map<String, TextEditingController> _fields = {
    for (String field in [
      'contact_name',
      'contact_email',
      'contact_phone',
      'payment_note'
    ])
      field: TextEditingController(text: widget.club[field] ?? '')
  };
  final TextEditingController _admin = TextEditingController();
  late String? _paidUntil = widget.club['paid_until'];
  String? _problem;
  String _saved = '';

  static final DateFormat _day = DateFormat('d MMMM yyyy');

  Map get club => widget.club;

  @override
  void dispose() {
    for (TextEditingController c in [..._fields.values, _admin]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String label) => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
      isDense: true,
      labelText: label);

  Widget _section(String heading, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );

  Widget _figure(String label, String value, {bool warn = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 170, child: Text(label)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: warn ? Colors.red.shade700 : null)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    bool paid = club['paid'] == true;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text(club['name'] ?? '',
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: 380,
          child: _section('How it is doing', [
            _figure('Members on Drives', '${club['members'] ?? 0}'),
            _figure('Admin', club['admins'] ?? 'none yet',
                warn: club['admins'] == null),
            _figure('AI this month',
                '${_dollars.format(club['ai_month_cost'] ?? 0)} (${_plural(club['ai_month_requests'] ?? 0, 'request')})'),
            _figure('AI in all', _dollars.format(club['ai_cost'] ?? 0)),
            _figure('Emails this month', '${club['emails_month'] ?? 0}'),
            _figure(
                'Subscription',
                club['paid_until'] == null
                    ? 'not paid'
                    : '${paid ? 'paid until' : 'ended'} ${_day.format(DateTime.parse(club['paid_until']))}',
                warn: !paid),
          ]),
        ),
        SizedBox(
          width: 380,
          child: _section('Contact', [
            for (var (field, label) in [
              ('contact_name', 'Name'),
              ('contact_email', 'Email'),
              ('contact_phone', 'Phone'),
            ]) ...[
              TextField(controller: _fields[field], decoration: _field(label)),
              const SizedBox(height: 10),
            ],
          ]),
        ),
        SizedBox(
          width: 380,
          child: _section('Payment', [
            Row(children: [
              Expanded(
                child: Text(
                    _paidUntil == null
                        ? 'Not paid'
                        : 'Paid until ${_day.format(DateTime.parse(_paidUntil!))}',
                    style: const TextStyle(fontSize: 16)),
              ),
              TextButton(
                  onPressed: _choosePaidUntil, child: const Text('Change')),
              if (_paidUntil != null)
                TextButton(
                    onPressed: () => setState(() => _paidUntil = null),
                    child: const Text('Not paid')),
            ]),
            const SizedBox(height: 6),
            TextField(
                controller: _fields['payment_note'],
                maxLines: 2,
                decoration: _field('Payment note')),
          ]),
        ),
        SizedBox(
          width: 380,
          child: _section('Admin', [
            Text(club['admins'] ??
                'No admin yet - make a member of the club '
                    'its admin, by their email'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _admin,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _field("A Drives user's email")),
              ),
              TextButton(onPressed: _appoint, child: const Text('Make admin')),
            ]),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save contact and payment'),
          onPressed: _save,
        ),
        const SizedBox(width: 12),
        if (_problem != null || _saved.isNotEmpty)
          Flexible(
            child: Text(_problem ?? _saved,
                style: TextStyle(
                    color:
                        _problem != null ? Colors.red.shade100 : Colors.white,
                    fontSize: 15)),
          ),
      ]),
    ]);
  }

  Future<void> _choosePaidUntil() async {
    DateTime now = DateTime.now();
    DateTime? chosen = await showDatePicker(
      context: context,
      initialDate: _paidUntil == null
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime.parse(_paidUntil!),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (chosen != null) {
      setState(() => _paidUntil = DateFormat('yyyy-MM-dd').format(chosen));
    }
  }

  Future<void> _appoint() async {
    if (!_admin.text.contains('@')) return;
    var result =
        await ClubService().appointAdmin(club['id'], _admin.text.trim());
    if (!mounted) return;
    if (result.$2 != null) return setState(() => _problem = result.$2);
    widget.onChanged(result);
  }

  Future<void> _save() async {
    var result = await ClubService().updateClub(club['id'], {
      for (var entry in _fields.entries) entry.key: entry.value.text,
      'paid_until': _paidUntil,
    });
    if (!mounted) return;
    if (result.$2 != null) return setState(() => _problem = result.$2);
    setState(() {
      _problem = null;
      _saved = 'Saved';
    });
    widget.onChanged(result);
  }
}
