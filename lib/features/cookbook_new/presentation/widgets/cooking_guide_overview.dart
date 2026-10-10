import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_chips.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_step_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The first screen of the Kochhelfer: every ingredient and every step.
class CookingGuideOverview extends StatelessWidget {
  /// Creates the overview of [guide].
  const new({required this.guide, super.key});

  /// The recipe as the Kochhelfer reads it.
  final CookingGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.cookingGuideKicker(guide.portions),
          title: guide.name,
        ),
        CookingGuideChips(ingredients: guide.ingredients),
        const SizedBox(height: AppSpacing.lg),
        RecipeStepList(steps: guide.steps),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            0,
          ),
          child: Text(
            l10n.cookingGuideSentenceNote(guide.sentences.length),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}
