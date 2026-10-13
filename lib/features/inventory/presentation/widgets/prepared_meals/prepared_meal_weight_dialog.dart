import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_portions.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_weight_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Room for "99.999,9", the largest weight with a separator and a decimal.
const _maxWeightLength = 8;

/// Asks for the weight of the food of the cooked [meal] now and returns its
/// grams of food, or null when the cook cancels.
///
/// A meal weighed in its pot at "Gekocht" asks for the pot on the scale and
/// takes the empty pot off; any other meal asks for the food alone. Before
/// the first portion is gone that is the whole dish, afterwards what is
/// left.
Future<int?> showPreparedMealWeightDialog({
  required BuildContext context,
  required PreparedMeal meal,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => PreparedMealWeightDialog(meal: meal),
  );
}

/// The dialog of [showPreparedMealWeightDialog].
class PreparedMealWeightDialog extends StatefulWidget {
  /// Creates the dialog for [meal].
  const new({required this.meal, super.key});

  /// Key of the weight field.
  static const fieldKey = Key('prepared_meal_weight_field');

  /// Key of the line that takes the empty pot off.
  static const netKey = Key('prepared_meal_weight_net');

  /// Key of the save button.
  static const saveKey = Key('prepared_meal_weight_save');

  /// The cooked meal.
  final PreparedMeal meal;

  @override
  State<PreparedMealWeightDialog> createState() =>
      _PreparedMealWeightDialogState();
}

class _PreparedMealWeightDialogState extends State<PreparedMealWeightDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final meal = widget.meal;
    final tare = meal.potTareWeight;
    final entry = PreparedMealWeightEntry(_controller.text, tareWeight: tare);
    final net = entry.netWeight;
    final current = meal.remainingNetWeight;

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.preparedMealWeightAction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Text(
            meal.remainingPortions >= meal.totalPortions
                ? l10n.preparedMealWeightWholeHint
                : l10n.preparedMealWeightLeftHint(
                    formatPreparedMealPortions(
                      meal.remainingPortions,
                      localeName: l10n.localeName,
                    ),
                    meal.totalPortions,
                  ),
          ),
          TextField(
            key: PreparedMealWeightDialog.fieldKey,
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(_maxWeightLength),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(net),
            decoration: InputDecoration(
              labelText: tare == null
                  ? l10n.preparedMealWeightFoodLabel
                  : l10n.eatPotWeighTitle,
              suffixText: l10n.inventoryUnitGram,
              // With the pot on the scale, the pot as it weighed last time.
              helperText: current != null && current > 0
                  ? l10n.preparedMealWeightCurrent(current + (tare ?? 0))
                  : null,
              errorText: entry.isTooLight
                  ? l10n.cookedTooLight
                  : entry.isInvalid
                  ? l10n.preparedMealWeightInvalid
                  : null,
            ),
          ),
          if (tare != null && net != null)
            Text(
              l10n.eatPotNetWeight(tare, net),
              key: PreparedMealWeightDialog.netKey,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: PreparedMealWeightDialog.saveKey,
          onPressed: net == null ? null : () => _save(net),
          child: Text(l10n.inventoryReceiptReviewSaveAction),
        ),
      ],
    );
  }

  void _save(int? net) {
    if (net == null) {
      return;
    }
    Navigator.of(context).pop(net);
  }
}
