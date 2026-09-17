import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Outlined form field card with the app's field surface and padding.
///
/// Becomes tappable with ink feedback when [onTap] is set.
class AppFieldCard extends StatelessWidget {
  /// Creates a field card.
  const new({required this.child, this.onTap, this.tapTargetKey, super.key});

  /// Card content.
  final Widget child;

  /// Tap callback. The card is not tappable when null.
  final VoidCallback? onTap;

  /// Key for the ink well that receives taps.
  final Key? tapTargetKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    final decoration = BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: borderRadius,
      border: Border.all(color: colors.outlineVariant),
    );
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 66),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: child,
      ),
    );

    final tap = onTap;
    if (tap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        key: tapTargetKey,
        onTap: tap,
        borderRadius: borderRadius,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}
