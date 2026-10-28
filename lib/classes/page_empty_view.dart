import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// What a page shows when it has nothing to list, or the user has to log in
/// first - the whole screen on a phone, the whole SideDrawer on the web. The
/// image fills the space, darkened so the message overlaid on it reads, with
/// an optional button under the message, e.g. to log in.
class PageEmptyView extends StatelessWidget {
  final String image;
  final List<String> lines;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const PageEmptyView({
    super.key,
    required this.image,
    required this.lines,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontSize: 22, color: Colors.white);
    return ImageBackdrop(
      image: image,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (String line in lines) ...[
              Text(line, style: style),
              const SizedBox(height: 15),
            ],
            if (buttonLabel != null) ...[
              const SizedBox(height: 15),
              Center(
                child: ActionChip(
                  label: Text(buttonLabel!, style: style),
                  onPressed: onButton,
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An image filling the space, darkened so white text reads over it - behind
/// a page with nothing of its own to show
class ImageBackdrop extends StatelessWidget {
  final String image;
  final Widget child;

  const ImageBackdrop({super.key, required this.image, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset(image, fit: BoxFit.cover),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5), // Light shadow top
              Colors.black.withValues(alpha: 0.7), // Dark contrast bottom
            ],
          ),
        ),
      ),
      child,
    ]);
  }
}

/// Markdown in white, to read over an ImageBackdrop
MarkdownStyleSheet onImageStyleSheet(BuildContext context) {
  ThemeData theme = Theme.of(context);
  return MarkdownStyleSheet.fromTheme(theme.copyWith(
          textTheme: theme.textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white)))
      .copyWith(
    p: const TextStyle(fontSize: 18, color: Colors.white),
    listBullet: const TextStyle(fontSize: 18, color: Colors.white),
    blockquote: const TextStyle(fontSize: 18, color: Colors.white),
    blockquoteDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4)),
    horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white70, width: 1))),
  );
}
