import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/weight_entry_dialog.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/models/progress_weighing_action.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The sheet that changes the weight, day, and time of an own [weighing], or
/// deletes it; an ignored one can count again. Pops the
/// [ProgressWeighingAction].
class ProgressWeighingEditSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({required this.weighing, required this.now, super.key});

  /// Key of the weight field.
  static const weightKey = ValueKey<String>('progress-weighing-weight');

  /// Key of the day button.
  static const dayKey = ValueKey<String>('progress-weighing-day');

  /// Key of the time button.
  static const timeKey = ValueKey<String>('progress-weighing-time');

  /// Key of the delete button.
  static const deleteKey = ValueKey<String>('progress-weighing-delete');

  /// Key of the save button.
  static const saveKey = ValueKey<String>('progress-weighing-save');

  /// Key of the count again button of an ignored weighing.
  static const countKey = ValueKey<String>('progress-weighing-count');

  /// The weighing that changes.
  final ProgressWeighing weighing;

  /// The current time, the latest time a weighing can have.
  final DateTime now;

  @override
  State<ProgressWeighingEditSheet> createState() =>
      _ProgressWeighingEditSheetState();
}

class _ProgressWeighingEditSheetState extends State<ProgressWeighingEditSheet> {
  late final String _initialText = widget.weighing.weightKg.toStringAsFixed(1);
  late final TextEditingController _weight = TextEditingController(
    text: _initialText,
  );
  // A weighing of 3.8.1 and older has no time; it starts at midday.
  late DateTime _at =
      widget.weighing.at ?? widget.weighing.day.add(const Duration(hours: 12));
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(2000),
      lastDate: widget.now,
    );
    if (picked != null && mounted) {
      setState(
        () => _at = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _at.hour,
          _at.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (picked != null && mounted) {
      setState(
        () => _at = DateTime(
          _at.year,
          _at.month,
          _at.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final parsed = parseWeightKg(_weight.text);
    if (parsed == null) {
      setState(
        () => _error = _weight.text.trim().isEmpty
            ? l10n.caloriesCalculatorWeightEmpty
            : l10n.caloriesCalculatorWeightInvalid,
      );
      return;
    }
    // The field shows one decimal, so an untouched field keeps the weight.
    final weightKg = parsed == parseWeightKg(_initialText)
        ? widget.weighing.weightKg
        : parsed;
    Navigator.of(context).pop<ProgressWeighingAction>(
      ProgressWeighingSave(
        at: _at.isAfter(widget.now) ? widget.now : _at,
        weightKg: weightKg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final error = Theme.of(context).colorScheme.error;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.progressWeighingEditTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              key: ProgressWeighingEditSheet.weightKey,
              controller: _weight,
              keyboardType: weightKeyboardType,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.caloriesCalculatorWeightLabel,
                errorText: _error,
              ),
            ),
            Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: _LabeledButton(
                    key: ProgressWeighingEditSheet.dayKey,
                    label: l10n.progressWeighingDayLabel,
                    value: DateFormat.yMEd(locale).format(_at),
                    onPressed: () => unawaited(_pickDay()),
                  ),
                ),
                Expanded(
                  child: _LabeledButton(
                    key: ProgressWeighingEditSheet.timeKey,
                    label: l10n.progressWeighingTimeLabel,
                    value: DateFormat.Hm(locale).format(_at),
                    onPressed: () => unawaited(_pickTime()),
                  ),
                ),
              ],
            ),
            if (widget.weighing.isIgnored)
              OutlinedButton(
                key: ProgressWeighingEditSheet.countKey,
                onPressed: () => Navigator.of(context)
                    .pop<ProgressWeighingAction>(
                      const ProgressWeighingIgnore(ignored: false),
                    ),
                child: Text(l10n.progressWeighingCount),
              ),
            Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ProgressWeighingEditSheet.deleteKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: error,
                      side: BorderSide(color: error),
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop<ProgressWeighingAction>(
                          const ProgressWeighingDelete(),
                        ),
                    child: Text(l10n.progressWeighingDelete),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: ProgressWeighingEditSheet.saveKey,
                    onPressed: _save,
                    child: Text(l10n.diaryWeightSaveAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A button that shows [value] under its [label].
class _LabeledButton extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textTheme.labelSmall),
            Text(value, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
