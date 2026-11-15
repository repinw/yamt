import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';

/// The picture of a line, turned slightly: the image of the item it takes,
/// else the first letter of its food.
class KochmodusLinePicture extends StatelessWidget {
  /// Creates the picture of [line].
  const new({required this.line, super.key});

  /// The line.
  final KochmodusLineView line;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final imageUrl = line.pictureItem?.imageUrl;
    final food = cookLineFood(line.need?.name ?? line.line.text);
    final letter = Center(
      child: Text(
        food.isEmpty ? '' : food.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: colors.muted, fontWeight: FontWeight.w800),
      ),
    );
    return Transform.rotate(
      angle: AppFoodLabel.imageTilt,
      child: SizedBox.square(
        dimension: AppGraphit.rowTile,
        child: ColoredBox(
          color: colors.tile,
          child: imageUrl == null
              ? letter
              : AppCachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => letter,
                ),
        ),
      ),
    );
  }
}
