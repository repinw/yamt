import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The one lime action of the page: the label, and the calories of the
/// entered amount in a small tag.
class EatPageConfirmButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.buttonKey,
    required this.label,
    required this.trailing,
    required this.onPressed,
    super.key,
  });

  /// Key of the button.
  final Key buttonKey;

  /// Text of the button.
  final String label;

  /// Small tag at the end, such as the calories; hidden when null.
  final String? trailing;

  /// Called on tap; the button is disabled when null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final trailingText = trailing;

    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xs, 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: AppSpacing.sm,
        children: [
          // A long label next to a second button shrinks instead of
          // overflowing.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1),
            ),
          ),
          if (trailingText != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onAccent.withValues(
                  alpha: AppOpacities.buttonTag,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  trailingText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
