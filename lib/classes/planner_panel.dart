import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/constants.dart';
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
  'pub': 'Pubs',
  'cafe': 'Cafés',
  'restaurant': 'Restaurants',
};

// A stop's kind -> (one, several)
const Map<String, (String, String)> _stops = {
  'pub': ('Pub', 'pubs'),
  'cafe': ('Café', 'cafés'),
  'restaurant': ('Restaurant', 'restaurants'),
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
    return ListenableBuilder(
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
                Icon(Icons.auto_awesome,
                    color: colourList[Setup().aiRouteColour]),
                const SizedBox(width: 8),
                Text('AI assist',
                    style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 12),
              if (planner.status == PlannerStatus.done)
                ..._result(context, planner)
              else if (planner.status == PlannerStatus.choose)
                ..._choose(context, planner)
              else ...[
                if (!planner.canPlan) _noneLeft(context, planner.allowance!),
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
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error))
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
            Text(allowance['reason'] ?? "AI assist isn't available"),
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
            "You've had all ${allowance['limit']} of your AI trip plans for "
            'the last 24 hours. You can plan another $when.'),
      ),
    );
  }

  /// How many plans are left, once some have been used
  String _left(Map? allowance) {
    if (allowance == null || (allowance['used'] ?? 0) == 0) return '';
    int left = (allowance['limit'] ?? 0) - (allowance['used'] ?? 0);
    return ' You have $left AI trip plan${left == 1 ? '' : 's'} left for now.';
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
    return [
      Text(trip['title'] ?? '', style: text.titleMedium),
      const SizedBox(height: 4),
      Text(trip['summary'] ?? ''),
      const SizedBox(height: 12),
      _roads(trip, text),
      const SizedBox(height: 10),
      _key(text),
      const SizedBox(height: 16),
      Text('What AI assist understood', style: text.titleSmall),
      const SizedBox(height: 6),
      _understood(planner),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Plan again'),
          onPressed: planner.edited ? planner.planAgain : null,
        ),
        TextButton(
          onPressed: planner.newRequest,
          child: const Text('Ask for something else'),
        ),
      ]),
      if ((trip['stops'] ?? []).isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Stops', style: text.titleSmall),
        for (Map stop in trip['stops']) _place(stop),
      ],
      if ((trip['choices'] ?? []).isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Or choose instead', style: text.titleSmall),
        Text('Put the crosshair on one and tap Waypoint to add it.',
            style: text.bodySmall),
        for (Map choice in trip['choices']) _place(choice),
      ],
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
              'AI assist builds trips only from real places in Drives and '
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
          'Small dots: other places AI assist found. Move the crosshair onto '
          'one and the Status Bar says what it is - Waypoint adds it'),
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

  /// A stop or choice: what it is, why it was chosen, its rating, what
  /// users said and what Wikipedia says - and a button to show it on the map
  Widget _place(Map place) {
    TextTheme text = Theme.of(context).textTheme;
    String what = placeWhat(place);
    if ((place['ratings'] ?? 0) > 0) {
      what += ' · ★ ${(place['rating'] ?? 0).toStringAsFixed(1)} '
          '(${place['ratings']})';
    }
    List reviews = place['reviews'] ?? [];
    Map? wikipedia = place['wikipedia'];
    String thumbnail = wikipedia?['thumbnail'] ?? '';
    String about = wikipedia?['extract'] ??
        (reviews.isNotEmpty
            ? '"${reviews.first['comment']}"'
            : place['description'] ?? '');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          thumbnail.isEmpty
              ? SizedBox(
                  width: 56, child: Icon(_iconOf(place['kind']), size: 32))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(thumbnail,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SizedBox(
                          width: 56,
                          child: Icon(_iconOf(place['kind']), size: 32)))),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place['name'] ?? '', style: text.titleSmall),
              Text(what, style: text.bodySmall),
              if ((place['why'] ?? '').toString().isNotEmpty)
                Text('Chosen because: ${place['why']}',
                    style:
                        text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              if (about.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(about,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall),
              ],
              if ((wikipedia?['url'] ?? '').toString().isNotEmpty)
                InkWell(
                  onTap: () => launchUrl(Uri.parse(wikipedia!['url'])),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('From Wikipedia',
                        style: text.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline)),
                  ),
                ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Show on the map',
            onPressed: place['lat'] == null
                ? null
                : () => MapService().showInView(LatLng(
                    (place['lat'] as num).toDouble(),
                    (place['lng'] as num).toDouble())),
          ),
        ]),
      ),
    );
  }
}
