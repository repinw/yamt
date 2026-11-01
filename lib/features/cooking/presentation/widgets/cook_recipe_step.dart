import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The first step: the recipe with its portions and lines, read only.
class CookRecipeStep extends StatelessWidget {
  /// Creates the step.
  const new({
    required this.view,
    required this.onPortions,
    required this.onNext,
    super.key,
  });

  /// The cooking.
  final CookView view;

  /// Called with new portions.
  final ValueChanged<int> onPortions;

  /// Goes on to assigning.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final portions = view.portions;
    return CookStepFrame(
      title: view.recipe.name,
      buttonLabel: l10n.cookAssignAction,
      onButton: onNext,
      children: [
        EatCountRow(
          label: l10n.cookPortionsLabel(portions),
          count: portions,
          decreaseTooltip: l10n.cookFewer,
          increaseTooltip: l10n.cookMore,
          onDecrease: portions > 1 ? () => onPortions(portions - 1) : null,
          onIncrease: () => onPortions(portions + 1),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.cookIngredients,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final line in view.lines)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.rule)),
            ),
            child: Text(line.label, style: textTheme.bodyLarge),
          ),
      ],
    );
  }
}
