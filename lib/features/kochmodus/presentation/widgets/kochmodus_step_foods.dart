import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';

/// The lines an instruction of the guide names, under its sentence: one quiet
/// row per line, its amount in ink ("2 EL") and its food muted ("Zucker"),
/// the foods in one column; a line without an amount shows its food alone.
class KochmodusStepFoods extends StatelessWidget {
  /// Creates the rows of [foods].
  const new({required this.foods, super.key});

  /// Key of the rows of a step.
  static const blockKey = ValueKey<String>('kochmodus-guide-foods');

  /// Key of the food of the row of the line [lineId]; its amount stands
  /// before it.
  static ValueKey<String> rowKey(String lineId) =>
      ValueKey<String>('kochmodus-guide-food-$lineId');

  /// The lines the step names, not empty.
  final List<KochmodusStepFood> foods;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final body = Theme.of(context).textTheme.bodyLarge;
    const gap = EdgeInsetsDirectional.only(
      end: AppSpacing.lg,
      bottom: AppSpacing.xs,
    );
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (final food in foods)
          TableRow(
            children: [
              Padding(
                padding: gap,
                child: Text(
                  food.amount ?? '',
                  style: body?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  food.food,
                  key: rowKey(food.lineId),
                  style: body?.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
