import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Quiet button for "Später" or "Zurücksetzen": underlined ink text, no fill.
class CookingFlowQuietButton extends StatelessWidget {
  /// Creates the quiet button.
  const new({required this.label, required this.onPressed, super.key});

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;
    final foreground = isEnabled ? colors.ink : colors.muted;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(
          AppGraphit.buttonHeight,
          AppGraphit.buttonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: foreground,
        ),
      ),
    );
  }
}
