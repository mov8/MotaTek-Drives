import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The few colours the app's look comes from. Buttons, chips, switches,
/// dialogs, cards and the bottom bar take theirs from these, through the
/// theme, rather than each setting its own - so the look stays the same from
/// screen to screen, and changing these changes it everywhere. (To come:
/// MotaTek's, and each club's, set in the control panel.)
class DrivesColours {
  /// The main colour: app bars, page backgrounds, buttons, the page you're on
  final Color brand;

  /// AI assist, and Write it for me - so what the AI does stands out
  final Color ai;

  /// Quieter controls: the drawer's handle, swipe-to-delete, the web's page
  /// buttons, hints
  final Color neutral;

  /// Headings and labels on white or pale backgrounds
  final Color ink;

  const DrivesColours({
    this.brand = const Color(0xFF2196F3), // Colors.blue
    this.ai = const Color(0xFF673AB7), // Colors.deepPurple
    this.neutral = const Color(0xFF607D8B), // Colors.blueGrey
    this.ink = const Color(0xFF011D33),
  });

  /// A page's panel over the brand background - the brand, see-through
  Color get panel => brand.withValues(alpha: 0.41);

  static DrivesColours current = const DrivesColours();
}

/// The whole app's theme, from its colours. (Without one, anything that
/// didn't set its own colour took Flutter's default - purple.)
ThemeData drivesTheme([DrivesColours? colours]) {
  DrivesColours c = colours ?? DrivesColours.current;
  ColorScheme scheme = _scheme(c.brand).copyWith(
    tertiary: c.ai,
    onTertiary: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: c.brand,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
      // light status bar icons, over the app bar's own colour (left to
      // Android, the status bar is a darker shade)
      systemOverlayStyle: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
    ),
  );
}

/// AI assist's own colours - wrap an AI part in Theme(data: aiTheme(...))
/// and its buttons, chips and progress take the AI colour
ThemeData aiTheme(ThemeData base) => base.copyWith(
      colorScheme: _scheme(DrivesColours.current.ai),
    );

/// The shades Material builds from one colour, with that colour itself as
/// the main one (fromSeed alone gives a darker tone of it)
ColorScheme _scheme(Color main) => ColorScheme.fromSeed(seedColor: main)
    .copyWith(primary: main, onPrimary: Colors.white);
