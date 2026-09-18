import 'package:material_ui/material_ui.dart';

/// Re-tints the accent roles of the theme with the chapter accent.
///
/// Buttons, switches, selection cards, value chips and info boxes on a page all
/// read `primary`, `primaryContainer` or `secondaryContainer`. Deriving those
/// roles from the chapter accent keeps every page in its chapter color instead
/// of falling back to the app's default palette. Surfaces stay untouched.
class IntroChapterTheme extends StatelessWidget {
  /// Creates a chapter theme around [child].
  const new({required this.accent, required this.child, super.key});

  /// Accent color of the chapter.
  final Color accent;

  /// The page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final seeded = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: base.colorScheme.brightness,
    );
    final scheme = base.colorScheme.copyWith(
      primary: seeded.primary,
      onPrimary: seeded.onPrimary,
      primaryContainer: seeded.primaryContainer,
      onPrimaryContainer: seeded.onPrimaryContainer,
      secondary: seeded.secondary,
      onSecondary: seeded.onSecondary,
      secondaryContainer: seeded.secondaryContainer,
      onSecondaryContainer: seeded.onSecondaryContainer,
    );

    return Theme(
      data: base.copyWith(colorScheme: scheme),
      child: child,
    );
  }
}
