import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_flow_top_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The top of the ingredient check: back, the title, the step count, and
/// one bar per step.
class IngredientCheckTopBar extends StatelessWidget {
  /// Creates the bar at [step] of [steps].
  const new({
    required this.step,
    required this.steps,
    required this.onBack,
    this.backKey,
    super.key,
  });

  /// The current step, from 1.
  final int step;

  /// The number of steps.
  final int steps;

  /// Goes one step back, or closes the check on the first one; `null` while
  /// the check is busy.
  final VoidCallback? onBack;

  /// Key of the back button.
  final Key? backKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Column(
      spacing: AppSpacing.xs,
      children: [
        RecipeFlowTopBar(
          backKey: backKey,
          onBack: onBack,
          closes: step == 1,
          title: l10n.recipeCheckTitle,
          caption: l10n.recipeCheckStep(step, steps),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm + AppSpacing.md,
            0,
            AppSpacing.xl,
            0,
          ),
          child: Row(
            spacing: AppGraphit.progressSegmentGap,
            children: [
              for (var i = 1; i <= steps; i++)
                Expanded(
                  child: SizedBox(
                    height: AppGraphit.progressSegmentHeight,
                    child: ColoredBox(
                      color: i <= step ? colors.ink : colors.track,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
