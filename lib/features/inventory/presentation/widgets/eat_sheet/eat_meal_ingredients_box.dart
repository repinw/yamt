import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_title.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Zutaten" box of a meal's detail page: every ingredient with its picture
/// and its amount in the whole meal, then the missing recipe ingredients in
/// the low color with links to fill or ignore them.
class EatMealIngredientsBox extends StatelessWidget {
  /// Creates the box for [meal].
  const new({
    required this.meal,
    required this.onFill,
    required this.onIgnore,
    super.key,
  });

  /// The meal.
  final PreparedMeal meal;

  /// Fills a missing ingredient from Vorrat foods; null while busy.
  final ValueChanged<String>? onFill;

  /// Ignores a missing ingredient; null while busy.
  final ValueChanged<String>? onIgnore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[
      for (final (index, component) in meal.components.indexed)
        _IngredientRow(
          key: ValueKey('eat_meal_ingredient_${component.inventoryItemId}'),
          name: component.name,
          amount: eatComponentAmount(
            l10n,
            preparedMealComponentDisplayAmount(component),
            component.usedUnit,
          ),
          imageUrl: component.imageUrl,
          tiltLeft: index.isEven,
        ),
      for (final ingredient in meal.pendingRecipeIngredients)
        _MissingRow(
          key: ValueKey('eat_meal_missing_$ingredient'),
          name: ingredient,
          onFill: onFill == null ? null : () => onFill!(ingredient),
          onIgnore: onIgnore == null ? null : () => onIgnore!(ingredient),
        ),
    ];
    return EatFramedBox(
      key: const Key('eat_meal_ingredients_box'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(text: l10n.preparedMealIngredientsTitle),
          for (final (index, row) in rows.indexed)
            _Ruled(showRule: index < rows.length - 1, child: row),
        ],
      ),
    );
  }
}

class _Ruled extends StatelessWidget {
  const new({required this.showRule, required this.child});

  final bool showRule;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showRule ? BorderSide(color: colors.rule) : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: child,
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const new({
    required this.name,
    required this.amount,
    required this.imageUrl,
    required this.tiltLeft,
    super.key,
  });

  final String name;
  final String amount;
  final String? imageUrl;
  final bool tiltLeft;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final trimmed = name.trim();
    return Row(
      spacing: AppSpacing.md,
      children: [
        EatImageTile(
          imageUrl: imageUrl,
          size: AppGraphit.rowTile,
          angle: tiltLeft ? -AppGraphit.pictureTilt : AppGraphit.pictureTilt,
          fallbackLetter: trimmed.isEmpty
              ? null
              : trimmed.characters.first.toUpperCase(),
        ),
        Expanded(
          child: Text(
            name,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          amount,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MissingRow extends StatelessWidget {
  const new({
    required this.name,
    required this.onFill,
    required this.onIgnore,
    super.key,
  });

  final String name;
  final VoidCallback? onFill;
  final VoidCallback? onIgnore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final onFill = this.onFill;
    final onIgnore = this.onIgnore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        Text(
          name,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.low,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          l10n.eatPageIngredientMissing,
          style: textTheme.labelSmall?.copyWith(color: colors.low),
        ),
        Wrap(
          spacing: AppSpacing.lg,
          children: [
            if (onFill != null)
              EatTextLink(
                buttonKey: ValueKey('eat_meal_fill_$name'),
                label: l10n.preparedMealPendingIngredientAddAction,
                onPressed: onFill,
              ),
            if (onIgnore != null)
              EatTextLink(
                buttonKey: ValueKey('eat_meal_ignore_$name'),
                label: l10n.preparedMealPendingIngredientIgnoreAction,
                onPressed: onIgnore,
                isMuted: true,
              ),
          ],
        ),
      ],
    );
  }
}
