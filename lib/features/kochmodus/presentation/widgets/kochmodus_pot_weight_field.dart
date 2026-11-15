import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "{Topf} mit Essen (g) · Pflicht", "· freiwillig" for a meal in pieces,
/// which never waits for it: empty until weighed, then the gross weight with
/// the food's weight below it.
class KochmodusPotWeightField extends StatelessWidget {
  /// Creates the field of [meal], whose pot is called [label].
  const new({
    required this.meal,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// The meal; its pot is set.
  final KochmodusMealView meal;

  /// The pot's name, "Topf N" when it has none.
  final String label;

  /// Opens the weighing.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final gross = meal.grossWeight;
    final net = meal.netWeight;
    final emptyWeight = meal.pot?.emptyWeight ?? 0;
    return Semantics(
      button: true,
      child: AppInkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: meal.inPieces
                ? l10n.kochmodusPotGrossOptional(label)
                : l10n.kochmodusPotGross(label),
            helperText: net == null ? null : l10n.cookNetWeight(net),
            errorText: meal.weighedTooLow
                ? l10n.cookWeightTooLow(emptyWeight)
                : null,
            suffixIcon: Icon(Icons.scale_outlined, color: colors.muted),
          ),
          child: Text(
            gross == null
                ? l10n.kochmodusPotWeighHint
                : l10n.cookAmountGrams('$gross'),
            style: gross == null
                ? textTheme.bodyLarge?.copyWith(color: colors.muted)
                : textTheme.bodyLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ),
      ),
    );
  }
}
