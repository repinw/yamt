import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
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
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: colors.muted,
      letterSpacing: AppGraphit.kickerTracking,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        spacing: AppSpacing.xs,
        children: [
          Row(
            children: [
              IconButton(
                key: backKey,
                tooltip: step == 1
                    ? MaterialLocalizations.of(context).closeButtonTooltip
                    : MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: step == 1
                    ? const Icon(Icons.close_rounded)
                    : const BackButtonIcon(),
              ),
              Expanded(
                child: Text(
                  l10n.recipeCheckTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              Text(l10n.recipeCheckStep(step, steps), style: style),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
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
      ),
    );
  }
}
