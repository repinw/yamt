import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_dashed_line.dart';

/// Diary content between two dashed lines, like a cut-out part of a food
/// label.
class DiaryDashedSection extends StatelessWidget {
  /// Creates the section around [child].
  const new({required this.child, super.key});

  /// Content between the lines.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FoodLabelDashedLine(color: colors.rule),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: child,
        ),
        FoodLabelDashedLine(color: colors.rule),
      ],
    );
  }
}
