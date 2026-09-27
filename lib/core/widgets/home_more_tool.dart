import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_more_sheet.dart';
import 'package:yamt/core/widgets/home_shell_more_scope.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Mehr" header tool that opens the Mehr sheet with the tab's own actions.
/// Only a tab with more than two actions gets one. Renders nothing outside
/// the home shell.
class HomeMoreTool extends StatelessWidget {
  /// Creates the Mehr tool.
  const new({required this.title, required this.entries, super.key});

  /// Stable key of the tool, for tests.
  static const toolKey = ValueKey<String>('home-more-tool');

  /// Title of the tab's section in the sheet.
  final String title;

  /// The tab's own actions.
  final List<HomeMoreEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scope = HomeShellMoreScope.maybeOf(context);
    if (scope == null) {
      return const SizedBox.shrink();
    }
    return HomeHeaderTool(
      key: toolKey,
      symbol: const Icon(Icons.more_horiz_rounded),
      label: AppLocalizations.of(context)!.homeMoreTool,
      onPressed: () => scope.openMore(title, entries),
    );
  }
}
