import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';

/// Shared top chrome rendered inside a home tab scroll view.
class HomeShellTabTopChrome extends StatelessWidget {
  /// The home tab top chrome.
  const HomeShellTabTopChrome({
    required this.title,
    super.key,
    this.subtitle,
    this.middle,
    this.actions = const <Widget>[],
  });

  /// Top bar title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Optional middle widget between title and actions.
  final Widget? middle;

  /// Optional tab-owned actions.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = shouldUseCompactHomeChrome(context);
    return HomeShellTopSliverChrome(
      child: HomeTopBar(
        title: title,
        subtitle: subtitle,
        middle: middle,
        titleColor: colors.primary,
        compact: compact,
        preferredHeight: HomeTopBar.preferredHeightFor(
          context,
          compact: compact,
          hasSubtitle: subtitle != null,
        ),
        actions: actions,
      ),
    );
  }
}
