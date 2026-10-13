import 'package:yamt/core/widgets/home_shell_menu_scope.dart';

/// What the shell's slide panel shows.
sealed class HomeSlidePanel {
  /// Base constructor of the panel kinds.
  const new();
}

/// The side menu on the left.
final class HomeSideMenuPanel extends HomeSlidePanel {
  /// Shows this panel.
  const new();
}

/// The current tab's actions, opened from the bottom bar.
final class HomeTabActionsPanel extends HomeSlidePanel {
  /// Shows this panel.
  const new();
}

/// A header tool's actions at the top right.
final class HomeHeaderActionsPanel extends HomeSlidePanel {
  /// Shows the actions that [build] returns.
  const new(this.build);

  /// Builds the tool's actions on every rebuild of the panel.
  final HomeHeaderActionsBuilder build;
}
