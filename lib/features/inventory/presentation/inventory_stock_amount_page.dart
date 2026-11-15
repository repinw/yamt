import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_open_eat_stock.dart';
import 'package:yamt/features/inventory/domain/inventory_stock_count.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_count.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/stock_amount_inputs.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/stock_amount_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The amount page of a food for a recipe line: one question, one big
/// number, quick choices from the package size, what the recipe takes and
/// leaves, the nutrition folded away, and "Übernehmen" above the keyboard.
/// A food in pieces is counted with minus and plus instead.
///
/// Pops an [InventoryStockCount], or nothing when the cook closes it.
class InventoryStockAmountPage extends StatefulWidget {
  /// Creates the page for [item], taken for a line measured in [lineUnit]
  /// that needs [need] of it. A piece without a weight starts with
  /// [pieceWeight].
  const new({
    required this.item,
    this.lineUnit,
    this.need,
    this.pieceWeight,
    super.key,
  });

  /// The food.
  final InventoryItem item;

  /// The unit of the recipe line; null for a line without one.
  final InventoryAmountUnit? lineUnit;

  /// What the line needs, in [lineUnit].
  final int? need;

  /// Grams of one piece the line names.
  final int? pieceWeight;

  /// Key of "Übernehmen".
  static const applyKey = Key('inventory_stock_amount_apply');

  @override
  State<InventoryStockAmountPage> createState() =>
      _InventoryStockAmountPageState();
}

class _InventoryStockAmountPageState extends State<InventoryStockAmountPage> {
  late final StockAmountQuestion _question = stockAmountQuestion(
    widget.item,
    widget.lineUnit,
  );
  late final _amount = TextEditingController(text: _startText());
  late final _weight = TextEditingController(
    text: '${widget.item.servingQuantity?.round() ?? widget.pieceWeight ?? ''}',
  );
  late int _count = openStockStartCount(
    widget.item,
    widget.lineUnit == InventoryAmountUnit.piece ? widget.need : null,
  );

  // The unit the big number is typed in.
  InventoryAmountUnit get _unit => switch (_question) {
    StockAmountQuestion.howMuch =>
      widget.item.amountUnit ?? InventoryAmountUnit.gram,
    StockAmountQuestion.packWeight =>
      widget.lineUnit == InventoryAmountUnit.milliliter
          ? InventoryAmountUnit.milliliter
          : InventoryAmountUnit.gram,
    StockAmountQuestion.howMany => InventoryAmountUnit.piece,
  };

  // The scale of the big number: the item's own for its amount, else none.
  int get _scale =>
      _question == StockAmountQuestion.howMuch ? widget.item.amountScale : 1;

  String _startText() => _question == StockAmountQuestion.howMuch
      ? formatInventoryAmountValue(
          amount: widget.item.initialAmount,
          unit: widget.item.amountUnit ?? InventoryAmountUnit.gram,
          scale: widget.item.amountScale,
        )
      : '';

  // The typed amount in the stored unit, or null while it is no amount.
  int? get _typed => parseInventoryAmountInput(
    rawValue: _amount.text,
    unit: _unit,
    scale: _scale,
  );

  int? get _pieceGrams {
    final grams = int.tryParse(_weight.text.trim());
    return grams == null || grams < 1 ? null : grams;
  }

  // What the page books, or null while the cook still has to type it.
  InventoryStockCount? get _booked => switch (_question) {
    StockAmountQuestion.howMany => (
      item: stockItemWithPieces(widget.item, _count, _pieceGrams),
      amount: _count * inventoryPieceAmountScale,
    ),
    StockAmountQuestion.packWeight => switch (_typed) {
      final amount? => (
        item: stockItemWithPackWeight(widget.item, amount, _unit),
        amount: amount,
      ),
      null => null,
    },
    StockAmountQuestion.howMuch => switch (_typed) {
      final amount? => (item: widget.item, amount: amount),
      null => null,
    },
  };

  @override
  void dispose() {
    _amount.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final counted = _booked;
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CloseButton(color: colors.ink),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  StockAmountHeader(item: widget.item),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    switch (_question) {
                      StockAmountQuestion.howMuch => l10n.eatPageStockQuestion,
                      StockAmountQuestion.packWeight =>
                        l10n.eatPageStockPackWeightMissing,
                      StockAmountQuestion.howMany =>
                        l10n.stockAmountCountQuestion,
                    },
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ..._inputs(),
                  const SizedBox(height: AppSpacing.xxl),
                  StockAmountNeedLine(
                    amount: _question == StockAmountQuestion.howMany
                        ? _count
                        : _typed,
                    unit: _unit,
                    scale: _scale,
                    lineUnit: widget.lineUnit,
                    need: widget.need,
                  ),
                  StockAmountNutritionRow(item: widget.item),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (counted == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        l10n.stockAmountEnterValue,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.muted),
                      ),
                    ),
                  FilledButton(
                    key: InventoryStockAmountPage.applyKey,
                    onPressed: counted == null
                        ? null
                        : () => Navigator.of(context).pop(counted),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      minimumSize: const Size.fromHeight(
                        AppGraphit.buttonHeight,
                      ),
                    ),
                    child: Text(l10n.eatPageStockApply),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inputs() => switch (_question) {
    StockAmountQuestion.howMany => [
      StockAmountCountRow(
        count: _count,
        onChanged: (count) => setState(() => _count = count),
      ),
      if (!hasPieceWeight(widget.item))
        StockAmountPieceWeight(
          controller: _weight,
          onChanged: (_) => setState(() {}),
        ),
    ],
    StockAmountQuestion.packWeight || StockAmountQuestion.howMuch => [
      StockAmountField(
        controller: _amount,
        unit: _unit,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpacing.xl),
      StockAmountChoices(
        amounts: _question == StockAmountQuestion.packWeight
            ? stockCommonPackSizes
            : [
                for (final share in stockPackShares)
                  (widget.item.initialAmount * share).round(),
              ],
        unit: _unit,
        scale: _scale,
        picked: _typed,
        onPicked: (amount) => setState(
          () => _amount.text = formatInventoryAmountValue(
            amount: amount,
            unit: _unit,
            scale: _scale,
          ),
        ),
      ),
    ],
  };
}
