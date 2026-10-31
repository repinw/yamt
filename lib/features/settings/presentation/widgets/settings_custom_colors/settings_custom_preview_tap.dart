import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';

/// Hands the preview's taps to the editor: a tap on a part of the preview
/// picks the color that part shows.
class SettingsCustomPreviewScope extends InheritedWidget {
  /// Creates the scope.
  const new({required this.onPick, required super.child, super.key});

  /// Called with the color of the tapped part.
  final ValueChanged<AppCustomColor> onPick;

  @override
  bool updateShouldNotify(SettingsCustomPreviewScope oldWidget) =>
      onPick != oldWidget.onPick;
}

/// A part of the preview that picks [color] when tapped. The innermost part
/// under the finger wins.
class SettingsCustomPreviewTap extends StatelessWidget {
  /// Creates the part.
  const new({required this.color, required this.child, super.key});

  /// The color this part picks.
  final AppCustomColor color;

  /// The part.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SettingsCustomPreviewScope>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: scope == null ? null : () => scope.onPick(color),
      child: child,
    );
  }
}
