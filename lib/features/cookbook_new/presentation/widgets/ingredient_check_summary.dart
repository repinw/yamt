import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The last step of the ingredient check: what comes from the Vorrat, what
/// goes on the shopping list, what is ignored, and what the cook changed,
/// with the switch that saves the changes in the recipe.
class IngredientCheckSummary extends StatelessWidget {
  /// Creates the summary of [check].
  const new({required this.check, required this.onSaveEdits, super.key});

  /// Key of the switch that saves the changes in the recipe.
  static const saveEditsKey = ValueKey<String>('ingredient-check-save-edits');

  /// The recipe and the cook's choices.
  final IngredientCheckView check;

  /// Saves the changes in the recipe, or for this cooking only.
  final ValueChanged<bool> onSaveEdits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget group(String title, List<String> labels) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          CookbookSectionTitle(title: title),
          if (labels.isEmpty)
            Text(
              l10n.recipeCheckNothing,
              style: textTheme.bodyLarge?.copyWith(color: colors.muted),
            ),
          for (final label in labels)
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: colors.ink),
            ),
        ],
      ),
    );

    final fromStock = check.fromStock;
    final onList = check.onList;
    final ignored = check.ignored;
    final changes = [
      for (final change in check.view.changes)
        switch ((
          ingredientAmountLabel(l10n, change.from),
          ingredientAmountLabel(l10n, change.to),
        )) {
          _ when change.removed => l10n.recipeCheckChangeRemoved(change.food),
          (_, final to?) when change.added => l10n.recipeCheckChangeAddedAmount(
            to,
            change.food,
          ),
          _ when change.added => l10n.recipeCheckChangeAdded(change.food),
          (final from?, final to?) => l10n.recipeCheckChangeAmount(
            change.food,
            from,
            to,
          ),
          _ => l10n.recipeCheckChangeOther(change.food),
        },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.recipeCheckSummaryKicker,
          title: l10n.recipeCheckSummaryTitle,
        ),
        group(l10n.recipeCheckFromStock(fromStock.length), fromStock),
        group(l10n.recipeCheckOnList(onList.length), onList),
        group(l10n.recipeCheckIgnored(ignored.length), ignored),
        if (changes.isNotEmpty) ...[
          group(l10n.recipeCheckChanged, changes),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            child: AppSwitchListTile(
              key: saveEditsKey,
              value: check.draft.saveEdits,
              onChanged: onSaveEdits,
              title: Text(l10n.recipeCheckSaveEdits),
              subtitle: Text(l10n.recipeCheckSaveEditsHint),
            ),
          ),
        ],
      ],
    );
  }
}
