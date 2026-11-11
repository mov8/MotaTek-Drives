import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/constants.dart';
import '/theme.dart';
import '/models/models.dart';
import '/services/services.dart';

/// AI assist in the drawer: the user's request, then what was understood as
/// chips they can change (Plan again), the suggested trip's time, distance
/// and roads, and its stops. The trip itself is on the map - see
/// PlannerService.
class PlannerPanel extends StatefulWidget {
  const PlannerPanel({super.key});

  @override
  State<PlannerPanel> createState() => _PlannerPanelState();
}

const Map<String, String> _interests = {
  'sights': 'Sights',
  'viewpoint': 'Viewpoints',
  'castle': 'Castles',
  'historic': 'Historic sites',
  'church': 'Churches',
  'windmill': 'Windmills',
  'museum': 'Museums',
  'attraction': 'Attractions',
  'nature': 'Nature',
  'birdwatching': 'Bird watching',
  'village': 'Villages',
  'park': 'Parks and gardens',
  'woods': 'Woods and forests',
  'coast': 'The coast',
  'zoo': 'Zoos and wildlife parks',
  'railway': 'Heritage railways',
  'motorsport': 'Motor racing',
  'picnic': 'Picnic spots',
  'pub': 'Pubs',
  'cafe': 'Cafés',
  'restaurant': 'Restaurants',
};

// A stop's kind -> (one, several)
const Map<String, (String, String)> _stops = {
  'pub': ('Pub', 'pubs'),
  'cafe': ('Café', 'cafés'),
  'restaurant': ('Restaurant', 'restaurants'),
  'picnic': ('Picnic spot', 'picnic spots'),
  'fuel': ('Fuel', 'fuel stops'),
  'toilets': ('Toilets', 'toilets'),
};

const Map<String, String> _when = {
  'start': 'at the start',
  'early': 'early on',
  'halfway': 'halfway',
  'late': 'later on',
  'end': 'at the end',
  'any': 'on the way',
};

const List<int> _times = [60, 90, 120, 150, 180, 240, 300];

// The plan's field for each route preference, named as in Settings
const List<(String, String)> _routePreferences = [
  ('avoid_motorways', 'Avoid motorways'),
  ('quiet_roads', 'Avoid main roads'),
  ('avoid_ferries', 'Avoid ferries'),
  ('avoid_tolls', 'Avoid toll roads'),
];

// The colours of UK road signs: blue motorways, green primary A roads
const List<(String, String, Color)> _roadTypes = [
  ('motorway', 'Motorways', Color(0xFF1565C0)),
  ('a_road', 'A roads', Color(0xFF2E7D32)),
  ('b_road', 'B roads', Color(0xFFF9A825)),
  ('minor', 'Lanes and minor roads', Color(0xFF9E9E9E)),
];

String _duration(num minutes) {
  int m = minutes.round();
  if (m < 60) return '$m min';
  return '${m ~/ 60} h${m % 60 > 0 ? ' ${m % 60} min' : ''}';
}

String _miles(num km) {
  double miles = km * 0.621371;
  return miles < 10 ? miles.toStringAsFixed(1) : miles.round().toString();
}

IconData _iconOf(String? kind) => switch (kind) {
      'pub' => Icons.sports_bar,
      'cafe' => Icons.local_cafe,
      'restaurant' => Icons.restaurant,
      'castle' => Icons.castle,
      'historic' => Icons.account_balance,
      'church' => Icons.church,
      'windmill' => Icons.wind_power,
      'museum' => Icons.museum,
      'viewpoint' => Icons.landscape,
      'nature' || 'birdwatching' => Icons.park,
      'village' || 'town' => Icons.holiday_village,
      'attraction' => Icons.attractions,
      'park' => Icons.local_florist,
      'woods' => Icons.forest,
      'coast' => Icons.beach_access,
      'zoo' => Icons.pets,
      'railway' => Icons.train,
      'motorsport' => Icons.sports_score,
      'picnic' => Icons.deck,
      _ => Icons.place,
    };

class _PlannerPanelState extends State<PlannerPanel> {
  late final TextEditingController _request =
      TextEditingController(text: PlannerService().request);

  @override
  void initState() {
    super.initState();
    PlannerService().checkAllowance();
  }

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AI assist's own colours, for everything in it
    return Theme(
      data: aiTheme(Theme.of(context)),
      child: ListenableBuilder(
        listenable: PlannerService(),
        builder: (context, _) {
          PlannerService planner = PlannerService();
          bool working = planner.status == PlannerStatus.working;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome, color: DrivesColours.current.ai),
                  const SizedBox(width: 8),
                  Text('Auto-route',
                      style: Theme.of(context).textTheme.titleLarge),
                ]),
                const SizedBox(height: 12),
                if (planner.status == PlannerStatus.done)
                  ..._result(context, planner)
                else if (planner.status == PlannerStatus.choose)
                  ..._choose(context, planner)
                else ...[
                  if (planner.needsLogin)
                    _logIn(context)
                  else if (!planner.canPlan)
                    _noneLeft(context, planner.allowance!),
                  TextField(
                    controller: _request,
                    enabled: !working && planner.canPlan,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Describe the drive you'd like - e.g. a two "
                          'hour loop from Boston with some interesting places '
                          'to see, and a pub about halfway',
                    ),
                  ),
                  Text('Your route preferences (as in Settings)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _preferences(working),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Plan my trip'),
                    onPressed: working || !planner.canPlan
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            planner.plan(_request.text);
                          },
                  ),
                  const SizedBox(height: 8),
                  if (working)
                    Row(children: [
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(planner.progress)),
                    ])
                  else if (planner.message.isNotEmpty)
                    Text(planner.message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))
                  else
                    Text(
                        'It starts from where you are unless you name a town. '
                        'Places come from OpenStreetMap and Drives users.'
                        '${_left(planner.allowance)}',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Before a request is written: AI assist needs a login. The login screen
  /// is in the SideDrawer on the web, and goes back to the page when it
  /// closes; on a phone they come back here.
  Widget _logIn(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log in to use Auto-route'),
          TextButton(
              onPressed: () async {
                if (kIsWeb) {
                  MapService()
                      .sideDrawerController
                      ?.setContent(content: BottomDrawerItems.login);
                  return;
                }
                await context.push('/login');
                await PlannerService().checkAllowance();
                if (mounted) setState(() {});
              },
              child: const Text('Log in')),
        ]),
      ),
    );
  }

  /// Before a request is written: they aren't paid up (api/payments.py),
  /// or they've had all their plans for now
  Widget _noneLeft(BuildContext context, Map allowance) {
    if (allowance['entitled'] == false) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(allowance['reason'] ?? "Auto-route isn't available"),
            if (allowance['subscribed'] == false && urlSubscribe.isNotEmpty)
              TextButton(
                  onPressed: () => launchUrl(Uri.parse(urlSubscribe),
                      mode: LaunchMode.externalApplication),
                  child: const Text('Find out more')),
          ]),
        ),
      );
    }
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
        child: Text(
            "You've had all ${allowance['limit']} of your Auto-route plans for "
            'the last 24 hours. You can plan another $when.'),
      ),
    );
  }

  /// How many plans are left, once some have been used
  String _left(Map? allowance) {
    if (allowance == null || (allowance['used'] ?? 0) == 0) return '';
    int left = (allowance['limit'] ?? 0) - (allowance['used'] ?? 0);
    return ' You have $left Auto-route plan${left == 1 ? '' : 's'} left for now.';
  }

  /// The user's route preferences before planning - their settings, which
  /// the Fab menu changes too. The planner adds them to the request.
  Widget _preferences(bool working) {
    bool setting(String field) => switch (field) {
          'avoid_motorways' => Setup().avoidMotorways,
          'quiet_roads' => Setup().avoidAroads,
          'avoid_ferries' => Setup().avoidFerries,
          _ => Setup().avoidTollRoads,
        };
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (var (field, name) in _routePreferences)
        FilterChip(
          label: Text(name),
          selected: setting(field),
          onSelected: working
              ? null
              : (on) => setState(() => switch (field) {
                    'avoid_motorways' => Setup().avoidMotorways = on,
                    'quiet_roads' => Setup().avoidAroads = on,
                    'avoid_ferries' => Setup().avoidFerries = on,
                    _ => Setup().avoidTollRoads = on,
                  }),
        ),
    ]);
  }

  List<Widget> _result(BuildContext context, PlannerService planner) {
    Map<String, dynamic> trip = planner.trip;
    TextTheme text = Theme.of(context).textTheme;
    Map? published = trip['published_trip'];
    List stops = trip['stops'] ?? [];
    List choices = trip['choices'] ?? [];
    num minutes = trip['minutes'] ?? 0;
    // The overview shows at once - is it the sort of drive they want? - and
    // the rest is there to open
    return [
      Text(trip['title'] ?? '', style: text.titleMedium),
      if ((trip['tagline'] ?? '').toString().isNotEmpty)
        Text(trip['tagline'],
            style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
      const SizedBox(height: 4),
      Text(trip['summary'] ?? ''),
      const SizedBox(height: 12),
      _roads(trip, text),
      if ((trip['checks'] ?? []).isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('What you asked for', style: text.titleSmall),
        const SizedBox(height: 4),
        for (Map check in trip['checks']) _check(check, text),
      ],
      // In their own words - the checks are what was made of them
      if (planner.request.isNotEmpty)
        _section(
            'Your request',
            [
              Text(planner.request,
                  style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic))
            ],
            text),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: planner.newRequest,
          child: const Text('Ask for something else'),
        ),
      ),
      if (stops.isNotEmpty) ...[
        Text('Stops', style: text.titleSmall),
        for (Map stop in stops) _place(stop, minutes),
      ],
      if (choices.isNotEmpty)
        _section(
            'Or stop instead (${choices.length})',
            [
              Text('Put the crosshair on one and tap Waypoint to add it.',
                  style: text.bodySmall),
              for (Map choice in choices) _place(choice, minutes),
            ],
            text),
      if ((trip['guide'] ?? '').toString().isNotEmpty)
        _section('Guide to the drive', [Text(trip['guide'])], text),
      _section(
          'Change what you asked for',
          [
            _understood(planner),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Plan again'),
                onPressed: planner.edited ? planner.planAgain : null,
              ),
            ),
          ],
          text,
          open: planner.edited),
      _section("What's on the map", [_key(text)], text),
      if (published != null) ...[
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Someone has published a trip like this'),
            subtitle: Text('"${published['title']}"'
                '${(published['driven'] ?? 0) > 0 ? ' - driven by ${published['driven']}' : ''}'
                '. Find it in Published.'),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
              'Auto-route builds trips only from real places in Drives and '
              'OpenStreetMap - but check the roads, opening times and food '
              'before you go. Change the route as usual, then Save trip.',
              style: text.bodySmall),
        ),
      ]),
    ];
  }

  /// A start or finish named in several places that are close calls - the
  /// user picks the one they meant, and it's planned
  List<Widget> _choose(BuildContext context, PlannerService planner) {
    TextTheme text = Theme.of(context).textTheme;
    return [
      Text(planner.message, style: text.titleMedium),
      for (String key in ['start', 'finish'])
        if (planner.fields?[key] case Map place
            when place['unsure'] == true) ...[
          const SizedBox(height: 8),
          Text(key == 'start' ? 'To start from:' : 'To finish at:',
              style: text.titleSmall),
          for (Map option in [place, ...?place['options']])
            Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: Icon(_iconOf(['city', 'town'].contains(option['what'])
                    ? 'town'
                    : 'village')),
                title: Text(option['name'] ?? ''),
                subtitle: Text(_placeDetail(option)),
                onTap: () => planner.choosePlace(key, option),
              ),
            ),
        ],
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: planner.newRequest,
          child: const Text('Ask for something else'),
        ),
      ),
    ];
  }

  /// e.g. "West Sussex · town"
  String _placeDetail(Map place) => [place['county'] ?? '', place['what'] ?? '']
      .where((part) => part.toString().isNotEmpty)
      .join(' · ');

  /// The time and distance, and how much is on each type of road
  Widget _roads(Map<String, dynamic> trip, TextTheme text) {
    Map types = trip['road_types'] ?? {};
    double total =
        types.values.fold(0.0, (sum, km) => sum + (km as num).toDouble());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: _figure('Driving', _duration(trip['minutes'] ?? 0), text)),
        Expanded(
            child:
                _figure('Distance', '${_miles(trip['km'] ?? 0)} miles', text)),
      ]),
      if (total > 0) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(children: [
              for (var (kind, _, colour) in _roadTypes)
                if ((types[kind] ?? 0) > 0)
                  Expanded(
                      flex:
                          ((types[kind] as num) * 10).round().clamp(1, 1 << 20),
                      child: ColoredBox(color: colour)),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(20),
            1: FlexColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: FixedColumnWidth(48),
          },
          children: [
            for (var (kind, name, colour) in _roadTypes)
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 10, height: 10, color: colour)),
                ),
                Text(name),
                Text('${_miles(types[kind] ?? 0)} mi',
                    textAlign: TextAlign.right),
                Text('${(100 * (types[kind] ?? 0) / total).round()}%',
                    textAlign: TextAlign.right),
              ]),
          ],
        ),
      ],
    ]);
  }

  /// What the AI colour's dots on the map are
  Widget _key(TextTheme text) {
    Color ai = colourList[Setup().aiRouteColour];
    Widget dot(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: ai.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5)));
    Widget line(Widget symbol, String words) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 22, child: Center(child: symbol)),
            const SizedBox(width: 6),
            Expanded(child: Text(words, style: text.bodySmall)),
          ]),
        );
    return Column(children: [
      line(Container(width: 18, height: 4, color: ai),
          'The suggested route - in this colour until you save it'),
      line(dot(16), 'Bigger dots: the other choices of places to stop'),
      line(
          dot(10),
          'Small dots: other places Auto-route found. Move the crosshair onto '
          'one and its name shows under the crosshair - Waypoint adds it'),
    ]);
  }

  Widget _figure(String label, String value, TextTheme text) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: text.bodySmall),
        Text(value, style: text.titleMedium),
      ]);

  /// What was understood, as chips - those that can change are deletable
  /// or have a menu, and changing any offers Plan again
  Widget _understood(PlannerService planner) {
    Map<String, dynamic> f = planner.fields ?? {};
    List interests = f['interests'] ?? [];
    List stops = f['stops'] ?? [];
    // With its county, so a name in several places shows which it found
    String placeName(dynamic place) => place is! Map
        ? '$place'
        : (place['county'] ?? '').toString().isEmpty ||
                place['county'] == place['name']
            ? place['name'] ?? ''
            : '${place['name']}, ${place['county']}';
    Widget limited(String words) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(words, overflow: TextOverflow.ellipsis));
    // A start or finish named in several places has a menu of the others
    Widget placeChip(String key, IconData icon, String words) {
      dynamic place = f[key];
      List options = place is Map ? place['options'] ?? [] : [];
      Widget chip = Chip(
          avatar: Icon(icon, size: 18),
          label: limited(options.isEmpty ? words : '$words ▾'));
      return options.isEmpty
          ? chip
          : PopupMenuButton<Map>(
              tooltip: 'Another place with this name',
              onSelected: (option) => planner.choosePlace(key, option),
              itemBuilder: (_) => [
                for (Map option in options)
                  PopupMenuItem(
                      value: option,
                      child:
                          Text('${option['name']} - ${_placeDetail(option)}')),
              ],
              child: chip,
            );
    }

    return Wrap(spacing: 6, runSpacing: 6, children: [
      placeChip('start', Icons.trip_origin, 'From ${placeName(f['start'])}'),
      f['finish'] != null
          ? placeChip(
              'finish', Icons.flag_outlined, 'To ${placeName(f['finish'])}')
          : const Chip(
              avatar: Icon(Icons.loop, size: 18), label: Text('Round trip')),
      for (String via in f['via'] ?? [])
        Chip(
            avatar: const Icon(Icons.alt_route, size: 18),
            label: Text('Via $via')),
      PopupMenuButton<int>(
        tooltip: 'How long',
        onSelected: (minutes) =>
            planner.changeField('minutes', minutes == 0 ? null : minutes),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 0, child: Text('Any length')),
          for (int minutes in _times)
            PopupMenuItem(value: minutes, child: Text(_duration(minutes))),
        ],
        child: Chip(
            avatar: const Icon(Icons.schedule, size: 18),
            label: Text(f['minutes'] == null
                ? 'Any length'
                : 'About ${_duration(f['minutes'])}')),
      ),
      for (String interest in interests)
        InputChip(
          avatar: Icon(_iconOf(interest), size: 18),
          label: Text(_interests[interest] ?? interest),
          onDeleted: () => planner.changeField(
              'interests', [...interests]..remove(interest)),
        ),
      PopupMenuButton<String>(
        tooltip: 'Something to see',
        onSelected: (interest) =>
            planner.changeField('interests', [...interests, interest]),
        itemBuilder: (_) => [
          for (MapEntry<String, String> interest in _interests.entries)
            if (!interests.contains(interest.key))
              PopupMenuItem(value: interest.key, child: Text(interest.value)),
        ],
        child: const Chip(
            avatar: Icon(Icons.add, size: 18), label: Text('Something to see')),
      ),
      for (int i = 0; i < stops.length; i++)
        InputChip(
          avatar: Icon(_iconOf(stops[i]['kind']), size: 18),
          label: Text(_stopLabel(stops[i])),
          onDeleted: () =>
              planner.changeField('stops', [...stops]..removeAt(i)),
        ),
      PopupMenuButton<String>(
        tooltip: 'A stop',
        onSelected: (kind) => planner.changeField('stops', [
          ...stops,
          {'kind': kind, 'when': 'halfway', 'choices': 1}
        ]),
        itemBuilder: (_) => [
          for (MapEntry<String, (String, String)> stop in _stops.entries)
            PopupMenuItem(value: stop.key, child: Text(stop.value.$1)),
        ],
        child: const Chip(
            avatar: Icon(Icons.add, size: 18), label: Text('A stop')),
      ),
      // The route preferences - turning one off relaxes it (and the setting)
      for (var (field, name) in _routePreferences)
        FilterChip(
          label: Text(name),
          selected: f[field] == true,
          onSelected: (on) => planner.changeRoutePreference(field, on),
        ),
      if ((f['notes'] ?? '').toString().isNotEmpty)
        InputChip(
          label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(f['notes'], overflow: TextOverflow.ellipsis)),
          onDeleted: () => planner.changeField('notes', ''),
        ),
    ]);
  }

  String _stopLabel(Map stop) {
    (String, String) names = _stops[stop['kind']] ?? ('Stop', 'stops');
    String when = _when[stop['when']] ?? '';
    int choices = stop['choices'] ?? 1;
    return choices > 1
        ? 'Choice of $choices ${names.$2} $when'
        : '${names.$1} $when';
  }

  /// A link under a stop: where something came from
  Widget _link(String words, String url, TextTheme text) => InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(words,
              style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline)),
        ),
      );

  /// Something asked for, and whether the trip does it - the server checks
  /// it from what was measured and found, not from what AI assist says
  Widget _check(Map check, TextTheme text) {
    ColorScheme colours = Theme.of(context).colorScheme;
    bool ok = check['ok'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 20, color: ok ? colours.primary : colours.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '${check['wanted']}: ', style: text.bodyMedium),
            TextSpan(
                text: check['got'] ?? '',
                style: text.bodyMedium?.copyWith(
                    color: ok ? null : colours.error,
                    fontWeight: FontWeight.w500)),
          ])),
        ),
      ]),
    );
  }

  /// A part of the result that opens when wanted
  Widget _section(String title, List<Widget> children, TextTheme text,
          {bool open = false}) =>
      ExpansionTile(
        title: Text(title, style: text.titleSmall),
        initiallyExpanded: open,
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );

  /// A stop or choice: closed, its name, what it is, where it is in the trip
  /// and its rating; opened, why it was chosen, its story with where that
  /// came from, what Wikipedia says, what users said, and showing it on
  /// the map
  Widget _place(Map place, num tripMinutes) {
    TextTheme text = Theme.of(context).textTheme;
    List<String> facts = [placeWhat(place)];
    if (place['along'] != null && tripMinutes > 0) {
      facts.add('about ${_duration((place['along'] as num) * tripMinutes)} in');
    }
    if ((place['ratings'] ?? 0) > 0) {
      facts.add('★ ${(place['rating'] ?? 0).toStringAsFixed(1)} '
          '(${place['ratings']})');
    }
    List reviews = place['reviews'] ?? [];
    Map? wikipedia = place['wikipedia'];
    String thumbnail = wikipedia?['thumbnail'] ?? '';
    String story = place['story'] ?? '';
    String about = wikipedia?['extract'] ?? place['description'] ?? '';
    Widget icon =
        SizedBox(width: 44, child: Icon(_iconOf(place['kind']), size: 28));
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.only(left: 8, right: 8),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: thumbnail.isEmpty
            ? icon
            : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(thumbnail,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => icon)),
        title: Text(place['name'] ?? '', style: text.titleSmall),
        subtitle: Text(facts.join(' · '), style: text.bodySmall),
        children: [
          if ((place['why'] ?? '').toString().isNotEmpty)
            Text('Chosen because: ${place['why']}',
                style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          if (story.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(story, style: text.bodySmall),
            for (Map source in place['sources'] ?? [])
              _link(
                  'Source: ${sourceName(source['url'])}', source['url'], text),
          ],
          if (about.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(about, style: text.bodySmall),
          ],
          if ((wikipedia?['url'] ?? '').toString().isNotEmpty)
            _link('From Wikipedia', wikipedia!['url'], text),
          for (Map review in reviews.take(2)) ...[
            const SizedBox(height: 6),
            Text('"${review['comment']}"',
                style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (place['lat'] != null)
            TextButton.icon(
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Show on the map'),
              onPressed: () => MapService().showUnderCrosshair(LatLng(
                  (place['lat'] as num).toDouble(),
                  (place['lng'] as num).toDouble())),
            ),
        ],
      ),
    );
  }
}
