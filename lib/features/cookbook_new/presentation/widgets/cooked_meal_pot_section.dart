import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Up to 99999 g, so the weight always parses.
const _maxWeightDigits = 5;

/// The "Topf" part of the "Gekocht" step: portions, the pot from the kitchen
/// utensils, the pot on the scale, and what that leaves for the food.
class CookedMealPotSection extends StatelessWidget {
  /// Creates the section.
  const new({
    required this.portions,
    required this.onPortionsChanged,
    required this.utensils,
    required this.utensilsFailed,
    required this.utensilId,
    required this.onUtensilChanged,
    required this.grossController,
    required this.result,
    super.key,
  });

  /// Key of the portion count.
  static const portionsKey = ValueKey<String>('cooked-portions');

  /// Key of the "one portion more" button.
  static const morePortionsKey = ValueKey<String>('cooked-portions-more');

  /// Key of the utensil picker.
  static const utensilKey = ValueKey<String>('cooked-utensil');

  /// Key of the utensil [id] in the picker.
  static ValueKey<String> utensilOptionKey(String id) =>
      ValueKey<String>('cooked-utensil-$id');

  /// Key of the weight field.
  static const grossKey = ValueKey<String>('cooked-gross');

  /// Number of portions.
  final int portions;

  /// Sets the number of portions.
  final ValueChanged<int> onPortionsChanged;

  /// The saved kitchen utensils.
  final List<KitchenUtensil> utensils;

  /// Whether the kitchen utensils could not be loaded.
  final bool utensilsFailed;

  /// Id of the pot, or `null` while none is picked.
  final String? utensilId;

  /// Picks the pot by its id.
  final ValueChanged<String?> onUtensilChanged;

  /// Holds the weight of the pot on the scale.
  final TextEditingController grossController;

  /// The food weight or per portion line under the weight field.
  final String result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(color: colors.ink);

    Widget row(Widget title, Widget control) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppGraphit.toolButton),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(child: title),
            control,
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        CookbookSectionTitle(title: l10n.cookedPotTitle),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(
              Text(l10n.cookedPortions, style: label),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l10n.cookedPortionsLess,
                    onPressed: portions > 1
                        ? () => onPortionsChanged(portions - 1)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppGraphit.badge,
                    ),
                    child: Text(
                      '$portions',
                      key: portionsKey,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: morePortionsKey,
                    tooltip: l10n.cookedPortionsMore,
                    onPressed: () => onPortionsChanged(portions + 1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            row(
              Text(l10n.cookedUtensil, style: label),
              Flexible(
                child: utensilsFailed
                    ? Text(
                        l10n.kitchenUtensilsLoadFailed,
                        style: textTheme.bodySmall?.copyWith(color: colors.low),
                      )
                    : AppDropdownButtonFormField<String?>(
                        key: utensilKey,
                        initialValue: utensilId,
                        isExpanded: true,
                        hint: Text(l10n.cookedPickUtensil),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: onUtensilChanged,
                        items: [
                          for (final item in utensils)
                            DropdownMenuItem(
                              key: utensilOptionKey(item.id),
                              value: item.id,
                              child: Text(switch (item.name) {
                                final name? => l10n.cookedUtensilOption(
                                  name,
                                  item.weightGrams,
                                ),
                                null => l10n.cookedUtensilWeight(
                                  item.weightGrams,
                                ),
                              }, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
              ),
            ),
            // Without a pot to pick the food weight cannot be told.
            if (!utensilsFailed && utensils.isNotEmpty)
              row(
                Text(l10n.cookedGrossWeight, style: label),
                SizedBox(
                  width: AppGraphit.numberField,
                  child: TextField(
                    key: grossKey,
                    controller: grossController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_maxWeightDigits),
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      suffixText: l10n.inventoryUnitGram,
                    ),
                  ),
                ),
              ),
            row(
              Text(
                l10n.cookedWeighTip,
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
              Flexible(
                child: Text(
                  result,
                  textAlign: TextAlign.end,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
