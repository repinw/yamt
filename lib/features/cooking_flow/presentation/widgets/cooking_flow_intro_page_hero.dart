import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';

/// Head of the intro step: a tilted framed picture, a small caption, the
/// recipe name and one line under it, like the head of the eat page.
class CookingFlowIntroMealHero extends StatelessWidget {
  /// Creates the hero.
  const new({
    required this.label,
    required this.kicker,
    required this.caption,
    required this.imageBytes,
    required this.imageUrl,
    super.key,
  });

  /// Recipe name.
  final String label;

  /// Small caption above the name.
  final String kicker;

  /// Line under the name.
  final String caption;

  /// Locally stored picture, if any.
  final Uint8List? imageBytes;

  /// Remote picture, if any.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      spacing: AppSpacing.xl,
      children: <Widget>[
        Transform.rotate(
          angle: AppFoodLabel.imageTilt,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tile,
              border: Border.all(
                color: colors.ink,
                width: AppFoodLabel.outline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppFoodLabel.outline),
              // The picture sits inside the frame and its inset, so the
              // frame stays visible on every side.
              child: PreparedMealCover(
                label: label,
                imageBytes: imageBytes,
                imageUrl: imageUrl,
                size: AppFoodLabel.imageTile - 4 * AppFoodLabel.outline,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: <Widget>[
              Text(
                kicker.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.cookingFlowKickerStyle,
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.cookingFlowDisplayStyle(textTheme.headlineSmall),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
