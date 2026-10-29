import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import '/classes/classes.dart';
import '/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme.dart';

/// Send feedback: a problem, an idea or a question, to the Drives team - with
/// the app version, platform and the page it was sent from filled in, so
/// there's no going back to ask. It waits in the control panel's inbox.
///
/// On the web it fills the SideDrawer; on a phone it's a page of its own.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  static const List<String> _pages = [
    'Home',
    'Published',
    'Explore',
    'Favourites',
    'Shop',
    'Messages'
  ];

  String _category = 'problem';
  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  // the page it's about - where it was opened from
  final String _screen =
      _pages.elementAtOrNull(NavigationService().page) ?? 'Drives';

  String get _version =>
      '${appVersion['major']}.${appVersion['minor']}.${appVersion['patch']} '
      '${appVersion['suffix']}';

  String get _platform => kIsWeb ? 'web' : Platform.operatingSystem;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ListView(padding: const EdgeInsets.all(16), children: [
      const Text(
          "Tell us what went wrong, what you'd like, or what you're not sure "
          'about - it goes straight to the Drives team, and helps us finish '
          'the app.',
          style: TextStyle(fontSize: 16)),
      const SizedBox(height: 16),
      if (Setup().jwt.isEmpty)
        const Text('Log in to send feedback.', style: TextStyle(fontSize: 16))
      else ...[
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'problem',
                label: Text('A problem'),
                icon: Icon(Icons.report_problem_outlined)),
            ButtonSegment(
                value: 'idea',
                label: Text('An idea'),
                icon: Icon(Icons.lightbulb_outline)),
            ButtonSegment(
                value: 'question',
                label: Text('A question'),
                icon: Icon(Icons.help_outline)),
          ],
          selected: {_category},
          onSelectionChanged: (chosen) =>
              setState(() => _category = chosen.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          minLines: 6,
          maxLines: 14,
          maxLength: 5000,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              hintText: switch (_category) {
                'problem' => 'What happened, and what were you doing?',
                'idea' => 'What would make Drives better for you?',
                _ => "What aren't you sure about?",
              }),
        ),
        Text('Sent with: Drives $_version, $_platform, from $_screen',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send'),
            onPressed: _sending ? null : _send,
          ),
        ),
      ],
    ]);
    if (kIsWeb) {
      return ScreensAppBarBottom(
          heading: 'Send feedback',
          prompt: 'A problem, an idea or a question',
          textColor: DrivesColours.current.ink,
          content: content);
    }
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: ScreensAppBar(
          heading: 'Send feedback', prompt: 'A problem, an idea or a question'),
      body: content,
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    String? problem = await sendFeedback(
        category: _category,
        message: _message.text,
        appVersion: _version,
        platform: _platform,
        screen: _screen);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(problem ?? 'Thank you - it has gone to the Drives team')));
    if (problem == null) _message.clear();
  }
}
