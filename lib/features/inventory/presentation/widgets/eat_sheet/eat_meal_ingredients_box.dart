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
    'eat_meal_missing_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Zutaten" box of a meal's detail page: every ingredient with its picture
/// and its amount in the whole meal and an x that takes it out again, then
/// the missing recipe ingredients in the low color with links to fill or
/// ignore them, then the ignored ones struck through, which can still be
/// filled or opened again. An ingredient whose label lacks values says so,
/// since the meal's nutrients leave them out.
class EatMealIngredientsBox extends StatelessWidget {
  /// Creates the box for [meal].
  const new({
    required this.meal,
    required this.onFill,
    required this.onIgnore,
    required this.onUnignore,
    required this.onUnassign,
    super.key,
  });

  /// Key of the x that takes the food of the Vorrat item [itemId] out.
  static ValueKey<String> unassignKey(String itemId) =>
      ValueKey<String>('eat_meal_unassign_$itemId');

  /// Key of the open row [row].
  static ValueKey<String> openRowKey(String row) =>
      ValueKey<String>('eat_meal_missing_$row');

  /// Key of the ignored row [row].
  static ValueKey<String> ignoredRowKey(String row) =>
      ValueKey<String>('eat_meal_ignored_$row');

  /// Key of "Zutat ergänzen" of the open or ignored row [row].
  static ValueKey<String> fillKey(String row) =>
      ValueKey<String>('eat_meal_fill_$row');

  /// Key of "Nicht mehr ignorieren" of the ignored row [row].
  static ValueKey<String> unignoreKey(String row) =>
      ValueKey<String>('eat_meal_unignore_$row');

  /// Key of the note that the ingredient from the Vorrat item [itemId]
  /// lacks nutrition values.
  static Key incompleteKey(String itemId) =>
      ValueKey('eat_meal_ingredient_incomplete_$itemId');

  /// The meal.
  final PreparedMeal meal;

  /// Fills an open or ignored row from Vorrat foods; null while busy.
  final ValueChanged<String>? onFill;

  /// Ignores an open row; null while busy.
  final ValueChanged<String>? onIgnore;

  /// Opens an ignored row again; null while busy.
  final ValueChanged<String>? onUnignore;

  /// Takes a food out of the meal again; null while busy or once the
  /// ingredients can no longer change.
  final ValueChanged<PreparedMealComponent>? onUnassign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onUnassign = this.onUnassign;
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
          itemId: component.inventoryItemId,
          isIncomplete: component.hasIncompleteNutrition,
          tiltLeft: index.isEven,
          removeKey: unassignKey(component.inventoryItemId),
          onRemove: onUnassign == null ? null : () => onUnassign(component),
        ),
      for (final ingredient in meal.pendingRecipeIngredients)
        EatMealMissingRow(
          key: openRowKey(ingredient),
          name: ingredient,
          isIgnored: false,
          fillKey: fillKey(ingredient),
          toggleKey: ValueKey('eat_meal_ignore_$ingredient'),
          onFill: _bind(onFill, ingredient),
          onToggle: _bind(onIgnore, ingredient),
        ),
      for (final ingredient in meal.ignoredPendingRecipeIngredients)
        EatMealMissingRow(
          key: ignoredRowKey(ingredient),
          name: ingredient,
          isIgnored: true,
          fillKey: fillKey(ingredient),
          toggleKey: unignoreKey(ingredient),
          onFill: _bind(onFill, ingredient),
          onToggle: _bind(onUnignore, ingredient),
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

  static VoidCallback? _bind(ValueChanged<String>? action, String row) =>
      action == null ? null : () => action(row);
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
    required this.itemId,
    required this.isIncomplete,
    required this.tiltLeft,
    required this.removeKey,
    required this.onRemove,
    super.key,
  });

  final String name;
  final String amount;
  final String? imageUrl;
  final String itemId;

  /// Whether the ingredient's label lacks nutrition values.
  final bool isIncomplete;
  final bool tiltLeft;
  final Key removeKey;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final trimmed = name.trim();
    final onRemove = this.onRemove;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              Text(
                name,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isIncomplete)
                Text(
                  l10n.eatPageIngredientNutritionIncomplete,
                  key: EatMealIngredientsBox.incompleteKey(itemId),
                  style: textTheme.labelSmall?.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
        Text(
          amount,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onRemove != null)
          IconButton(
            key: removeKey,
            tooltip: AppLocalizations.of(context)!.preparedMealUnassignAction,
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: colors.muted),
          ),
      ],
    );
  }
}
