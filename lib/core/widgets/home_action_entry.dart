import 'package:material_ui/material_ui.dart';

/// One action of a tab: a title and a one-line description of what it does.
@immutable
class HomeActionEntry {
  /// Creates an action.
  const new({
    required this.title,
    required this.description,
    required this.onSelected,
    this.icon,
    this.symbol,
    this.key,
  }) : assert(icon != null || symbol != null, 'Needs an icon or a symbol.');

  /// Icon in front of the title.
  final IconData? icon;

  /// Drawn symbol in front of the title, such as a barcode, used instead of
  /// [icon].
  final Widget? symbol;

  /// The symbol in front of the title, sized and colored by the icon theme.
  Widget get leading => symbol ?? Icon(icon);

  /// Name of the action.
  final String title;

  /// One line that says what the action does.
  final String description;

  /// Called after the action panel closed.
  final VoidCallback onSelected;

  /// Key of the entry's tile, for tests.
  final Key? key;
}

/// Titled group of a tab's actions.
@immutable
class HomeActionSection {
  /// Creates an action section.
  const new({required this.title, required this.entries});

  /// Small title above the entries.
  final String title;

  /// Entries of the section.
  final List<HomeActionEntry> entries;
}
