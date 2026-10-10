import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Ingredients with their amounts as small round labels, such as
/// "400 g Tomaten".
class CookingGuideChips extends StatelessWidget {
  /// Creates the labels for [ingredients].
  const new({required this.ingredients, super.key});

  /// The ingredients as the recipe page names them.
  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: colors.ink, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final ingredient in ingredients)
            DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.tile,
                shape: const StadiumBorder(),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppGraphit.chipHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(ingredient, style: style),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
