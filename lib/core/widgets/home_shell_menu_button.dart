import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Menü" header tool that opens the home side menu. Renders nothing outside
/// the home shell.
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
    return HomeHeaderTool(
      key: buttonKey,
      symbol: const Icon(Icons.menu_rounded),
      label: AppLocalizations.of(context)!.homeMenuTool,
      onPressed: scope.openMenu,
    );
  }
}
