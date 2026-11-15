import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// [need] as a row says it, with the exact quantity it has, such as "500 g",
/// "1,5 EL", or "1/2".
String kochmodusNeedText(
  AppLocalizations l10n,
  TemplateIngredientRequirement need,
) => _text(
  l10n,
  ingredientQuantityText(need),
  need.unit,
  need.countMeasureLabel,
);

/// [amount] in [unit], with the spoon or other measure [measure] of a piece
/// line, such as "500 g", "2 EL", or "2".
String kochmodusAmountText(
  AppLocalizations l10n,
  int amount,
  TemplateIngredientUnit unit,
  String? measure,
) => _text(l10n, '$amount', unit, measure);

/// [amount] of [item] in [unit] and the item's scale, as "400 g", "1.250 g"
/// or "2,5 Stk." in the number format of the language of [l10n], with a
/// no-break space that keeps number and unit together.
String kochmodusItemAmountText(
  AppLocalizations l10n,
  int amount,
  InventoryAmountUnit? unit,
  InventoryItem item,
) {
  final kept = unit ?? InventoryAmountUnit.piece;
  final scale = kept == InventoryAmountUnit.piece ? cookAmountScale(item) : 1;
  return _keptText(l10n, amount / scale, kept);
}

/// [grams] that a line brings into the pot (grams and ml count 1:1) in the
/// unit its [food] is kept in, as "20 ml" for oil from a bottle kept in ml
/// and "20 g" for a food kept in grams or in pieces, whose weight comes from
/// its piece size, or without a [food]; in the number format of the language
/// of [l10n], with a no-break space.
String kochmodusWeightText(
  AppLocalizations l10n,
  int grams,
  InventoryItem? food,
) => _keptText(
  l10n,
  grams.toDouble(),
  food?.amountUnit == InventoryAmountUnit.milliliter
      ? InventoryAmountUnit.milliliter
      : InventoryAmountUnit.gram,
);

String _keptText(
  AppLocalizations l10n,
  double amount,
  InventoryAmountUnit kept,
) {
  final value = (NumberFormat.decimalPattern(
    l10n.localeName,
  )..maximumFractionDigits = _maxFractionDigits).format(amount);
  final text = switch (kept) {
    InventoryAmountUnit.gram => l10n.cookAmountGrams(value),
    InventoryAmountUnit.milliliter => l10n.cookAmountMilliliters(value),
    InventoryAmountUnit.piece => l10n.cookAmountPieces(value),
  };
  return text.replaceAll(' ', _noBreakSpace);
}

/// What the foods of [line] still have for it, in the unit the first is kept
/// in, as every text that says what is there says it: "350 ml" for a bottle
/// of 400 ml of which another cooking takes 50 ml, also on "5 EL Olivenöl"
/// (`KochmodusLineView.stockLeft`). `null` when the line takes from no food.
String? kochmodusThereText(AppLocalizations l10n, KochmodusLineView line) =>
    switch (line.stockLeft) {
      (:final item, :final amount)? => kochmodusItemAmountText(
        l10n,
        amount,
        item.amountUnit,
        item,
      ),
      null => null,
    };

String _text(
  AppLocalizations l10n,
  String quantity,
  TemplateIngredientUnit unit,
  String? measure,
) {
  final label = measure?.trim() ?? '';
  return switch (unit) {
    TemplateIngredientUnit.gram => l10n.cookAmountGrams(quantity),
    TemplateIngredientUnit.milliliter => l10n.cookAmountMilliliters(quantity),
    TemplateIngredientUnit.piece when label.isNotEmpty => l10n.cookAmountOf(
      quantity,
      label,
    ),
    TemplateIngredientUnit.piece => quantity,
  };
}

const _noBreakSpace = '\u00A0';
const _maxFractionDigits = 2;
