import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_stock_count.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the amount page: picture, brand, name and the package size.
class StockAmountHeader extends StatelessWidget {
  /// Creates the head.
  const new({required this.item, super.key});

  /// The food.
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = item.amountUnit;
    return EatPageHeader(
      title: item.name,
      brand: item.brand,
      imageUrl: item.imageUrl,
      caption: unit == null || !item.usesAmountProgress
          ? null
          : l10n.stockAmountPack(
              stockAmountText(
                l10n,
                amount: item.initialAmount,
                unit: unit,
                scale: item.amountScale,
              ),
            ),
    );
  }
}

/// What the recipe takes of the typed amount and what stays in the Vorrat,
/// or what is missing. Shown only when the line needs [need] in [unit].
class StockAmountNeedLine extends StatelessWidget {
  /// Creates the line.
  const new({
    required this.amount,
    required this.unit,
    required this.scale,
    required this.lineUnit,
    required this.need,
    super.key,
  });

  /// Key of the line.
  static const lineKey = Key('inventory_stock_amount_need');

  /// The typed amount in [unit] and [scale], or null while there is none.
  final int? amount;

  /// Unit of [amount].
  final InventoryAmountUnit unit;

  /// Scale of [amount].
  final int scale;

  /// Unit of the recipe line.
  final InventoryAmountUnit? lineUnit;

  /// What the line needs, in [lineUnit] without a scale.
  final int? need;

  @override
  Widget build(BuildContext context) {
    final amount = this.amount;
    final need = this.need;
    if (amount == null || need == null || need < 1 || lineUnit != unit) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    String text(int value) =>
        stockAmountText(l10n, amount: value, unit: unit, scale: scale);
    final needed = need * scale;
    final (:rest, :missing) = stockRestOf(amount, needed);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Text(
        missing > 0
            ? l10n.stockAmountMissing(text(needed), text(missing))
            : rest > 0
            ? l10n.stockAmountNeedRest(text(needed), text(rest))
            : l10n.stockAmountNeedAll(text(needed)),
        key: lineKey,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: missing > 0 ? colors.low : colors.ink),
      ),
    );
  }
}

/// The nutrition per 100 g or ml, folded to one line with the energy.
class StockAmountNutritionRow extends StatefulWidget {
  /// Creates the row.
  const new({required this.item, super.key});

  /// Key of the row that folds the table open.
  static const rowKey = Key('inventory_stock_amount_nutrition');

  /// The food.
  final InventoryItem item;

  @override
  State<StockAmountNutritionRow> createState() =>
      _StockAmountNutritionRowState();
}

class _StockAmountNutritionRowState extends State<StockAmountNutritionRow> {
  var _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.item.nutrition;
    if (nutrition == null || !nutrition.hasAnyNutritionValue) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final per100 = EatNutrition.per100Only(nutrition).per100!;
    final unit = widget.item.amountUnit == InventoryAmountUnit.milliliter
        ? l10n.inventoryUnitMilliliter
        : l10n.caloriesUnitGram;
    final kcal = NumberFormat.decimalPattern(l10n.localeName)
        .format((nutrition.per100Kcal ?? 0).round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          key: StockAmountNutritionRow.rowKey,
          onPressed: () => setState(() => _isOpen = !_isOpen),
          style: TextButton.styleFrom(
            foregroundColor: colors.muted,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
          ),
          icon: Icon(_isOpen ? Icons.expand_less : Icons.expand_more),
          label: Text(l10n.stockAmountNutrition(kcal, unit)),
        ),
        if (_isOpen)
          EatLabelTable(
            rows: nutritionFactsRows(context, eaten: per100),
            eatenHeader: l10n.caloriesEntryPer100Label(unit),
          ),
      ],
    );
  }
}
