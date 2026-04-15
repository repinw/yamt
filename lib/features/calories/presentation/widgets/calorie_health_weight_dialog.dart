import 'package:flutter/material.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> showCalorieHealthWeightDialog({
  required BuildContext context,
  required String dayLabel,
  required double? initialWeightKg,
  required bool hasManualWeight,
  required Future<bool> Function(double weightKg) onSaveWeight,
  required Future<bool> Function() onClearWeight,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: initialWeightKg?.toStringAsFixed(1) ?? '',
  );
  double? parsedWeight;
  String? errorText;

  final action = await showDialog<_CalorieHealthWeightDialogAction>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.caloriesHealthTrendsWeightDialogTitle(dayLabel)),
            content: TextField(
              key: CalorieHealthTrendsPageKeys.weightDialogField,
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.caloriesCalculatorWeightLabel,
                errorText: errorText,
              ),
            ),
            actions: <Widget>[
              if (hasManualWeight)
                TextButton(
                  key: CalorieHealthTrendsPageKeys.weightDialogClearButton,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_CalorieHealthWeightDialogAction.clear),
                  child: Text(l10n.caloriesHealthTrendsWeightClearAction),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              FilledButton(
                key: CalorieHealthTrendsPageKeys.weightDialogSaveButton,
                onPressed: () {
                  final rawWeight = controller.text.trim().replaceAll(',', '.');
                  if (rawWeight.isEmpty) {
                    setState(() {
                      errorText = l10n.caloriesCalculatorWeightEmpty;
                    });
                    return;
                  }

                  parsedWeight = double.tryParse(rawWeight);
                  if (parsedWeight == null || parsedWeight! <= 0) {
                    setState(() {
                      errorText = l10n.caloriesCalculatorWeightInvalid;
                    });
                    return;
                  }

                  Navigator.of(
                    context,
                  ).pop(_CalorieHealthWeightDialogAction.save);
                },
                child: Text(l10n.caloriesHealthTrendsWeightSaveAction),
              ),
            ],
          );
        },
      );
    },
  );

  if (!context.mounted || action == null) {
    _disposeControllerLater(controller);
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  switch (action) {
    case _CalorieHealthWeightDialogAction.save:
      final weightKg = parsedWeight;
      if (weightKg == null) {
        _disposeControllerLater(controller);
        return;
      }
      final saved = await onSaveWeight(weightKg);
      if (context.mounted && !saved) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.caloriesHealthTrendsWeightSaveFailed)),
        );
      }
    case _CalorieHealthWeightDialogAction.clear:
      final cleared = await onClearWeight();
      if (context.mounted && !cleared) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.caloriesHealthTrendsWeightClearFailed)),
        );
      }
  }

  _disposeControllerLater(controller);
}

enum _CalorieHealthWeightDialogAction { save, clear }

void _disposeControllerLater(TextEditingController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
