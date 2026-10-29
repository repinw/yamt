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
