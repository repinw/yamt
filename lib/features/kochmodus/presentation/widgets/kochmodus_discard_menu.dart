import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The menu of a cook run's top bar, with "Verwerfen".
class KochmodusDiscardMenu extends StatelessWidget {
  /// Creates the menu that runs [onDiscard] on "Verwerfen".
  const new({required this.onDiscard, super.key});

  /// Key of the menu button.
  static const menuKey = ValueKey<String>('kochmodus-menu');

  /// Key of "Verwerfen" in the menu.
  static const discardKey = ValueKey<String>('kochmodus-discard');

  /// Discards the run.
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    key: menuKey,
    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
    icon: const Icon(Icons.more_vert_rounded),
    onSelected: (action) => action(),
    itemBuilder: (_) => [
      PopupMenuItem(
        key: discardKey,
        value: onDiscard,
        child: Text(AppLocalizations.of(context)!.cookingDiscardAction),
      ),
    ],
  );
}
