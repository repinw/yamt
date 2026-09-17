import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the home side menu. Renders nothing outside the home shell.
class HomeShellMenuButton extends StatelessWidget {
  /// Creates the menu button.
  const new({super.key});

  /// Stable key for tests.
  static const buttonKey = ValueKey<String>('home-shell-menu-button');

  @override
  Widget build(BuildContext context) {
    final scope = HomeShellMenuScope.maybeOf(context);
    if (scope == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: buttonKey,
      tooltip: AppLocalizations.of(context)!.homeMenuTooltip,
      icon: const Icon(Icons.menu_rounded),
      onPressed: scope.openMenu,
    );
  }
}
