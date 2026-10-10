import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The buttons at the bottom of the recipe page and the ingredient check:
/// the main one, and a second one before it when [secondaryLabel] is set.
class RecipeBottomBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
    super.key,
  });

  /// The main button.
  final String label;

  /// Called by the main button; `null` turns it off.
  final VoidCallback? onPressed;

  /// Key of the main button.
  final Key? buttonKey;

  /// The second button.
  final String? secondaryLabel;

  /// Called by the second button; `null` turns it off.
  final VoidCallback? onSecondary;

  /// Key of the second button.
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final secondaryLabel = this.secondaryLabel;
    const size = Size.fromHeight(AppGraphit.buttonHeight);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            if (secondaryLabel != null)
              Expanded(
                child: FilledButton.tonal(
                  key: secondaryKey,
                  onPressed: onSecondary,
                  style: FilledButton.styleFrom(minimumSize: size),
                  child: Text(secondaryLabel),
                ),
              ),
            Expanded(
              flex: secondaryLabel == null ? 1 : 2,
              child: FilledButton(
                key: buttonKey,
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  minimumSize: size,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
