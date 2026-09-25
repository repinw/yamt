import 'dart:developer' show log;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _preparedMealDialogsLogName = 'PreparedMealDialogs';

/// Show prepared meal portion dialog.
Future<num?> showPreparedMealPortionDialog({
  required BuildContext context,
  required PreparedMeal meal,
  required String title,
}) {
  return showDialog<num>(
    context: context,
    builder: (dialogContext) {
      return _PreparedMealPortionDialog(meal: meal, title: title);
    },
  );
}

class _PreparedMealPortionDialog extends StatefulWidget {
  const new({required this.meal, required this.title});

  final PreparedMeal meal;
  final String title;

  @override
  State<_PreparedMealPortionDialog> createState() =>
      _PreparedMealPortionDialogState();
}

class _PreparedMealPortionDialogState
    extends State<_PreparedMealPortionDialog> {
  late final TextEditingController _controller;
  bool _hasInitializedPortionsText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedPortionsText) {
      return;
    }
    _controller.text = formatPreparedMealPortions(
      PreparedMealEatCalculator(widget.meal).defaultPortions,
      localeName: AppLocalizations.of(context)!.localeName,
    );
    _hasInitializedPortionsText = true;
  }

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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.preparedMealPortionsToUseLabel,
          helperText: l10n.preparedMealPortionsRemaining(
            _formatPortions(widget.meal.remainingPortions, l10n),
            widget.meal.totalPortions,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: TextButton(
              key: const Key('prepared_meal_portion_dialog_fill_button'),
              onPressed: _fillRemainingPortions,
              child: Text(l10n.inventoryAmountDialogAllRemainingAction),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(),
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
            final portions = parsePreparedMealAmountInput(_controller.text);
            if (portions == null ||
                portions <= 0 ||
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

  void _fillRemainingPortions() {
    final value = _formatPortions(
      widget.meal.remainingPortions,
      AppLocalizations.of(context)!,
    );
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

void _showInvalidPortionsSnackBar({
  required BuildContext scaffoldContext,
  required String message,
}) {
  ScaffoldMessenger.of(scaffoldContext)
      .showAppSnackBar(message, tone: AppSnackBarTone.error);
}

String _formatPortions(num portions, AppLocalizations l10n) {
  return formatPreparedMealPortions(portions, localeName: l10n.localeName);
}
