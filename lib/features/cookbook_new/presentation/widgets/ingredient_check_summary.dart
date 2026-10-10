import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The last step of the ingredient check: what comes from the Vorrat, what
/// goes on the shopping list, and what is ignored.
class IngredientCheckSummary extends StatelessWidget {
  /// Creates the summary of [check].
  const new({required this.check, super.key});

  /// The recipe and the cook's choices.
  final IngredientCheckView check;

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
      ],
    );
  }
}
