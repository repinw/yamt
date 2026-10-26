import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/cooked_pot.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What one portion or piece of the [pot] weighs and holds.
class CookedMealPortionLine extends StatelessWidget {
  /// Creates the line for [pot], counted in pieces when [inPieces].
  const new({required this.pot, required this.inPieces, super.key});

  /// The pot as weighed so far.
  final CookedPot pot;

  /// Whether the meal is counted in pieces.
  final bool inPieces;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Text(
      switch (pot.gramsPerPortion) {
        final grams? => l10n.cookedPerPortionWeighed(grams, pot.kcalPerPortion),
        null when inPieces => l10n.cookedPerPiece(pot.kcalPerPortion),
        null => l10n.cookedPerPortion(pot.kcalPerPortion),
      },
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: colors.muted),
    );
  }
}
