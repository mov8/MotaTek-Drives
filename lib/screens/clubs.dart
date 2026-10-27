import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';

/// My clubs: invitations waiting, the clubs you're in, and finding a club to
/// ask to join. A club opens on its own page - with the admin's tabs
/// (profile, members, requests, invitations) for its admin. See
/// api/club_admin.py for the rules.
///
/// On the web it fills the SideDrawer; on a phone it's a page of its own.
class ClubsForm extends StatefulWidget {
  const ClubsForm({super.key});

  @override
  State<ClubsForm> createState() => _ClubsFormState();
}

class _ClubsFormState extends State<ClubsForm> {
  List _invitations = [];
  List _found = [];
  bool _searched = false;
  Map? _open; // the club being looked at - its profile
  final TextEditingController _search = TextEditingController();
  final TextEditingController _joinMessage = TextEditingController();

  bool get _loggedIn => Setup().jwt.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    _joinMessage.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_loggedIn) return;
    await ClubService().refresh();
    var (invitations, _) = await ClubService().invitations();
    if (mounted) setState(() => _invitations = invitations ?? []);
  }

  void _say(String? problem, [String done = '']) {
    String words = problem ?? done;
    if (words.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(words)));
    }
  }

  Future<void> _openClub(String clubId) async {
    var (club, problem) = await ClubService().profile(clubId);
    if (problem != null) return _say(problem);
    setState(() => _open = club);
  }

  @override
  Widget build(BuildContext context) {
    String prompt = _open == null ? 'My clubs' : _open!['name'] ?? 'Club';
    Widget content = ListenableBuilder(
      listenable: ClubService(),
      builder: (context, _) => _open == null ? _clubsList() : _clubPage(),
    );
    if (kIsWeb) {
      return ScreensAppBarBottom(
          prompt: prompt,
          textColor: const Color.fromRGBO(1, 29, 51, 1),
          content: content);
    }
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(heading: 'My clubs', prompt: prompt),
      body: content,
    );
  }

  // ---- the list ----------------------------------------------------------------

  Widget _clubsList() {
    ClubService clubs = ClubService();
    return ListView(padding: const EdgeInsets.all(10), children: [
      if (!_loggedIn)
        _note('Log in to see your clubs and their invitations. You can '
            'look for a club below.'),
      if (_invitations.isNotEmpty) ...[
        _heading('Invitations waiting'),
        for (Map invitation in _invitations)
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(invitation['club'] ?? ''),
              subtitle: Text([
                if ((invitation['invited_by'] ?? '').isNotEmpty)
                  'From ${invitation['invited_by']}',
                if ((invitation['message'] ?? '').isNotEmpty)
                  '"${invitation['message']}"',
              ].join('\n')),
              trailing: Wrap(children: [
                TextButton(
                    onPressed: () => _answer(invitation, false),
                    child: const Text('Decline')),
                FilledButton(
                    onPressed: () => _answer(invitation, true),
                    child: const Text('Join')),
              ]),
            ),
          ),
      ],
      if (_loggedIn) ...[
        _heading('My clubs'),
        if (!clubs.inAnyClub)
          _note("You're not in a club yet. Many owners' clubs use Drives for "
              'their news, events and group drives - find yours below.'),
        for (Club club in clubs.clubs)
          Card(
            child: ListTile(
              leading: Icon(club.isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.groups_outlined),
              title: Text(club.name),
              subtitle:
                  Text(club.isAdmin ? 'You look after this club' : 'Member'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openClub(club.id),
            ),
          ),
      ],
      _heading('Find a club'),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _find(),
            decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                hintText: 'A club\'s name - e.g. MG, Triumph, Austin Healey'),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _find, child: const Text('Find')),
      ]),
      if (_searched && _found.isEmpty)
        _note('No club by that name uses Drives yet. Why not tell your '
            "club's secretary about it?"),
      for (Map club in _found)
        Card(
          child: ListTile(
            leading: _logo(club, 40),
            title: Text(club['name'] ?? ''),
            subtitle: Text(
                '${club['members']} member${club['members'] == 1 ? '' : 's'}'
                '${(club['description'] ?? '').isEmpty ? '' : ' - ${club['description']}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openClub(club['id']),
          ),
        ),
    ]);
  }

  Future<void> _find() async {
    var (found, problem) = await ClubService().search(_search.text);
    if (problem != null) return _say(problem);
    setState(() {
      _found = found ?? [];
      _searched = true;
    });
  }

  Future<void> _answer(Map invitation, bool accept) async {
    String? problem = await ClubService().answer(invitation['id'], accept);
    _say(problem, accept ? 'Welcome to ${invitation['club']}' : '');
    await _refresh();
  }

  // ---- a club's own page -------------------------------------------------------

  Widget _clubPage() {
    Map club = _open!;
    String role = club['role'] ?? '';
    Widget about = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _logo(club, 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(club['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          if ((club['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(club['description']),
          ],
          const SizedBox(height: 8),
          Text('${club['members']} members'),
          if ((club['website'] ?? '').isNotEmpty)
            InkWell(
              onTap: () => launchUrl(Uri.parse(
                  club['website'].startsWith('http')
                      ? club['website']
                      : 'https://${club['website']}')),
              child: Text(club['website'],
                  style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline)),
            ),
          if ((club['contact_email'] ?? '').isNotEmpty)
            Text('Contact: ${club['contact_email']}'),
        ]),
      ),
    );
    Widget back = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.arrow_back),
        label: const Text('My clubs'),
        onPressed: () {
          setState(() => _open = null);
          _refresh();
        },
      ),
    );
    if (role == 'admin') {
      return Column(children: [
        back,
        Expanded(
            child: ClubAdminPanel(
                club: club,
                onChanged: (changed) => setState(() => _open = changed))),
      ]);
    }
    return ListView(padding: const EdgeInsets.all(10), children: [
      back,
      about,
      const SizedBox(height: 8),
      if (role == 'member')
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Leave the club'),
            onPressed: () => _leave(club),
          ),
        )
      else if (!_loggedIn)
        _note('Log in to ask to join the club.')
      else if (ClubService().inAnyClub)
        _note("You're in ${ClubService().clubs.first.name}. A Drives account "
            'can be in one club - to join another, use a separate account, '
            'with another email address, as with any app.')
      else if (club['invitation'] != null)
        _note("You've been invited - see Invitations waiting in My clubs.")
      else if (club['request'] == 'pending')
        _note("You've asked to join - the club's admin will let you know.")
      else ...[
        TextField(
          controller: _joinMessage,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              hintText: 'A note for the club, e.g. which car you have '
                  '(optional)'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Ask to join'),
            onPressed: () => _askToJoin(club),
          ),
        ),
      ],
    ]);
  }

  Future<void> _askToJoin(Map club) async {
    var (_, problem) =
        await ClubService().askToJoin(club['id'], _joinMessage.text);
    _say(problem, 'Your request has gone to the club');
    if (problem == null) await _openClub(club['id']);
  }

  Future<void> _leave(Map club) async {
    bool sure = await _confirm('Leave ${club['name']}?',
        "You'll no longer see the club's pages or events.");
    if (!sure) return;
    String? problem = await ClubService().leave(club['id']);
    _say(problem, 'You have left ${club['name']}');
    if (problem == null) setState(() => _open = null);
  }

  Future<bool> _confirm(String title, String words) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(words),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes')),
          ],
        ),
      ) ??
      false;
}

Widget _heading(String words) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(words,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );

Widget _note(String words) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(words, style: const TextStyle(fontSize: 15)),
    );

Widget _logo(Map club, double size) => (club['logo'] ?? '').isEmpty
    ? Icon(Icons.groups_outlined, size: size * 0.8)
    : ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(club['logo'],
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.groups_outlined, size: size * 0.8)),
      );

/// The admin's tabs: the club's profile, its members, requests to join and
/// invitations
class ClubAdminPanel extends StatefulWidget {
  final Map club;
  final Function(Map) onChanged; // the profile, changed
  const ClubAdminPanel(
      {super.key, required this.club, required this.onChanged});

  @override
  State<ClubAdminPanel> createState() => _ClubAdminPanelState();
}

class _ClubAdminPanelState extends State<ClubAdminPanel> {
  late final TextEditingController _description =
      TextEditingController(text: widget.club['description'] ?? '');
  late final TextEditingController _website =
      TextEditingController(text: widget.club['website'] ?? '');
  late final TextEditingController _contact =
      TextEditingController(text: widget.club['contact_email'] ?? '');
  final TextEditingController _emails = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _news = TextEditingController();
  bool _sending = false;
  String _emailed = '';
  List _members = [];
  List _requests = [];
  List _outstanding = [];
  String _sent = '';

  String get _id => widget.club['id'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (TextEditingController c in [
      _description,
      _website,
      _contact,
      _emails,
      _message,
      _subject,
      _news
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    var (members, _) = await ClubService().members(_id);
    var (requests, _) = await ClubService().requests(_id);
    var (outstanding, _) = await ClubService().outstanding(_id);
    if (!mounted) return;
    setState(() {
      _members = members ?? [];
      _requests = requests ?? [];
      _outstanding = outstanding ?? [];
    });
  }

  void _say(String? problem, [String done = '']) {
    String words = problem ?? done;
    if (words.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(words)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(children: [
        Material(
          color: Colors.white,
          child: TabBar(isScrollable: true, tabs: [
            const Tab(text: 'Profile'),
            Tab(text: 'Members (${_members.length})'),
            Tab(text: 'Requests (${_requests.length})'),
            const Tab(text: 'Invite'),
            const Tab(text: 'Email members'),
          ]),
        ),
        Expanded(
          child: TabBarView(children: [
            _profileTab(),
            _membersTab(),
            _requestsTab(),
            _inviteTab(),
            _emailTab(),
          ]),
        ),
      ]),
    );
  }

  InputDecoration _field(String label, [String hint = '']) => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
      labelText: label,
      hintText: hint);

  Widget _profileTab() =>
      ListView(padding: const EdgeInsets.all(10), children: [
        _standing(),
        const SizedBox(height: 12),
        Row(children: [
          _logo(widget.club, 64),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.image_outlined),
            label: const Text('Choose a logo'),
            onPressed: _chooseLogo,
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: _description,
            maxLines: 4,
            maxLength: 2000,
            decoration: _field(
                'About the club', 'What people see when they find the club')),
        const SizedBox(height: 8),
        TextField(controller: _website, decoration: _field('Website')),
        const SizedBox(height: 8),
        TextField(
            controller: _contact,
            keyboardType: TextInputType.emailAddress,
            decoration: _field('Contact email')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child:
              FilledButton(onPressed: _saveProfile, child: const Text('Save')),
        ),
        _note("The club's name is set by Drives - contact us to change it."),
      ]);

  /// How the club stands with Drives - its members on the app, and its
  /// subscription (MotaTek records payments, on the website)
  Widget _standing() {
    String? paid = widget.club['paid_until'];
    DateTime? until = paid == null ? null : DateTime.parse(paid);
    bool current =
        until != null && !until.isBefore(DateUtils.dateOnly(DateTime.now()));
    String when = until == null ? '' : DateFormat('d MMMM yyyy').format(until);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text('${widget.club['members'] ?? 0} '
            'member${widget.club['members'] == 1 ? '' : 's'} on Drives'),
        subtitle: Text(
            until == null
                ? 'Subscription: no payment recorded yet'
                : current
                    ? 'Subscription paid until $when'
                    : 'Subscription ended on $when',
            style: current ? null : TextStyle(color: Colors.red.shade700)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    var (club, problem) = await ClubService().updateProfile(_id, {
      'description': _description.text,
      'website': _website.text,
      'contact_email': _contact.text,
    });
    _say(problem, 'Saved');
    if (club is Map) widget.onChanged({...club, 'role': 'admin'});
  }

  Future<void> _chooseLogo() async {
    XFile? picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    var (club, problem) = await ClubService()
        .uploadLogo(_id, await picked.readAsBytes(), picked.name);
    _say(problem, 'Logo saved');
    if (club is Map) widget.onChanged({...club, 'role': 'admin'});
  }

  Widget _membersTab() =>
      ListView(padding: const EdgeInsets.all(10), children: [
        if (_members.isEmpty) _note('No members yet - invite some.'),
        for (Map member in _members)
          Card(
            child: ListTile(
              leading: Icon(member['role'] == 'admin'
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline),
              title: Text(
                  '${member['forename'] ?? ''} ${member['surname'] ?? ''}'
                      .trim()),
              subtitle: Text(
                  '${member['email']}${member['role'] == 'admin' ? ' - admin' : ''}'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _memberAction(member, action),
                itemBuilder: (_) => [
                  if (member['role'] != 'admin')
                    const PopupMenuItem(
                        value: 'admin', child: Text('Make admin'))
                  else
                    const PopupMenuItem(
                        value: 'member',
                        child: Text('Make an ordinary member')),
                  const PopupMenuItem(
                      value: 'remove', child: Text('Remove from the club')),
                ],
              ),
            ),
          ),
      ]);

  Future<void> _memberAction(Map member, String action) async {
    var (members, problem) = action == 'remove'
        ? await ClubService().remove(_id, member['id'])
        : await ClubService().setRole(_id, member['id'], action);
    _say(problem);
    if (members is List) setState(() => _members = members);
  }

  Widget _requestsTab() =>
      ListView(padding: const EdgeInsets.all(10), children: [
        if (_requests.isEmpty)
          _note('No requests to join just now. People who find the club in '
              'Drives can ask to join.'),
        for (Map request in _requests)
          Card(
            child: ListTile(
              title: Text(
                  '${request['forename'] ?? ''} ${request['surname'] ?? ''}'
                      .trim()),
              subtitle: Text([
                request['email'] ?? '',
                if ((request['message'] ?? '').isNotEmpty)
                  '"${request['message']}"',
              ].join('\n')),
              trailing: Wrap(children: [
                TextButton(
                    onPressed: () => _decide(request, false),
                    child: const Text('Decline')),
                FilledButton(
                    onPressed: () => _decide(request, true),
                    child: const Text('Let in')),
              ]),
            ),
          ),
      ]);

  Future<void> _decide(Map request, bool approve) async {
    var (requests, problem) =
        await ClubService().decide(_id, request['id'], approve);
    _say(problem);
    if (requests is List) {
      setState(() => _requests = requests);
      if (approve) _load(); // a new member
    }
  }

  Widget _inviteTab() => ListView(padding: const EdgeInsets.all(10), children: [
        _note('Paste the email addresses of the people to invite - one, or '
            'your whole membership list. Any separators will do. Each is '
            'emailed an invitation, which waits for them in Drives (after '
            'they register, if they don\'t use Drives yet).'),
        TextField(
            controller: _emails,
            minLines: 4,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: _field('Email addresses')),
        const SizedBox(height: 8),
        TextField(
            controller: _message,
            maxLines: 3,
            maxLength: 500,
            decoration: _field('A message with the invitation (optional)')),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send invitations'),
            onPressed: _invite,
          ),
        ),
        if (_sent.isNotEmpty) _note(_sent),
        if (_outstanding.isNotEmpty) ...[
          _heading('Invitations not yet accepted'),
          for (Map invitation in _outstanding)
            Card(
              child: ListTile(
                title: Text(invitation['email'] ?? ''),
                subtitle: Text(invitation['status'] == 'declined'
                    ? 'Declined'
                    : 'Waiting since ${(invitation['created'] ?? '').toString().split(' ').take(4).join(' ')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Withdraw',
                  onPressed: () => _withdraw(invitation),
                ),
              ),
            ),
        ],
      ]);

  Future<void> _invite() async {
    var (result, problem) =
        await ClubService().invite(_id, _emails.text, _message.text);
    if (problem != null) return _say(problem);
    int count(String key) => (result[key] as List?)?.length ?? 0;
    setState(() {
      _sent = [
        '${count('invited')} invited',
        if (count('already_invited') > 0)
          '${count('already_invited')} invited again',
        if (count('already_members') > 0)
          '${count('already_members')} already members',
        if (count('in_another_club') > 0)
          "${count('in_another_club')} in another club (they'd need another "
              'account)',
      ].join(', ');
      _emails.clear();
    });
    var (outstanding, _) = await ClubService().outstanding(_id);
    if (mounted && outstanding is List) {
      setState(() => _outstanding = outstanding);
    }
  }

  Future<void> _withdraw(Map invitation) async {
    var (outstanding, problem) =
        await ClubService().withdraw(_id, invitation['id']);
    _say(problem);
    if (outstanding is List) setState(() => _outstanding = outstanding);
  }

  Widget _emailTab() => ListView(padding: const EdgeInsets.all(10), children: [
        _note('An email to every member of ${widget.club['name']} - news, '
            'or an event, alongside your newsletter. It comes from Drives, '
            'with your name at the bottom. A few a day at most.'),
        TextField(
            controller: _subject,
            maxLength: 150,
            decoration: _field('Subject')),
        TextField(
            controller: _news,
            minLines: 6,
            maxLines: 16,
            maxLength: 5000,
            keyboardType: TextInputType.multiline,
            decoration: _field('Message')),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: Text(
                'Send to ${_members.length} member${_members.length == 1 ? '' : 's'}'),
            onPressed: _sending ? null : _emailMembers,
          ),
        ),
        if (_emailed.isNotEmpty) _note(_emailed),
      ]);

  Future<void> _emailMembers() async {
    if (_subject.text.trim().isEmpty || _news.text.trim().isEmpty) {
      return _say('The email needs a subject and a message');
    }
    bool send = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Email every member?'),
                  content: Text(
                      '"${_subject.text.trim()}" goes to ${_members.length} member${_members.length == 1 ? '' : 's'}.'),
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
        await ClubService().emailMembers(_id, _subject.text, _news.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (problem != null) return _say(problem);
    setState(() {
      _emailed =
          'Sent to ${result['sent']} member${result['sent'] == 1 ? '' : 's'}';
      _subject.clear();
      _news.clear();
    });
  }
}
