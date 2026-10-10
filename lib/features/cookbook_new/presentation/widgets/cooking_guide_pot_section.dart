import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_section_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What goes into the pot while the Kochhelfer reads: every ingredient.
class CookingGuidePotSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.ingredients, super.key});

  /// Every ingredient, as the recipe page names it.
  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          CookbookSectionTitle(
            title: l10n.cookingGuideInPot,
            caption: l10n.cookingGuideLineCount(ingredients.length),
          ),
          Text(
            ingredients.join(' · '),
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
