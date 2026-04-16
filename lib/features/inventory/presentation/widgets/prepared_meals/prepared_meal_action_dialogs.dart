import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _defaultPreparedMealPortions = 1;
const _preparedMealDialogsLogName = 'PreparedMealDialogs';

/// Defines prepared meal day picker typedef.
typedef PreparedMealDayPicker =
    Future<DateTime?> Function({
      required BuildContext context,
      required DateTime initialDate,
      required DateTime firstDate,
      required DateTime lastDate,
    });

/// Defines prepared meal eat dialog result.
class PreparedMealEatDialogResult {
  /// The prepared meal eat dialog result.
  const PreparedMealEatDialogResult({
    required this.portions,
    required this.mealType,
    required this.loggedDay,
  });

  /// The portions.
  final int portions;

  /// The meal type.
  final MealType mealType;

  /// The logged day.
  final DateTime loggedDay;
}

/// Show prepared meal eat dialog.
Future<PreparedMealEatDialogResult?> showPreparedMealEatDialog(
  BuildContext context,
  PreparedMeal meal, {
  bool useRootNavigator = false,
  PreparedMealDayPicker? pickLoggedDay,
}) {
  return showDialog<PreparedMealEatDialogResult>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return _PreparedMealEatDialog(
        meal: meal,
        pickLoggedDay: pickLoggedDay ?? _showPreparedMealDayPicker,
      );
    },
  );
}

/// Show prepared meal portion dialog.
Future<int?> showPreparedMealPortionDialog({
  required BuildContext context,
  required PreparedMeal meal,
  required String title,
  bool useRootNavigator = false,
}) {
  return showDialog<int>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return _PreparedMealPortionDialog(meal: meal, title: title);
    },
  );
}

class _PreparedMealEatDialog extends StatefulWidget {
  const _PreparedMealEatDialog({
    required this.meal,
    required this.pickLoggedDay,
  });

  final PreparedMeal meal;
  final PreparedMealDayPicker pickLoggedDay;

  @override
  State<_PreparedMealEatDialog> createState() => _PreparedMealEatDialogState();
}

class _PreparedMealEatDialogState extends State<_PreparedMealEatDialog> {
  late final TextEditingController _portionsController = TextEditingController(
    text: _defaultPreparedMealPortions.toString(),
  );
  late DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());
  late MealType _selectedMealType = MealType.defaultForDateTime(DateTime.now());

  @override
  void dispose() {
    _portionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.preparedMealEatTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _portionsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.preparedMealPortionsToUseLabel,
              helperText: l10n.preparedMealPortionsRemaining(
                widget.meal.remainingPortions,
                widget.meal.totalPortions,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<MealType>(
            initialValue: _selectedMealType,
            decoration: InputDecoration(labelText: l10n.caloriesEntryMealLabel),
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
                _selectedMealType = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.preparedMealDiaryDayLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickLoggedDay,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(material.formatMediumDate(_selectedDay)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        TextButton(
          onPressed: () {
            final portions = int.tryParse(_portionsController.text.trim());
            if (portions == null ||
                portions < 1 ||
                portions > widget.meal.remainingPortions) {
              _showInvalidPortionsSnackBar(
                scaffoldContext: context,
                message: l10n.preparedMealInvalidPortionsRange,
              );
              return;
            }
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop(
              PreparedMealEatDialogResult(
                portions: portions,
                mealType: _selectedMealType,
                loggedDay: _selectedDay,
              ),
            );
          },
          child: Text(l10n.inventoryItemEatAction),
        ),
      ],
    );
  }

  Future<void> _pickLoggedDay() async {
    final firstDate = DateTime(2000);
    final lastDate = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await widget.pickLoggedDay(
      context: context,
      initialDate: _selectedDay.isAfter(lastDate) ? lastDate : _selectedDay,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    final normalizedDate = DateUtils.dateOnly(pickedDate);
    if (normalizedDate.isBefore(firstDate) ||
        normalizedDate.isAfter(lastDate)) {
      return;
    }

    setState(() {
      _selectedDay = normalizedDate;
    });
  }
}

Future<DateTime?> _showPreparedMealDayPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

class _PreparedMealPortionDialog extends StatefulWidget {
  const _PreparedMealPortionDialog({required this.meal, required this.title});

  final PreparedMeal meal;
  final String title;

  @override
  State<_PreparedMealPortionDialog> createState() =>
      _PreparedMealPortionDialogState();
}

class _PreparedMealPortionDialogState
    extends State<_PreparedMealPortionDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _defaultPreparedMealPortions.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.preparedMealPortionsToUseLabel,
          helperText: l10n.preparedMealPortionsRemaining(
            widget.meal.remainingPortions,
            widget.meal.totalPortions,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        TextButton(
          onPressed: () {
            final portions = int.tryParse(_controller.text.trim());
            if (portions == null ||
                portions < 1 ||
                portions > widget.meal.remainingPortions) {
              log(
                'showPreparedMealPortionDialog(): invalid portions '
                '"${_controller.text}" for meal ${widget.meal.id}',
                name: _preparedMealDialogsLogName,
              );
              _showInvalidPortionsSnackBar(
                scaffoldContext: context,
                message: l10n.preparedMealInvalidPortionsRange,
              );
              return;
            }
            FocusManager.instance.primaryFocus?.unfocus();
            log(
              'showPreparedMealPortionDialog(): confirmed '
              '(mealId=${widget.meal.id}, portions=$portions)',
              name: _preparedMealDialogsLogName,
            );
            Navigator.of(context).pop(portions);
          },
          child: Text(l10n.preparedMealConfirmAction),
        ),
      ],
    );
  }
}

void _showInvalidPortionsSnackBar({
  required BuildContext scaffoldContext,
  required String message,
}) {
  final messenger = ScaffoldMessenger.of(scaffoldContext);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
