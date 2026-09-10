import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recurrence input fields; the owning dialog manages their lifecycle.
class ShoppingScheduleForm extends StatelessWidget {
  /// Creates the schedule form.
  const ShoppingScheduleForm({
    required this.formKey,
    required this.days,
    required this.quantity,
    required this.date,
    required this.onPickDate,
    super.key,
  });

  /// Validation state owned by the dialog.
  final GlobalKey<FormState> formKey;

  /// Interval input.
  final TextEditingController days;

  /// Quantity input.
  final TextEditingController quantity;

  /// Selected first due date.
  final DateTime date;

  /// Opens the date picker.
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(mainAxisSize: MainAxisSize.min, children: _fields(context)),
  );

  List<Widget> _fields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(l10n.shoppingListScheduleExplanation),
      const SizedBox(height: 16),
      _numberField(context, days, l10n.shoppingListScheduleDays, 365),
      const SizedBox(height: 12),
      _numberField(context, quantity, l10n.shoppingListQuantityLabel, 999),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onPickDate,
        icon: const Icon(Icons.calendar_today),
        label: Text(_dateLabel(context)),
      ),
    ];
  }

  String _dateLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = DateFormat.yMd(locale).format(date);
    return '${AppLocalizations.of(context)!.shoppingListFirstDue}: $formatted';
  }

  Widget _numberField(
    BuildContext context,
    TextEditingController controller,
    String label,
    int max,
  ) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = int.tryParse(value ?? '') ?? 0;
      return number >= 1 && number <= max
          ? null
          : AppLocalizations.of(context)!.shoppingListNumberRange(max);
    },
  );
}
