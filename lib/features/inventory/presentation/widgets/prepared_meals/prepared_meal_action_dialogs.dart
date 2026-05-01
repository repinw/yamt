import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_amount_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip_scroller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_sheet_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_when_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'prepared_meal_eat_sheet_widgets.dart';

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
  Uint8List? imageBytes,
}) {
  return showModalBottomSheet<PreparedMealEatDialogResult>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) {
      return _PreparedMealEatSheet(
        meal: meal,
        pickLoggedDay: pickLoggedDay ?? _showPreparedMealDayPicker,
        imageBytes: imageBytes,
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

class _PreparedMealEatSheet extends StatefulWidget {
  const _PreparedMealEatSheet({
    required this.meal,
    required this.pickLoggedDay,
    required this.imageBytes,
  });

  final PreparedMeal meal;
  final PreparedMealDayPicker pickLoggedDay;
  final Uint8List? imageBytes;

  @override
  State<_PreparedMealEatSheet> createState() => _PreparedMealEatSheetState();
}

class _PreparedMealEatSheetState extends State<_PreparedMealEatSheet> {
  late final TextEditingController _portionsController = TextEditingController(
    text: _defaultPreparedMealPortions.toString(),
  );
  late final FocusNode _portionsFocusNode = FocusNode();
  late DateTime _selectedLoggedAt = DateTime.now();
  late MealType _selectedMealType = MealType.defaultForDateTime(
    _selectedLoggedAt,
  );
  String? _portionsErrorText;

  @override
  void dispose() {
    _portionsFocusNode.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final isLoggedAtToday = _isLoggedAtToday();
    final loggedAtLabel = isLoggedAtToday
        ? null
        : material.formatMediumDate(_selectedLoggedAt);
    final selectedPortions = _selectedQuickPortions();
    final metrics = _buildNutritionMetrics(l10n, selectedPortions ?? 1);

    return InventoryEatFlowSheetScaffold(
      viewInsetsBottom: MediaQuery.viewInsetsOf(context).bottom,
      hero: _PreparedMealEatHero(
        meal: widget.meal,
        imageBytes: widget.imageBytes,
      ),
      confirmActionText: l10n.inventoryItemEatSheetConfirmAction,
      confirmButtonKey: const Key('prepared_meal_eat_confirm_button'),
      onConfirm: _submit,
      children: [
        if (metrics.isNotEmpty) ...[
          NutritionMetricsStrip(
            metrics: metrics,
            highlightedMetricIndex: 0,
            metricValueKeyPrefix: 'prepared_meal_nutrition_value',
            metricLabelKeyPrefix: 'prepared_meal_nutrition_label',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        _PreparedMealEatPortionsSection(
          controller: _portionsController,
          focusNode: _portionsFocusNode,
          errorText: _portionsErrorText,
          selectedPortions: selectedPortions,
          quickOptions: _buildQuickOptions(l10n),
          remainingLabel: l10n.preparedMealPortionsRemaining(
            widget.meal.remainingPortions,
            widget.meal.totalPortions,
          ),
          clearTooltip: l10n.inventoryItemEatSheetClearAmountAction,
          onChanged: _clearPortionsError,
          onClearAndFocus: _clearPortionsAndFocus,
          onSubmitted: _dismissKeyboard,
          onQuickOptionSelected: _selectPortions,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        InventoryEatFlowWhenSection(
          isToday: isLoggedAtToday,
          label: loggedAtLabel,
          selectedMealType: _selectedMealType,
          loggedAtButtonKey: const Key('prepared_meal_logged_at_button'),
          loggedAtCompactKey: const Key('prepared_meal_logged_at_compact'),
          loggedAtLabeledKey: const Key('prepared_meal_logged_at_labeled'),
          onPickLoggedAt: _pickLoggedDay,
          onMealTypeSelected: _selectMealType,
        ),
      ],
    );
  }

  List<NutritionMetric> _buildNutritionMetrics(
    AppLocalizations l10n,
    int portions,
  ) {
    if (widget.meal.totalPortions < 1) {
      return const <NutritionMetric>[];
    }

    final multiplier = portions / widget.meal.totalPortions;
    return [
      NutritionMetric(
        label: l10n.inventoryNutritionCaloriesShortLabel,
        value: (widget.meal.totalKcal * multiplier).round().toString(),
      ),
      NutritionMetric(
        label: l10n.inventoryNutritionCarbsShortLabel,
        value:
            '${formatInventoryNutritionValue(
              widget.meal.totalCarbs * multiplier,
            )}g',
      ),
      NutritionMetric(
        label: l10n.caloriesProteinLabel,
        value:
            '${formatInventoryNutritionValue(
              widget.meal.totalProtein * multiplier,
            )}g',
      ),
      NutritionMetric(
        label: l10n.caloriesFatLabel,
        value:
            '${formatInventoryNutritionValue(
              widget.meal.totalFat * multiplier,
            )}g',
      ),
    ];
  }

  List<_PreparedMealQuickOption> _buildQuickOptions(AppLocalizations l10n) {
    final values = <int>{};
    final options = <_PreparedMealQuickOption>[];

    void addOption(int value, String label) {
      if (value < 1 || value > widget.meal.remainingPortions) {
        return;
      }
      if (!values.add(value)) {
        return;
      }
      options.add(_PreparedMealQuickOption(label: label, value: value));
    }

    addOption(
      widget.meal.remainingPortions,
      l10n.inventoryItemEatSheetAllAction,
    );
    for (final value in const [1, 2, 3]) {
      addOption(value, value.toString());
    }
    return options;
  }

  int? _selectedQuickPortions() {
    return int.tryParse(_portionsController.text.trim());
  }

  void _clearPortionsError(String _) {
    if (_portionsErrorText == null) {
      return;
    }
    setState(() {
      _portionsErrorText = null;
    });
  }

  void _clearPortionsAndFocus() {
    setState(() {
      _portionsController.clear();
      _portionsErrorText = null;
    });
    _portionsFocusNode.requestFocus();
  }

  void _selectPortions(int portions) {
    setState(() {
      _portionsController.text = portions.toString();
      _portionsErrorText = null;
    });
  }

  void _selectMealType(MealType mealType) {
    setState(() {
      _selectedMealType = mealType;
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool _isLoggedAtToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedLoggedAt);
    return selectedDay == today;
  }

  Future<void> _pickLoggedDay() async {
    final firstDate = DateTime(2000);
    final lastDate = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedLoggedAt);
    final pickedDate = await widget.pickLoggedDay(
      context: context,
      initialDate: selectedDay.isAfter(lastDate) ? lastDate : selectedDay,
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
      final now = DateTime.now();
      _selectedLoggedAt = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        now.hour,
        now.minute,
      );
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final portions = int.tryParse(_portionsController.text.trim());
    if (portions == null ||
        portions < 1 ||
        portions > widget.meal.remainingPortions) {
      log(
        'showPreparedMealEatDialog(): invalid portions '
        '"${_portionsController.text}" for meal ${widget.meal.id}',
        name: _preparedMealDialogsLogName,
      );
      setState(() {
        _portionsErrorText = l10n.preparedMealInvalidPortionsRange;
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      PreparedMealEatDialogResult(
        portions: portions,
        mealType: _selectedMealType,
        loggedDay: _selectedLoggedAt,
      ),
    );
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
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
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

  void _fillRemainingPortions() {
    final value = widget.meal.remainingPortions.toString();
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
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
