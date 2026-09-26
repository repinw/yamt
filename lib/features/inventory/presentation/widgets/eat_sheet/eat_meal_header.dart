import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_image_tile.dart';

/// Head of a meal on the item hub: the foods' images side by side, tilted
/// and overlapping, and the meal name.
class EatMealHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.title, required this.imageUrls, super.key});

  /// Meal name, such as "Gouda + Bread".
  final String title;

  /// Image of each food, in meal order.
  final List<String?> imageUrls;

  @override
  Widget build(BuildContext context) {
    const size = AppFoodLabel.mealImageTile;
    const step = size - AppFoodLabel.mealImageOverlap;
    final shown = imageUrls
        .take(AppFoodLabel.mealHeaderImages)
        .toList(growable: false);

    return Row(
      spacing: AppSpacing.lg,
      children: [
        SizedBox(
          width: size + step * (shown.length - 1),
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (index, url) in shown.indexed)
                Positioned(
                  left: step * index,
                  child: EatImageTile(
                    imageUrl: url,
                    size: size,
                    angle: index.isEven
                        ? AppFoodLabel.imageTilt
                        : -AppFoodLabel.imageTilt,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              color: FoodLabelColors.of(context).ink,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}
