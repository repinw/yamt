import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _defaultPreparedMealPortions = 1;

class PreparedMealEatDialogResult {
  const PreparedMealEatDialogResult({
    required this.portions,
    required this.mealType,
  });

  final int portions;
  final MealType mealType;
}

Future<PreparedMealEatDialogResult?> showPreparedMealEatDialog(
  BuildContext context,
  PreparedMeal meal,
) {
  final l10n = AppLocalizations.of(context)!;
  final portionsController = TextEditingController(
    text: _defaultPreparedMealPortions.toString(),
  );
  var selectedMealType = MealType.defaultForDateTime(DateTime.now());

  return showDialog<PreparedMealEatDialogResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogChildContext, setState) {
          return AlertDialog(
            title: Text(l10n.preparedMealEatTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: portionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.preparedMealPortionsToUseLabel,
                    helperText: l10n.preparedMealPortionsRemaining(
                      meal.remainingPortions,
                      meal.totalPortions,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<MealType>(
                  initialValue: selectedMealType,
                  decoration: InputDecoration(
                    labelText: l10n.caloriesEntryMealLabel,
                  ),
                  items: MealType.sectionOrder
                      .map((mealType) {
                        return DropdownMenuItem<MealType>(
                          value: mealType,
                          child: Text(mealType.localizedName(l10n)),
                        );
                      })
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      selectedMealType = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              TextButton(
                onPressed: () {
                  final portions = int.tryParse(portionsController.text.trim());
                  if (portions == null ||
                      portions < 1 ||
                      portions > meal.remainingPortions) {
                    _showInvalidPortionsSnackBar(
                      scaffoldContext: context,
                      message: l10n.preparedMealInvalidPortionsRange,
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    PreparedMealEatDialogResult(
                      portions: portions,
                      mealType: selectedMealType,
                    ),
                  );
                },
                child: Text(l10n.inventoryItemEatAction),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(portionsController.dispose);
}

Future<int?> showPreparedMealPortionDialog({
  required BuildContext context,
  required PreparedMeal meal,
  required String title,
}) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: _defaultPreparedMealPortions.toString(),
  );

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.preparedMealPortionsToUseLabel,
            helperText: l10n.preparedMealPortionsRemaining(
              meal.remainingPortions,
              meal.totalPortions,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          TextButton(
            onPressed: () {
              final portions = int.tryParse(controller.text.trim());
              if (portions == null ||
                  portions < 1 ||
                  portions > meal.remainingPortions) {
                _showInvalidPortionsSnackBar(
                  scaffoldContext: context,
                  message: l10n.preparedMealInvalidPortionsRange,
                );
                return;
              }
              Navigator.of(dialogContext).pop(portions);
            },
            child: Text(l10n.preparedMealConfirmAction),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

void _showInvalidPortionsSnackBar({
  required BuildContext scaffoldContext,
  required String message,
}) {
  final messenger = ScaffoldMessenger.of(scaffoldContext);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
