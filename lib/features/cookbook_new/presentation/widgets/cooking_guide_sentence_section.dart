import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_chips.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One sentence of the Kochhelfer: where it is, the sentence in large
/// type, and the ingredients it names.
class CookingGuideSentenceSection extends StatelessWidget {
  /// Creates the sentence at [index] of [guide].
  const new({required this.guide, required this.index, super.key});

  /// The recipe as the Kochhelfer reads it.
  final CookingGuide guide;

  /// The sentence to show, from 0.
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final (:sentence, :ingredients) = guide.sentences[index];
    final count = guide.sentences.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.cookingGuideProgress(index + 1, count, sentence.step),
          title: sentence.text,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: LinearProgressIndicator(
            value: (index + 1) / count,
            minHeight: AppGraphit.progressSegmentHeight,
            color: colors.ink,
            backgroundColor: colors.track,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CookingGuideChips(ingredients: ingredients),
      ],
    );
  }
}
