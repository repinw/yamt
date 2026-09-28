import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Tappable rounded surface shared by the filled cooking flow buttons.
class CookingFlowButtonSurface extends StatelessWidget {
  /// Creates the surface.
  const new({
    required this.child,
    required this.onPressed,
    required this.fill,
    required this.foreground,
    required this.padding,
    super.key,
  });

  /// Content of the button.
  final Widget child;

  /// Press callback; null disables the button.
  final VoidCallback? onPressed;

  /// Background color.
  final Color fill;

  /// Icon color.
  final Color foreground;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : AppGraphit.disabledOpacity,
      child: Material(
        color: fill,
        borderRadius: radius,
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppGraphit.buttonHeight,
            ),
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              // Fills the width it is given and no more height than the
              // label needs.
              child: Align(
                heightFactor: 1,
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
