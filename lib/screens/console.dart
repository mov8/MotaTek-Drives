import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/classes/classes.dart';
import '/services/services.dart';

/// The control panel - Drives staff (web). In the SideDrawer, a summary of
/// all of Drives, of private users (as one big club) and of each club: its
/// contact, scheme, last payment and balance (this month's income from its
/// scheme less its AI). To the right (SideDrawerController.setDetails), the
/// selected one's details - a club's contact, scheme and payments, private
/// users as counts and exceptions - and its last year month by month; or the
/// schemes; or an email to everyone or the clubs' admins; or the feedback
/// inbox. See
/// api/v1/console.py, api/reports.py and api/payments.py.
class ConsoleForm extends StatefulWidget {
  const ConsoleForm({super.key});

  @override
  State<ConsoleForm> createState() => _ConsoleFormState();
}

final NumberFormat _pounds = NumberFormat.currency(symbol: '£');
final NumberFormat _dollars = NumberFormat.currency(symbol: '\$');
final DateFormat _day = DateFormat('d MMM yyyy');

String _plural(int count, String word) =>
    '$count $word${count == 1 ? '' : 's'}';

String _date(String? iso) =>
    iso == null ? '-' : _day.format(DateTime.parse(iso));

Color _warning() => Colors.red.shade700;

InputDecoration _field(String label) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(),
    isDense: true,
    labelText: label);

Widget _section(String heading, List<Widget> children, {double width = 380}) =>
    SizedBox(
      width: width,
      child: Card(
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
      ),
    );

Widget _heading(String words) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(words,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
    );

void _say(BuildContext context, String? words) {
  if (words != null && words.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(words)));
  }
}

Future<String?> _pickDate(BuildContext context, String? current) async {
  DateTime now = DateTime.now();
  DateTime? chosen = await showDatePicker(
    context: context,
    initialDate: current == null ? now : DateTime.parse(current),
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 10),
  );
  return chosen == null ? null : DateFormat('yyyy-MM-dd').format(chosen);
}

class _ConsoleFormState extends State<ConsoleForm> {
  List<Map> _rows = [];
  List<Map> _schemes = [];
  String? _problem;
  String _selected = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var (schemes, _) = await ConsoleService().schemes();
    if (schemes is List) _schemes = List<Map>.from(schemes);
    _showRows(await ConsoleService().overview());
  }

  /// Every change comes back as the summaries
  void _showRows((dynamic, String?) result, {String? select}) {
    var (rows, problem) = result;
    if (!mounted) return;
    setState(() {
      _problem = problem;
      if (rows is List) _rows = List<Map>.from(rows);
    });
    _select(select ?? _selected);
  }

  void _select(String id) {
    setState(() => _selected = id);
    Widget details = switch (id) {
      'schemes' => _SchemesDetails(
          key: const ValueKey('schemes'),
          schemes: _schemes,
          onChanged: (schemes) {
            _schemes = schemes;
            _load();
          }),
      'email' => const _EmailDetails(key: ValueKey('email')),
      'feedback' => const _FeedbackDetails(key: ValueKey('feedback')),
      _ => _PayerDetails(
          key: ValueKey('$id${_rows.length}${DateTime.now().millisecond}'),
          row: _rows.firstWhere((row) => row['id'] == id,
              orElse: () => _rows.isEmpty ? {} : _rows.first),
          schemes: _schemes,
          onChanged: (result) => _showRows(result, select: id),
          reload: () async =>
              _showRows(await ConsoleService().overview(), select: id)),
    };
    MapService().sideDrawerController?.setDetails(details);
  }

  @override
  Widget build(BuildContext context) {
    return ScreensAppBarBottom(
      heading: 'Control panel',
      prompt: 'How Drives is doing - clubs, payments, AI',
      textColor: const Color.fromRGBO(1, 29, 51, 1),
      content: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(10), children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            _button('schemes', Icons.sell_outlined, 'Schemes'),
            _button('email', Icons.mail_outline, 'Email'),
            _button('feedback', Icons.feedback_outlined, 'Feedback'),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New club'),
              onPressed: _newClub,
            ),
          ]),
          if (_problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_problem!, style: TextStyle(color: _warning())),
            ),
          const SizedBox(height: 6),
          for (Map row in _rows) _tile(row),
        ]),
      ),
    );
  }

  Widget _button(String id, IconData icon, String label) => OutlinedButton.icon(
        style: _selected == id
            ? OutlinedButton.styleFrom(backgroundColor: Colors.blue.shade50)
            : null,
        icon: Icon(icon),
        label: Text(label),
        onPressed: () => _select(id),
      );

  Widget _tile(Map row) {
    bool club = row['kind'] == 'club';
    double balance = (row['balance'] ?? 0).toDouble();
    String contact = [row['contact_name'], row['contact_email']]
        .where((part) => (part ?? '').toString().isNotEmpty)
        .join(', ');
    return Card(
      color: row['id'] == _selected ? Colors.blue.shade50 : null,
      child: ListTile(
        onTap: () => _select(row['id']),
        title: Text(row['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (club)
              Text(contact.isEmpty ? 'No contact yet' : contact,
                  style: contact.isEmpty ? TextStyle(color: _warning()) : null),
            Text('${row['scheme'] ?? 'No scheme'} - '
                '${_plural(row['members'] ?? 0, 'member')}'),
            Text('Last payment ${_date(row['last_paid'])}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_pounds.format(balance),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance < 0 ? _warning() : Colors.green.shade800)),
            if (club)
              Text(row['paid'] == true ? 'Paid' : 'Not paid',
                  style: TextStyle(
                      color: row['paid'] == true
                          ? Colors.green.shade800
                          : _warning())),
          ],
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
          decoration: _field("The club's name"),
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
    var (result, problem) = await ConsoleService().newClub(chosen!.trim());
    if (!mounted) return;
    _say(context, problem);
    if (result is Map) {
      _showRows((result['summaries'], null), select: result['id']);
    }
  }
}

// ---- a club, private users, or all of Drives -------------------------------------

class _PayerDetails extends StatefulWidget {
  final Map row;
  final List<Map> schemes;
  final Function((dynamic, String?)) onChanged; // the summaries, changed
  final Future<void> Function() reload;
  const _PayerDetails(
      {super.key,
      required this.row,
      required this.schemes,
      required this.onChanged,
      required this.reload});

  @override
  State<_PayerDetails> createState() => _PayerDetailsState();
}

class _PayerDetailsState extends State<_PayerDetails> {
  late final TextEditingController _note =
      TextEditingController(text: widget.row['payment_note'] ?? '');
  final TextEditingController _admin = TextEditingController();
  late String? _schemeId = widget.row['scheme_id'];
  late String? _paidUntil = widget.row['paid_until'];
  bool _paidUntilChanged = false; // sent only then - a scheme's trial sets it

  Map get row => widget.row;
  bool get _club => row['kind'] == 'club';

  @override
  void dispose() {
    for (TextEditingController c in [_note, _admin]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double balance = (row['balance'] ?? 0).toDouble();
    return ListView(padding: const EdgeInsets.all(12), children: [
      _heading(row['name'] ?? ''),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _section('This month', [
          _figure('Members', '${row['members'] ?? 0}'),
          _figure('AI so far', _dollars.format(row['ai_month_cost'] ?? 0)),
          _figure('Income', _pounds.format(row['income_month'] ?? 0)),
          _figure('Balance', _pounds.format(balance), warn: balance < 0),
          if (_club) ...[
            _figure('Paid until', _date(row['paid_until']),
                warn: row['paid'] != true),
            _figure('Last payment', _date(row['last_paid'])),
          ],
        ]),
        if (_club) ...[
          _contact(),
          _scheme(),
          _PaymentsCard(
              payer: 'clubs', id: row['id'], onRecorded: widget.reload),
        ],
        if (row['kind'] == 'private') const _PrivateUsers(),
      ]),
      const SizedBox(height: 12),
      _MonthsTable(scope: row['id'] ?? 'all', everyone: row['kind'] == 'all'),
    ]);
  }

  Widget _figure(String label, String value, {bool warn = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: warn ? _warning() : null)),
          ),
        ]),
      );

  /// The club's contact - its admin, who looks after its pages - and their
  /// own details. A new contact takes the club over (api clubs.make_admin).
  Widget _contact() => _section('Contact', [
        if (row['admins'] == null)
          Text('No contact yet', style: TextStyle(color: _warning()))
        else ...[
          _figure('Name', row['contact_name'] ?? ''),
          _figure('Email', row['contact_email'] ?? ''),
          _figure(
              'Phone',
              (row['contact_phone'] ?? '').isEmpty
                  ? '-'
                  : row['contact_phone']),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _admin,
                  decoration: _field("The contact's email (a Drives user)"))),
          TextButton(
              onPressed: _appoint,
              child: Text(
                  row['admins'] == null ? 'Set contact' : 'Change contact')),
        ]),
        const Text(
            "The contact looks after the club's pages in Drives. A new "
            'contact takes over; the old one stays a member.',
            style: TextStyle(fontSize: 12)),
      ]);

  Widget _scheme() {
    List<Map> offered = widget.schemes
        .where((s) =>
            s['for_clubs'] == true &&
            (s['retired'] != true || s['id'] == _schemeId))
        .toList();
    return _section('Scheme and payment', [
      DropdownButtonFormField<String?>(
        initialValue: _schemeId,
        decoration: _field('Scheme'),
        items: [
          const DropdownMenuItem(value: null, child: Text('None')),
          for (Map s in offered)
            DropdownMenuItem(
                value: s['id'],
                child: Text(
                    '${s['name']} - ${_pounds.format(s['price_pence'] / 100)} '
                    'a ${s['period']}')),
        ],
        onChanged: (id) => setState(() => _schemeId = id),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: Text('Paid until ${_date(_paidUntil)}',
                style: const TextStyle(fontSize: 16))),
        TextButton(
            onPressed: () async {
              String? chosen = await _pickDate(context, _paidUntil);
              if (chosen != null) {
                setState(() {
                  _paidUntil = chosen;
                  _paidUntilChanged = true;
                });
              }
            },
            child: const Text('Change')),
      ]),
      TextField(
          controller: _note, maxLines: 2, decoration: _field('Payment note')),
      const SizedBox(height: 10),
      FilledButton(onPressed: _save, child: const Text('Save scheme')),
    ]);
  }

  Future<void> _save() async {
    var result = await ConsoleService().updateClub(row['id'], {
      'payment_note': _note.text,
      'scheme_id': _schemeId,
      if (_paidUntilChanged) 'paid_until': _paidUntil,
    });
    if (!mounted) return;
    _say(context, result.$2 ?? 'Saved');
    if (result.$2 == null) widget.onChanged(result);
  }

  Future<void> _appoint() async {
    if (!_admin.text.contains('@')) return;
    var result =
        await ConsoleService().appointAdmin(row['id'], _admin.text.trim());
    if (!mounted) return;
    _say(context, result.$2);
    if (result.$2 == null) widget.onChanged(result);
  }
}

/// A payer's payments, and recording one - paid until moves on a period of
/// their scheme (or to the date given)
class _PaymentsCard extends StatefulWidget {
  final String payer; // clubs
  final String id;
  final Future<void> Function() onRecorded;
  const _PaymentsCard(
      {required this.payer, required this.id, required this.onRecorded});

  @override
  State<_PaymentsCard> createState() => _PaymentsCardState();
}

class _PaymentsCardState extends State<_PaymentsCard> {
  List<Map> _payments = [];
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  String _paid = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var (payments, _) =
        await ConsoleService().payments(widget.payer, widget.id);
    if (mounted && payments is List) {
      setState(() => _payments = List<Map>.from(payments));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _section('Payments', [
      if (_payments.isEmpty) const Text('None recorded yet'),
      for (Map p in _payments.take(6))
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${_date(p['paid'])}: ${_pounds.format(p['amount'])}'
              '${(p['reference'] ?? '').isEmpty ? '' : ' (${p['reference']})'}'
              ' - to ${_date(p['paid_until'])}'),
        ),
      const Divider(),
      Row(children: [
        Expanded(
            child: TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: _field('Amount £'))),
        const SizedBox(width: 8),
        TextButton(
            onPressed: () async {
              String? chosen = await _pickDate(context, _paid);
              if (chosen != null) setState(() => _paid = chosen);
            },
            child: Text(_date(_paid))),
      ]),
      const SizedBox(height: 8),
      TextField(
          controller: _reference,
          decoration: _field('Reference, e.g. a bank transfer')),
      const SizedBox(height: 8),
      FilledButton(onPressed: _record, child: const Text('Record payment')),
    ]);
  }

  Future<void> _record() async {
    var (payments, problem) =
        await ConsoleService().recordPayment(widget.payer, widget.id, {
      'amount': _amount.text.replaceAll('£', '').trim(),
      'paid': _paid,
      'reference': _reference.text,
    });
    if (!mounted) return;
    _say(context, problem ?? 'Payment recorded');
    if (payments is List) {
      setState(() {
        _payments = List<Map>.from(payments);
        _amount.clear();
        _reference.clear();
      });
      widget.onRecorded();
    }
  }
}

/// Private users - too many to list - as counts, and the exceptions to look
/// into: heavy AI users this month, those often at their daily limit,
/// payments lapsed, and bursts of messages. They join, and pay, themselves.
class _PrivateUsers extends StatefulWidget {
  const _PrivateUsers();

  @override
  State<_PrivateUsers> createState() => _PrivateUsersState();
}

class _PrivateUsersState extends State<_PrivateUsers> {
  Map? _seen;

  @override
  void initState() {
    super.initState();
    ConsoleService().privateUsers().then((result) {
      if (mounted && result.$1 is Map) setState(() => _seen = result.$1);
    });
  }

  @override
  Widget build(BuildContext context) {
    Map? seen = _seen;
    if (seen == null) return const SizedBox.shrink();
    Map counts = seen['counts'] ?? {};
    Map limits = seen['thresholds'] ?? {};
    String name(Map u) =>
        '${u['forename'] ?? ''} ${u['surname'] ?? ''}'.trim().isEmpty
            ? u['email']
            : '${u['forename'] ?? ''} ${u['surname'] ?? ''} - ${u['email']}';
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _section('Private users', [
        for (var (label, key) in [
          ('Users', 'users'),
          ('Paying', 'paying'),
          ('Lapsed', 'lapsed'),
          ('New this month', 'new_this_month'),
          ('Unsubscribed this month', 'unsubscribed_this_month'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 190, child: Text(label)),
              Text('${counts[key] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
      ]),
      _exception(
          'Heavy AI users this month',
          'At least ${_dollars.format(limits['heavy_ai_dollars'] ?? 2)}',
          seen['heavy_ai'],
          (u) => '${name(u)}: ${_dollars.format(u['ai_cost'])} '
              '(${_plural(u['plans'] ?? 0, 'plan')})'),
      _exception(
          'Often at their daily AI limit',
          'On ${limits['limit_days'] ?? 3} days or more this month - a '
              'scheme with more?',
          seen['at_limit'],
          (u) => '${name(u)}: ${_plural(u['days'] ?? 0, 'day')}'),
      _exception(
          'Payments lapsed',
          'On a scheme, past their paid until',
          seen['lapsed'],
          (u) => '${name(u)}: ${u['scheme']}, paid until '
              '${_date(u['paid_until'])}'),
      _exception(
          'Bursts of messages',
          '${limits['busy_messages'] ?? 100} or more in a day - spam?',
          seen['busy'],
          (u) => '${name(u)}: up to ${u['messages']} a day, '
              '${_plural(u['days'] ?? 0, 'day')}'),
    ]);
  }

  /// One exception: how many, and the first of them
  Widget _exception(
      String heading, String what, Map? found, String Function(Map) line) {
    int count = found?['count'] ?? 0;
    List users = found?['users'] ?? [];
    return _section('$heading ($count)', [
      Text(what, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 6),
      if (count == 0) const Text('Nobody - nothing to look into'),
      for (Map u in users)
        Padding(
            padding: const EdgeInsets.only(bottom: 3), child: Text(line(u))),
      if (count > users.length)
        Text('... and ${count - users.length} more',
            style: const TextStyle(fontStyle: FontStyle.italic)),
    ]);
  }
}

/// The last year, month by month
class _MonthsTable extends StatefulWidget {
  final String scope;
  final bool everyone;
  const _MonthsTable({required this.scope, this.everyone = false});

  @override
  State<_MonthsTable> createState() => _MonthsTableState();
}

class _MonthsTableState extends State<_MonthsTable> {
  List<Map> _months = [];

  @override
  void initState() {
    super.initState();
    ConsoleService().months(widget.scope).then((result) {
      if (mounted && result.$1 is List) {
        setState(() => _months = List<Map>.from(result.$1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<(String, String Function(Map))> columns = [
      (
        'Month',
        (m) => DateFormat('MMM yyyy').format(DateTime.parse('${m['month']}-01'))
      ),
      ('Members', (m) => '${m['members']}'),
      if (widget.everyone) ('New users', (m) => '${m['new_users'] ?? 0}'),
      ('AI', (m) => '${_dollars.format(m['ai_cost'])} (${m['ai_plans']})'),
      ('Trips added', (m) => '${m['trips_added']} (${m['trips_added_ai']} AI)'),
      ('Published', (m) => '${m['trips_published']}'),
      ('Driven', (m) => '${m['trips_driven']}'),
      ('Messages', (m) => '${m['messages']}'),
      ('Emails', (m) => '${m['emails']}'),
      if (widget.everyone) ('Unsubscribed', (m) => '${m['unsubscribed'] ?? 0}'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Month by month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 36,
              columns: [
                for (var (label, _) in columns)
                  DataColumn(label: Text(label), numeric: label != 'Month')
              ],
              rows: [
                for (Map m in _months)
                  DataRow(cells: [
                    for (var (_, value) in columns) DataCell(Text(value(m)))
                  ])
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ---- schemes ----------------------------------------------------------------------

class _SchemesDetails extends StatefulWidget {
  final List<Map> schemes;
  final Function(List<Map>) onChanged;
  const _SchemesDetails(
      {super.key, required this.schemes, required this.onChanged});

  @override
  State<_SchemesDetails> createState() => _SchemesDetailsState();
}

class _SchemesDetailsState extends State<_SchemesDetails> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(child: _heading('Schemes')),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('New scheme'),
          onPressed: () => setState(() => _adding = true),
        ),
      ]),
      Wrap(spacing: 12, runSpacing: 12, children: [
        if (_adding)
          _SchemeCard(
              key: const ValueKey('new'),
              scheme: const {},
              onChanged: (schemes) {
                setState(() => _adding = false);
                widget.onChanged(schemes);
              }),
        for (Map scheme in widget.schemes)
          _SchemeCard(
              key: ValueKey(scheme['id']),
              scheme: scheme,
              onChanged: widget.onChanged),
      ]),
    ]);
  }
}

class _SchemeCard extends StatefulWidget {
  final Map scheme;
  final Function(List<Map>) onChanged;
  const _SchemeCard({super.key, required this.scheme, required this.onChanged});

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard> {
  late final Map scheme = widget.scheme;
  late final TextEditingController _name =
      TextEditingController(text: scheme['name'] ?? '');
  late final TextEditingController _description =
      TextEditingController(text: scheme['description'] ?? '');
  late final TextEditingController _price = TextEditingController(
      text: scheme['price_pence'] == null
          ? ''
          : (scheme['price_pence'] / 100).toStringAsFixed(2));
  late final TextEditingController _trial =
      TextEditingController(text: '${scheme['trial_days'] ?? 0}');
  late final TextEditingController _plans =
      TextEditingController(text: '${scheme['ai_plans_per_day'] ?? 10}');
  late final TextEditingController _budget = TextEditingController(
      text: scheme['ai_monthly_budget'] == null
          ? ''
          : '${scheme['ai_monthly_budget']}');
  late bool _forClubs = scheme['for_clubs'] ?? true;
  late String _period = scheme['period'] ?? 'month';

  @override
  void dispose() {
    for (TextEditingController c in [
      _name,
      _description,
      _price,
      _trial,
      _plans,
      _budget
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String inUse = scheme['id'] == null
        ? ''
        : ' - ${_plural(scheme['clubs'] ?? 0, 'club')}, '
            '${_plural(scheme['users'] ?? 0, 'user')}';
    return _section(
        scheme['id'] == null
            ? 'A new scheme'
            : '${scheme['name']}${scheme['retired'] == true ? ' (retired)' : ''}$inUse',
        [
          TextField(controller: _name, decoration: _field('Name')),
          const SizedBox(height: 8),
          TextField(
              controller: _description,
              maxLines: 2,
              decoration: _field('Description')),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('For clubs')),
              ButtonSegment(value: false, label: Text('For private users')),
            ],
            selected: {_forClubs},
            onSelectionChanged: (chosen) =>
                setState(() => _forClubs = chosen.first),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _price, decoration: _field('Price £'))),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: 'month', child: Text('a month')),
                DropdownMenuItem(value: 'year', child: Text('a year')),
              ],
              onChanged: (period) =>
                  setState(() => _period = period ?? _period),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _trial, decoration: _field('Trial days'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _plans, decoration: _field('AI plans a day'))),
          ]),
          if (_forClubs) ...[
            const SizedBox(height: 8),
            TextField(
                controller: _budget,
                decoration:
                    _field("Club's AI budget, \$ a month (blank: no cap)")),
          ],
          const SizedBox(height: 10),
          Row(children: [
            FilledButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(width: 8),
            if (scheme['id'] != null)
              TextButton(
                  onPressed: _delete,
                  child: Text('Delete',
                      style: TextStyle(color: Colors.red.shade700))),
          ]),
        ]);
  }

  Future<void> _save() async {
    var (schemes, problem) = await ConsoleService().saveScheme(scheme['id'], {
      'name': _name.text,
      'description': _description.text,
      'for_clubs': _forClubs,
      'price': _price.text.replaceAll('£', '').trim(),
      'period': _period,
      'trial_days': _trial.text.trim(),
      'ai_plans_per_day': _plans.text.trim(),
      'ai_monthly_budget': _forClubs ? _budget.text.trim() : '',
    });
    if (!mounted) return;
    _say(context, problem ?? 'Saved');
    if (schemes is List) widget.onChanged(List<Map>.from(schemes));
  }

  Future<void> _delete() async {
    var (result, problem) = await ConsoleService().deleteScheme(scheme['id']);
    if (!mounted) return;
    _say(
        context,
        problem ??
            (result['done'] == 'retired'
                ? "It's in use, so it's retired - it stays for those on it"
                : 'Deleted'));
    if (result is Map) widget.onChanged(List<Map>.from(result['schemes']));
  }
}

// ---- email ------------------------------------------------------------------------

class _EmailDetails extends StatefulWidget {
  const _EmailDetails({super.key});

  @override
  State<_EmailDetails> createState() => _EmailDetailsState();
}

class _EmailDetailsState extends State<_EmailDetails> {
  String _to = 'all';
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _heading('Email'),
      _section('To', width: 600, [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('Every Drives user')),
            ButtonSegment(
                value: 'club_admins', label: Text("Every club's admin")),
          ],
          selected: {_to},
          onSelectionChanged: (chosen) => setState(() => _to = chosen.first),
        ),
        const SizedBox(height: 8),
        Text(_to == 'all'
            ? "News, to everyone who hasn't unsubscribed - each email has a "
                'link to stop them.'
            : 'About running their club - to the admin of every club.'),
        const SizedBox(height: 12),
        TextField(
            controller: _subject,
            maxLength: 150,
            decoration: _field('Subject')),
        TextField(
            controller: _message,
            minLines: 8,
            maxLines: 20,
            maxLength: 5000,
            decoration: _field('Message')),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send'),
          onPressed: _sending ? null : _send,
        ),
      ]),
    ]);
  }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      return _say(context, 'The email needs a subject and a message');
    }
    bool send = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(_to == 'all'
                      ? 'Email every Drives user?'
                      : "Email every club's admin?"),
                  content: Text('"${_subject.text.trim()}"'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Send')),
                  ],
                )) ??
        false;
    if (!send) return;
    setState(() => _sending = true);
    var (result, problem) =
        await ConsoleService().email(_to, _subject.text, _message.text);
    if (!mounted) return;
    setState(() => _sending = false);
    _say(context,
        problem ?? 'Sent to ${_plural(result['sent'] ?? 0, 'person')}');
    if (problem == null) {
      _subject.clear();
      _message.clear();
    }
  }
}

// ---- feedback ---------------------------------------------------------------------

/// The feedback inbox - from the app and the website - newest first: open
/// (new and acknowledged) or all, each moved on with a status and a note
class _FeedbackDetails extends StatefulWidget {
  const _FeedbackDetails({super.key});

  @override
  State<_FeedbackDetails> createState() => _FeedbackDetailsState();
}

class _FeedbackDetailsState extends State<_FeedbackDetails> {
  static const List<String> _statuses = [
    'new',
    'acknowledged',
    'fixed',
    'closed'
  ];
  bool _all = false;
  List<Map> _items = [];
  Map _counts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var (inbox, problem) = await ConsoleService().feedback(all: _all);
    if (!mounted) return;
    _say(context, problem);
    if (inbox is Map) {
      setState(() {
        _items = List<Map>.from(inbox['items'] ?? []);
        _counts = Map.from(inbox['counts'] ?? {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int open = (_counts['new'] ?? 0) + (_counts['acknowledged'] ?? 0);
    return ListView(padding: const EdgeInsets.all(12), children: [
      _heading('Feedback'),
      Wrap(spacing: 8, runSpacing: 6, children: [
        ChoiceChip(
            label: Text('Open ($open)'),
            selected: !_all,
            onSelected: (_) {
              _all = false;
              _load();
            }),
        ChoiceChip(
            label: const Text('All'),
            selected: _all,
            onSelected: (_) {
              _all = true;
              _load();
            }),
      ]),
      const SizedBox(height: 12),
      if (_items.isEmpty)
        const Text('Nothing to look at', style: TextStyle(color: Colors.white)),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (Map item in _items)
          _FeedbackCard(
              key: ValueKey('${item['id']}${item['status']}'),
              item: item,
              statuses: _statuses,
              onChanged: _load),
      ]),
    ]);
  }
}

class _FeedbackCard extends StatefulWidget {
  final Map item;
  final List<String> statuses;
  final Future<void> Function() onChanged;
  const _FeedbackCard(
      {super.key,
      required this.item,
      required this.statuses,
      required this.onChanged});

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  late final TextEditingController _note =
      TextEditingController(text: widget.item['note'] ?? '');
  late String _status = widget.item['status'] ?? 'new';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map item = widget.item;
    String who = (item['name'] ?? '').toString().isEmpty
        ? (item['email'] ?? 'Someone')
        : '${item['name']} - ${item['email'] ?? ''}';
    String where = [
      item['source'] == 'app' ? 'the app' : 'the website',
      item['screen'],
      item['platform'],
      item['app_version'],
    ].where((part) => (part ?? '').toString().isNotEmpty).join(', ');
    return _section(
        '${(item['category'] ?? 'feedback').toString()[0].toUpperCase()}'
        '${(item['category'] ?? 'feedback').toString().substring(1)}'
        ' - ${item['added'] == null ? '' : _day.format(DateTime.parse(item['added']))}',
        width: 460,
        [
          Text(who, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('From $where', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Text(item['message'] ?? ''),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<String>(
              value: _status,
              items: [
                for (String s in widget.statuses)
                  DropdownMenuItem(value: s, child: Text(s))
              ],
              onChanged: (s) => setState(() => _status = s ?? _status),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _note, decoration: _field('Our note'))),
            TextButton(onPressed: _save, child: const Text('Save')),
          ]),
        ]);
  }

  Future<void> _save() async {
    var (_, problem) = await ConsoleService().updateFeedback(
        widget.item['id'], {'status': _status, 'note': _note.text});
    if (!mounted) return;
    _say(context, problem ?? 'Saved');
    if (problem == null) widget.onChanged();
  }
}
