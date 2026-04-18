import 'package:flutter/material.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show calorie health weight dialog.
Future<void> showCalorieHealthWeightDialog({
  required BuildContext context,
  required String dayLabel,
  required double? initialWeightKg,
  required bool hasManualWeight,
  required Future<bool> Function(double weightKg) onSaveWeight,
  required Future<bool> Function() onClearWeight,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<_CalorieHealthWeightDialogResult>(
    context: context,
    builder: (context) {
      return _CalorieHealthWeightDialogContent(
        dayLabel: dayLabel,
        initialWeightKg: initialWeightKg,
        hasManualWeight: hasManualWeight,
      );
    },
  );

  if (!context.mounted || result == null) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

  switch (result.action) {
    case _CalorieHealthWeightDialogAction.save:
      final weightKg = result.weightKg;
      if (weightKg == null) {
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
}

class _CalorieHealthWeightDialogContent extends StatefulWidget {
  const _CalorieHealthWeightDialogContent({
    required this.dayLabel,
    required this.initialWeightKg,
    required this.hasManualWeight,
  });

  final String dayLabel;
  final double? initialWeightKg;
  final bool hasManualWeight;

  @override
  State<_CalorieHealthWeightDialogContent> createState() =>
      _CalorieHealthWeightDialogContentState();
}

class _CalorieHealthWeightDialogContentState
    extends State<_CalorieHealthWeightDialogContent> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialWeightKg?.toStringAsFixed(1) ?? '',
    );
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
      title: Text(l10n.caloriesHealthTrendsWeightDialogTitle(widget.dayLabel)),
      content: TextField(
        key: CalorieHealthTrendsPageKeys.weightDialogField,
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.caloriesCalculatorWeightLabel,
          errorText: _errorText,
        ),
      ),
      actions: <Widget>[
        if (widget.hasManualWeight)
          TextButton(
            key: CalorieHealthTrendsPageKeys.weightDialogClearButton,
            onPressed: () => Navigator.of(
              context,
            ).pop(const _CalorieHealthWeightDialogResult.clear()),
            child: Text(l10n.caloriesHealthTrendsWeightClearAction),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: CalorieHealthTrendsPageKeys.weightDialogSaveButton,
          onPressed: _save,
          child: Text(l10n.caloriesHealthTrendsWeightSaveAction),
        ),
      ],
    );
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final rawWeight = _controller.text.trim().replaceAll(',', '.');
    if (rawWeight.isEmpty) {
      setState(() {
        _errorText = l10n.caloriesCalculatorWeightEmpty;
      });
      return;
    }

    final parsedWeight = double.tryParse(rawWeight);
    if (parsedWeight == null || parsedWeight <= 0) {
      setState(() {
        _errorText = l10n.caloriesCalculatorWeightInvalid;
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(_CalorieHealthWeightDialogResult.save(parsedWeight));
  }
}

class _CalorieHealthWeightDialogResult {
  const _CalorieHealthWeightDialogResult._({
    required this.action,
    this.weightKg,
  });

  const _CalorieHealthWeightDialogResult.clear()
    : this._(action: _CalorieHealthWeightDialogAction.clear);

  const _CalorieHealthWeightDialogResult.save(double weightKg)
    : this._(action: _CalorieHealthWeightDialogAction.save, weightKg: weightKg);

  final _CalorieHealthWeightDialogAction action;
  final double? weightKg;
}

enum _CalorieHealthWeightDialogAction { save, clear }
