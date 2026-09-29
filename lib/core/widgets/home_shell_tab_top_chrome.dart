import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_top_sliver_chrome.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';

/// Shared top chrome rendered inside a home tab scroll view.
class HomeShellTabTopChrome extends StatelessWidget {
  /// The home tab top chrome.
  const new({
    required this.title,
    super.key,
    this.tools = const <Widget>[],
    this.kicker,
  });

  /// Top bar title.
  final String title;

  /// Small caption above the title.
  final String? kicker;

  /// Labeled tools of the tab.
  final List<Widget> tools;

  @override
  Widget build(BuildContext context) {
    final compact = shouldUseCompactHomeChrome(context);
    return HomeShellTopSliverChrome(
      child: HomeTopBar(
        title: title,
        kicker: kicker,
        compact: compact,
        preferredHeight: HomeTopBar.preferredHeightFor(
          context,
          compact: compact,
          hasKicker: kicker != null,
        ),
        tools: tools,
      ),
    );
  }
}
