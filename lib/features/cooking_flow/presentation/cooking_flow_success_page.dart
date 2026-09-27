import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Success screen shown after cookflow saved a meal.
class CookingFlowSuccessPage extends StatelessWidget {
  /// Creates success page.
  const new({
    required this.mealName,
    required this.onInventoryPressed,
    super.key,
  });

  /// Saved meal name.
  final String mealName;

  /// Opens inventory after save.
  final VoidCallback onInventoryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return CookingFlowStepLayout(
      title: l10n.cookflowSuccessTitle,
      subtitle: l10n.cookflowSuccessSubtitle,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.rule),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.cookflowSuccessHeadline.toUpperCase(),
                  style: context.cookingFlowKickerStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mealName,
                  style: context.cookingFlowDisplayStyle(
                    textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: CookingFlowActionButton(
                    label: l10n.cookflowToInventoryButton,
                    onPressed: onInventoryPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
