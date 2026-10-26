import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/classes/classes.dart';
import '/services/services.dart';

/// Drives staff (web): every club at a glance - who to contact, whether
/// they've paid, members, AI usage - as a table sorted by any column, so a
/// club that hasn't paid, or has used a lot of AI, stands out. A club opens
/// to change its contact and payment, or to appoint its admin. See
/// api/v1/console.py.
class ConsoleForm extends StatefulWidget {
  const ConsoleForm({super.key});

  @override
  State<ConsoleForm> createState() => _ConsoleFormState();
}

class _ConsoleFormState extends State<ConsoleForm> {
  List<Map> _clubs = [];
  String? _problem;
  int _sortColumn = 0;
  bool _ascending = true;

  static final NumberFormat _dollars = NumberFormat.currency(symbol: '\$');
  static final DateFormat _day = DateFormat('d MMM yy');

  // what each column sorts by
  static final List<Comparable Function(Map)> _sortBy = [
    (club) => (club['name'] ?? '').toString().toLowerCase(),
    (club) => club['paid_until'] ?? '', // not paid sorts first
    (club) => club['members'] ?? 0,
    (club) => club['ai_month_cost'] ?? 0,
    (club) => club['ai_cost'] ?? 0,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async => _show(await ClubService().consoleClubs());

  /// Every console call comes back as the whole list
  void _show((dynamic, String?) result) {
    var (clubs, problem) = result;
    if (!mounted) return;
    setState(() {
      _problem = problem;
      if (clubs is List) {
        _clubs = List<Map>.from(clubs);
        _sort();
      }
    });
  }

  void _sort() {
    _clubs.sort((a, b) {
      int order = _sortBy[_sortColumn](a).compareTo(_sortBy[_sortColumn](b));
      return _ascending ? order : -order;
    });
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
      prompt: 'Every club - contact, payment, members, AI usage',
      textColor: const Color.fromRGBO(1, 29, 51, 1),
      content: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(10), children: [
          Row(children: [
            Expanded(
              child: Text(
                  _problem ??
                      '${_clubs.length} club${_clubs.length == 1 ? '' : 's'}, $unpaid not paid. '
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumn,
              sortAscending: _ascending,
              showCheckboxColumn: false,
              columnSpacing: 18,
              horizontalMargin: 8,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columns: [
                for (String label in [
                  'Club',
                  'Paid until',
                  'Members',
                  'AI month',
                  'AI all'
                ])
                  DataColumn(
                    label: Text(label),
                    numeric: !['Club', 'Paid until'].contains(label),
                    onSort: (column, ascending) => setState(() {
                      _sortColumn = column;
                      _ascending = ascending;
                      _sort();
                    }),
                  ),
              ],
              rows: [for (Map club in _clubs) _row(club)],
            ),
          ),
        ]),
      ),
    );
  }

  DataRow _row(Map club) {
    bool paid = club['paid'] == true;
    String contact = [club['contact_name'], club['contact_email']]
        .where((part) => (part ?? '').toString().isNotEmpty)
        .join(', ');
    TextStyle warning = TextStyle(color: Colors.red.shade700);
    return DataRow(
      onSelectChanged: (_) => _edit(club),
      cells: [
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(club['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(contact.isEmpty ? 'No contact' : contact,
                style: const TextStyle(fontSize: 12)),
            if (club['admins'] == null)
              Text('No admin yet', style: warning.copyWith(fontSize: 12)),
          ],
        )),
        DataCell(Text(
            club['paid_until'] == null
                ? 'Not paid'
                : _day.format(DateTime.parse(club['paid_until'])),
            style: paid ? null : warning)),
        DataCell(Text('${club['members'] ?? 0}')),
        DataCell(Text('${_dollars.format(club['ai_month_cost'] ?? 0)}'
            ' (${club['ai_month_requests'] ?? 0})')),
        DataCell(Text(_dollars.format(club['ai_cost'] ?? 0))),
      ],
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
    _show(result);
  }

  Future<void> _edit(Map club) async {
    (dynamic, String?)? result = await showDialog<(dynamic, String?)>(
      context: context,
      builder: (context) => _ClubDialog(club: club),
    );
    if (result != null) _show(result);
  }
}

/// A club's contact and payment, and appointing its admin
class _ClubDialog extends StatefulWidget {
  final Map club;
  const _ClubDialog({required this.club});

  @override
  State<_ClubDialog> createState() => _ClubDialogState();
}

class _ClubDialogState extends State<_ClubDialog> {
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
  late String? _admins = widget.club['admins'];
  String? _problem;
  (dynamic, String?)? _changed; // the list, after appointing an admin

  static final DateFormat _day = DateFormat('d MMM yyyy');

  @override
  void dispose() {
    for (TextEditingController c in [..._fields.values, _admin]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String label) => InputDecoration(
      border: const OutlineInputBorder(), isDense: true, labelText: label);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.club['name'] ?? 'Club'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var (field, label) in [
                ('contact_name', 'Contact'),
                ('contact_email', 'Contact email'),
                ('contact_phone', 'Contact phone'),
              ]) ...[
                TextField(
                    controller: _fields[field], decoration: _field(label)),
                const SizedBox(height: 10),
              ],
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
              const SizedBox(height: 16),
              Text('Admin: ${_admins ?? 'none yet'}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: _admin,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _field("A Drives user's email")),
                ),
                TextButton(
                    onPressed: _appoint, child: const Text('Make admin')),
              ]),
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_problem!,
                      style: TextStyle(color: Colors.red.shade700)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, _changed),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
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
        await ClubService().appointAdmin(widget.club['id'], _admin.text.trim());
    if (!mounted) return;
    setState(() {
      _problem = result.$2;
      if (result.$1 is List) {
        _changed = result;
        _admins = (result.$1 as List).firstWhere(
            (club) => club['id'] == widget.club['id'],
            orElse: () => {})['admins'];
        _admin.clear();
      }
    });
  }

  Future<void> _save() async {
    var result = await ClubService().updateClub(widget.club['id'], {
      for (var entry in _fields.entries) entry.key: entry.value.text,
      'paid_until': _paidUntil,
    });
    if (!mounted) return;
    if (result.$2 != null) return setState(() => _problem = result.$2);
    Navigator.pop(context, result);
  }
}
