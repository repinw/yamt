import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_top_sliver_chrome.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';

/// Shared top chrome rendered inside a home tab scroll view.
class HomeShellTabTopChrome extends StatelessWidget {
  /// The home tab top chrome.
  const new({required this.title, super.key, this.actions = const <Widget>[]});

  /// Top bar title.
  final String title;

  /// Optional tab-owned actions.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = shouldUseCompactHomeChrome(context);
    return HomeShellTopSliverChrome(
      child: HomeTopBar(
        title: title,
        titleColor: colors.primary,
        compact: compact,
        preferredHeight: HomeTopBar.preferredHeightFor(
          context,
          compact: compact,
        ),
        actions: actions,
      ),
    );
  }
}
