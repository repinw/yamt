import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// A square with the first letter of [text], turned slightly, as the
/// picture of a person without a photo.
class InitialTile extends StatelessWidget {
  /// Creates the initial tile.
  const new({required this.text, super.key});

  /// The name whose first letter the tile shows.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initial = text.isEmpty ? '' : text.characters.first.toUpperCase();
    return Transform.rotate(
      angle: AppFoodLabel.imageTilt,
      child: Container(
        width: AppSizes.profileInitialTile,
        height: AppSizes.profileInitialTile,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.onSurface,
            width: AppFoodLabel.outline,
          ),
          color: colors.surfaceContainerLowest,
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
