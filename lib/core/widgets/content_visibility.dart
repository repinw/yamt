import 'package:material_ui/material_ui.dart';

/// Tells descendants whether the user can see them right now.
///
/// The home shell sets it to false while a sheet, dialog, or page covers the
/// shell. Content without this ancestor counts as visible.
class ContentVisibility extends InheritedWidget {
  /// Creates the visibility scope.
  const new({required this.isVisible, required super.child, super.key});

  /// Whether the content below is visible.
  final bool isVisible;

  /// Whether the content at [context] is visible. Rebuilds [context] when
  /// this changes.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ContentVisibility>()
          ?.isVisible ??
      true;

  @override
  bool updateShouldNotify(ContentVisibility oldWidget) =>
      isVisible != oldWidget.isVisible;
}
