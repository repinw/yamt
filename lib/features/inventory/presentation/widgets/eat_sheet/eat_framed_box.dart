import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Box of the eat page with a thick outline, like a printed food label.
class EatFramedBox extends StatelessWidget {
  /// Creates the box around [child].
  const new({required this.child, super.key});

  /// Content of the box.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.ink, width: AppFoodLabel.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: child,
      ),
    );
  }
}
