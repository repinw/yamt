import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The rows of the meal editor that no food fills: open ones in the low
/// color, then ignored ones struck through, each with an x that deletes it
/// from the meal.
class PreparedMealEditOpenRows extends StatelessWidget {
  /// Creates the rows.
  const new({
    required this.openRows,
    required this.ignoredRows,
    required this.onDelete,
    super.key,
  });

  /// Key of the open row [row].
  static ValueKey<String> openKey(String row) =>
      ValueKey<String>('prepared_meal_edit_open_row_$row');

  /// Key of the ignored row [row].
  static ValueKey<String> ignoredKey(String row) =>
      ValueKey<String>('prepared_meal_edit_ignored_row_$row');

  /// Key of the x that deletes [row].
  static ValueKey<String> deleteKey(String row) =>
      ValueKey<String>('prepared_meal_edit_delete_row_$row');

  /// The open rows, such as "200 g Reis".
  final List<String> openRows;

  /// The ignored rows.
  final List<String> ignoredRows;

  /// Deletes a row from the meal, or null once the ingredients are fixed.
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in openRows)
          _Row(name: row, isIgnored: false, onDelete: onDelete),
        for (final row in ignoredRows)
          _Row(name: row, isIgnored: true, onDelete: onDelete),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const new({
    required this.name,
    required this.isIgnored,
    required this.onDelete,
  });

  final String name;
  final bool isIgnored;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = isIgnored ? colors.muted : colors.low;
    final onDelete = this.onDelete;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.ink)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: Column(
                  // Keyed inside the row, so equal rows are no equal
                  // siblings.
                  key: isIgnored
                      ? PreparedMealEditOpenRows.ignoredKey(name)
                      : PreparedMealEditOpenRows.openKey(name),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    Text(
                      name,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        decoration: isIgnored
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: color,
                      ),
                    ),
                    Text(
                      isIgnored
                          ? l10n.eatPageIngredientIgnored
                          : l10n.eatPageIngredientMissing,
                      style: textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  key: PreparedMealEditOpenRows.deleteKey(name),
                  tooltip: l10n.preparedMealEditDeleteRowAction,
                  onPressed: () => onDelete(name),
                  icon: Icon(Icons.close_rounded, color: colors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
