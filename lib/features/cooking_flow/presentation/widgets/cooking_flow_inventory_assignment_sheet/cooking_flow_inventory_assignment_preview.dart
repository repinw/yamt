import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_cover.dart';

/// Small picture of a Vorrat item in the assignment lists.
class CookingFlowInventoryAssignmentPreview extends StatelessWidget {
  /// Creates the picture.
  const new({
    required this.label,
    required this.imageUrl,
    this.size = 40,
    super.key,
  });

  /// Item name, used for the placeholder.
  final String label;

  /// Item picture, if any.
  final String? imageUrl;

  /// Edge length of the picture.
  final double size;

  @override
  Widget build(BuildContext context) {
    return PreparedMealCover(
      label: label,
      imageBytes: null,
      imageUrl: imageUrl,
      size: size,
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
  }
}
