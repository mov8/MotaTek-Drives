import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/constants.dart';
import '/services/services.dart';

/// The ? on each main page: what the page is for - its summary from the
/// documentation on the website (HelpService) - with its full help there,
/// one docs page each, named as the Hugo docs are (HelpService.mainPages)
class HelpButton extends StatelessWidget {
  final double size;
  const HelpButton({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return HelpTip(
      helpKey: 'bar.help',
      child: IconButton(
        icon: Icon(Icons.help_outline, size: size, color: Colors.white),
        onPressed: () => _summary(context),
      ),
    );
  }

  void _summary(BuildContext context) {
    String name =
        HelpService.mainPages.elementAtOrNull(NavigationService().page) ?? '';
    var page = HelpService().page(name);
    Uri full =
        page?.url ?? Uri.parse('$urlDocs${name.isEmpty ? '' : '$name/'}');
    if (page == null || page.summary.isEmpty) {
      _open(full); // no summary to show - the help itself
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(page.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(page.summary, style: const TextStyle(fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _open(full);
            },
            child: const Text('Read the full help'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _open(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
}
