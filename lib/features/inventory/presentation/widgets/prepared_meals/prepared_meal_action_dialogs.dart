import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
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
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'prepared_meal_eat_sheet_widgets.dart';

const _defaultPreparedMealPortions = 1.0;
const _preparedMealDialogsLogName = 'PreparedMealDialogs';

enum _PreparedMealEatAmountMode { portions, grams }

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
  final num portions;

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
  DateTime? initialLoggedAt,
  MealType? initialMealType,
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
        initialLoggedAt: initialLoggedAt,
        initialMealType: initialMealType,
      );
    },
  );
}

/// Show prepared meal portion dialog.
Future<num?> showPreparedMealPortionDialog({
  required BuildContext context,
  required PreparedMeal meal,
  required String title,
  bool useRootNavigator = false,
}) {
  return showDialog<num>(
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
    this.initialLoggedAt,
    this.initialMealType,
  });

  final PreparedMeal meal;
  final PreparedMealDayPicker pickLoggedDay;
  final Uint8List? imageBytes;
  final DateTime? initialLoggedAt;
  final MealType? initialMealType;

  @override
  State<_PreparedMealEatSheet> createState() => _PreparedMealEatSheetState();
}

class _PreparedMealEatSheetState extends State<_PreparedMealEatSheet> {
  late final TextEditingController _portionsController;
  late final FocusNode _portionsFocusNode = FocusNode();
  late DateTime _selectedLoggedAt;
  late MealType _selectedMealType;
  _PreparedMealEatAmountMode _selectedAmountMode =
      _PreparedMealEatAmountMode.portions;
  bool _hasInitializedPortionsText = false;
  String? _portionsErrorText;

  @override
  void initState() {
    super.initState();
    _portionsController = TextEditingController();
    _selectedLoggedAt = widget.initialLoggedAt ?? DateTime.now();
    _selectedMealType =
        widget.initialMealType ??
        MealType.defaultForDateTime(
          _selectedLoggedAt,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedPortionsText) {
      return;
    }
    _portionsController.text = _defaultPortionsText(
      widget.meal.remainingPortions,
      AppLocalizations.of(context)!.localeName,
    );
    _hasInitializedPortionsText = true;
  }

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
    final canUseGrams = _canUseGramAmountMode(widget.meal);

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
          amountMode: _selectedAmountMode,
          canUseGrams: canUseGrams,
          selectedAmount: _selectedQuickAmount(),
          quickOptions: _buildQuickOptions(l10n),
          remainingLabel: _remainingAmountLabel(l10n),
          onAmountModeChanged: canUseGrams ? _updateAmountMode : null,
          clearTooltip: l10n.inventoryItemEatSheetClearAmountAction,
          onChanged: _clearPortionsError,
          onClearAndFocus: _clearPortionsAndFocus,
          onSubmitted: _dismissKeyboard,
          onQuickOptionSelected: _selectAmount,
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
    num portions,
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
    return switch (_selectedAmountMode) {
      _PreparedMealEatAmountMode.portions => _buildPortionQuickOptions(l10n),
      _PreparedMealEatAmountMode.grams => _buildGramQuickOptions(l10n),
    };
  }

  List<_PreparedMealQuickOption> _buildPortionQuickOptions(
    AppLocalizations l10n,
  ) {
    final values = <num>{};
    final options = <_PreparedMealQuickOption>[];

    void addOption(num value, String label) {
      if (value <= 0 || value > widget.meal.remainingPortions) {
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
    for (final value in const [0.5, 1.0, 2.0, 3.0]) {
      addOption(value, _formatPortions(value, l10n));
    }
    return options;
  }

  List<_PreparedMealQuickOption> _buildGramQuickOptions(AppLocalizations l10n) {
    final remainingGrams = _remainingGramAmount(widget.meal);
    if (remainingGrams == null || remainingGrams <= 0) {
      return const <_PreparedMealQuickOption>[];
    }
    final values = <num>{};
    final options = <_PreparedMealQuickOption>[];

    void addOption(num value, String label) {
      if (value <= 0 || value > remainingGrams) {
        return;
      }
      if (!values.add(value)) {
        return;
      }
      options.add(_PreparedMealQuickOption(label: label, value: value));
    }

    addOption(remainingGrams, l10n.inventoryItemEatSheetAllAction);
    for (final value in const [100, 250, 500]) {
      addOption(value, '${value}g');
    }
    return options;
  }

  num? _selectedQuickAmount() {
    return _parsePortions(_portionsController.text);
  }

  num? _selectedQuickPortions() {
    final amount = _selectedQuickAmount();
    if (amount == null) {
      return null;
    }
    return switch (_selectedAmountMode) {
      _PreparedMealEatAmountMode.portions => amount,
      _PreparedMealEatAmountMode.grams => _gramsToPortions(amount),
    };
  }

  String _remainingAmountLabel(AppLocalizations l10n) {
    if (_selectedAmountMode == _PreparedMealEatAmountMode.grams) {
      final remainingGrams = _remainingGramAmount(widget.meal) ?? 0;
      final totalGrams = widget.meal.finalNetWeight ?? 0;
      return '${_formatGrams(remainingGrams)} / ${_formatGrams(totalGrams)}';
    }
    return l10n.preparedMealPortionsRemaining(
      _formatPortions(widget.meal.remainingPortions, l10n),
      widget.meal.totalPortions,
    );
  }

  void _updateAmountMode(_PreparedMealEatAmountMode mode) {
    if (mode == _selectedAmountMode) {
      return;
    }
    final currentAmount = _parsePortions(_portionsController.text);
    final nextAmount = currentAmount == null
        ? null
        : switch (mode) {
            _PreparedMealEatAmountMode.portions => _gramsToPortions(
              currentAmount,
            ),
            _PreparedMealEatAmountMode.grams => _portionsToGrams(
              currentAmount,
            ),
          };
    setState(() {
      _selectedAmountMode = mode;
      _portionsErrorText = null;
      if (nextAmount != null && nextAmount > 0) {
        _portionsController.text = _formatModeAmount(nextAmount);
      }
    });
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

  void _selectAmount(num amount) {
    setState(() {
      _portionsController.text = _formatModeAmount(amount);
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
    final amount = _parsePortions(_portionsController.text);
    final portions = amount == null
        ? null
        : switch (_selectedAmountMode) {
            _PreparedMealEatAmountMode.portions => amount,
            _PreparedMealEatAmountMode.grams => _gramsToPortions(amount),
          };
    if (amount == null ||
        !_isAmountInRange(amount) ||
        portions == null ||
        portions <= 0 ||
        portions > widget.meal.remainingPortions) {
      log(
        'showPreparedMealEatDialog(): invalid amount '
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

  bool _isAmountInRange(num amount) {
    if (amount <= 0) {
      return false;
    }
    return switch (_selectedAmountMode) {
      _PreparedMealEatAmountMode.portions =>
        amount <= widget.meal.remainingPortions,
      _PreparedMealEatAmountMode.grams =>
        amount <= (_remainingGramAmount(widget.meal) ?? 0),
    };
  }

  num? _gramsToPortions(num grams) {
    final finalNetWeight = widget.meal.finalNetWeight;
    if (finalNetWeight == null ||
        finalNetWeight <= 0 ||
        widget.meal.totalPortions < 1) {
      return null;
    }
    return grams * widget.meal.totalPortions / finalNetWeight;
  }

  num? _portionsToGrams(num portions) {
    final finalNetWeight = widget.meal.finalNetWeight;
    if (finalNetWeight == null ||
        finalNetWeight <= 0 ||
        widget.meal.totalPortions < 1) {
      return null;
    }
    return portions * finalNetWeight / widget.meal.totalPortions;
  }

  String _formatModeAmount(num amount) {
    return switch (_selectedAmountMode) {
      _PreparedMealEatAmountMode.portions => _formatPortions(
        amount,
        AppLocalizations.of(context)!,
      ),
      _PreparedMealEatAmountMode.grams => formatInventoryAmountValue(
        amount: amount.round(),
        unit: InventoryAmountUnit.gram,
      ),
    };
  }
}

num? _parsePortions(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    return null;
  }
  final rounded = parsed.roundToDouble();
  if ((parsed - rounded).abs() < 0.000001) {
    return rounded.toInt();
  }
  return parsed;
}

bool _canUseGramAmountMode(PreparedMeal meal) {
  final finalNetWeight = meal.finalNetWeight;
  return finalNetWeight != null && finalNetWeight > 0 && meal.totalPortions > 0;
}

int? _remainingGramAmount(PreparedMeal meal) {
  final remainingNetWeight = meal.remainingNetWeight;
  if (remainingNetWeight != null) {
    return remainingNetWeight < 0 ? 0 : remainingNetWeight;
  }
  final finalNetWeight = meal.finalNetWeight;
  if (finalNetWeight == null ||
      finalNetWeight < 1 ||
      meal.totalPortions < 1 ||
      meal.remainingPortions <= 0) {
    return null;
  }
  return ((finalNetWeight * meal.remainingPortions) / meal.totalPortions)
      .round();
}

String _formatGrams(num grams) {
  return '${formatInventoryAmountValue(
    amount: grams.round(),
    unit: InventoryAmountUnit.gram,
  )}g';
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
    _controller.text = _defaultPortionsText(
      widget.meal.remainingPortions,
      AppLocalizations.of(context)!.localeName,
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
            final portions = _parsePortions(_controller.text);
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
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatPortions(num portions, AppLocalizations l10n) {
  return formatPreparedMealPortions(portions, localeName: l10n.localeName);
}

String _defaultPortionsText(num remainingPortions, String localeName) {
  if (remainingPortions <= 0 ||
      remainingPortions >= _defaultPreparedMealPortions) {
    return formatPreparedMealPortions(
      _defaultPreparedMealPortions,
      localeName: localeName,
    );
  }
  return formatPreparedMealPortions(
    remainingPortions,
    localeName: localeName,
  );
}
