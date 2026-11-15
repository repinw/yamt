import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Vorhandenes" and "Rezept" of the amount sheet: each fills the field and
/// shows only when it would change [value].
class KochmodusAmountPresets extends StatelessWidget {
  /// Creates the presets of [line].
  const new({
    required this.line,
    required this.value,
    required this.standsForRecipe,
    required this.onRecipePart,
    required this.onFill,
    super.key,
  });

  /// Key of the preset "Vorhandenes".
  static const availableKey = ValueKey<String>('kochmodus-amount-available');

  /// Key of the preset "Rezept".
  static const recipeKey = ValueKey<String>('kochmodus-amount-recipe');

  /// The line.
  final KochmodusLineView line;

  /// What the field holds.
  final int? value;

  /// Whether the field, while empty, stands for the recipe's amount.
  final bool standsForRecipe;

  /// Takes a recipe amount with a part of a unit, which the field cannot hold.
  final VoidCallback onRecipePart;

  /// Fills the field.
  final ValueChanged<int> onFill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final available = line.availableForLine;
    final parsed = line.parsed;
    final recipePart = line.recipeHasPart;
    final changesRecipe = recipePart
        ? value != null || !standsForRecipe
        : parsed?.amount != value;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        if (available != null && available > 0 && available != value)
          EatChip(
            key: availableKey,
            label: l10n.kochmodusAmountPresetAvailable(
              kochmodusAmountText(
                l10n,
                available,
                line.amountUnit,
                line.need?.countMeasureLabel,
              ),
            ),
            isSelected: false,
            onPressed: () => onFill(available),
          ),
        if (parsed != null && changesRecipe)
          EatChip(
            key: recipeKey,
            label: l10n.kochmodusAmountPresetRecipe(
              kochmodusNeedText(l10n, parsed),
            ),
            isSelected: false,
            onPressed: recipePart ? onRecipePart : () => onFill(parsed.amount),
          ),
      ],
    );
  }
}
