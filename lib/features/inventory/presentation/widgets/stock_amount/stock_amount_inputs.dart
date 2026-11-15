import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The one big number of the amount page, typed with the number keyboard,
/// with its unit beside it.
class StockAmountField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.controller,
    required this.unit,
    required this.onChanged,
    super.key,
  });

  /// Key of the field.
  static const fieldKey = Key('inventory_stock_amount_field');

  /// The typed number.
  final TextEditingController controller;

  /// Unit of the number.
  final InventoryAmountUnit unit;

  /// Called on each change.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final big = textTheme.displayMedium?.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w800,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            autofocus: controller.text.isEmpty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            style: big,
            cursorColor: colors.accent,
            decoration: InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.rule),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.rule),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.ink),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        Text(
          unit.localizedName(AppLocalizations.of(context)!),
          style: textTheme.headlineSmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

/// Quick choices under the big number, such as a quarter, half, the whole
/// or two packs, or common pack sizes; the typed amount is marked.
class StockAmountChoices extends StatelessWidget {
  /// Creates the choices.
  const new({
    required this.amounts,
    required this.unit,
    required this.scale,
    required this.picked,
    required this.onPicked,
    super.key,
  });

  /// Key of the choice of [amount].
  static Key choiceKey(int amount) =>
      Key('inventory_stock_amount_choice_$amount');

  /// The amounts offered, in the stored unit.
  final List<int> amounts;

  /// Unit of the amounts.
  final InventoryAmountUnit unit;

  /// Scale of the amounts.
  final int scale;

  /// The typed amount, marked when it is one of [amounts].
  final int? picked;

  /// Called with the tapped amount.
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final amount in amounts.where((amount) => amount > 0).toSet())
          EatChip(
            key: choiceKey(amount),
            label: stockAmountText(
              l10n,
              amount: amount,
              unit: unit,
              scale: scale,
            ),
            isSelected: amount == picked,
            isAccent: true,
            onPressed: () => onPicked(amount),
          ),
      ],
    );
  }
}

/// The count of pieces as one big number between minus and plus.
class StockAmountCountRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.count, required this.onChanged, super.key});

  /// Key of the minus button.
  static const lessKey = Key('inventory_stock_amount_less');

  /// Key of the plus button.
  static const moreKey = Key('inventory_stock_amount_more');

  /// Key of the count.
  static const countKey = Key('inventory_stock_amount_count');

  /// The count, at least one.
  final int count;

  /// Called with the new count.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: colors.tile,
      foregroundColor: colors.ink,
      disabledForegroundColor: colors.muted,
    );
    return Row(
      spacing: AppSpacing.xl,
      children: [
        IconButton(
          key: lessKey,
          tooltip: l10n.stockAmountLess,
          style: buttonStyle,
          onPressed: count > 1 ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: Text(
            l10n.inventoryEatSheetAmountWithUnit(
              '$count',
              InventoryAmountUnit.piece.localizedName(l10n),
            ),
            key: countKey,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          key: moreKey,
          tooltip: l10n.stockAmountMore,
          style: buttonStyle,
          onPressed: () => onChanged(count + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// The weight of one piece in grams, asked under the count when the food
/// does not know it, so the recipe can turn pieces into grams.
class StockAmountPieceWeight extends StatelessWidget {
  /// Creates the field.
  const new({required this.controller, required this.onChanged, super.key});

  /// Key of the field.
  static const fieldKey = Key('inventory_stock_amount_piece_weight');

  /// The typed grams.
  final TextEditingController controller;

  /// Called on each change.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: colors.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.tile,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          hintText: l10n.stockAmountPieceWeightHint,
          suffixText: l10n.eatPageStockPerPiece(l10n.caloriesUnitGram),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
