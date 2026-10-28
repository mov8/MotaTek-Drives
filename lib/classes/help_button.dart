import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/constants.dart';
import '/services/services.dart';

/// The ? on each main page: an overview of that page, from the documentation
/// on the website (urlDocs) - one page each, named as the Hugo docs are
class HelpButton extends StatelessWidget {
  final double size;
  const HelpButton({super.key, this.size = 30});

  // the main pages, in NavigationService().page order
  static const List<String> _pages = [
    'home',
    'great_drives', // Published
    'my_trip', // Explore
    'my_drives', // Favourites
    'shop',
    'messages',
  ];

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help with this page',
      icon: Icon(Icons.help_outline, size: size, color: Colors.white),
      onPressed: () {
        String page = _pages.elementAtOrNull(NavigationService().page) ?? '';
        launchUrl(Uri.parse('$urlDocs${page.isEmpty ? '' : '$page/'}'),
            mode: LaunchMode.externalApplication);
      },
    );
  }
}
