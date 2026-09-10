import 'package:flutter/material.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_schedule_dialog/shopping_schedule_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Editable recurrence settings returned only after confirmation.
typedef ShoppingScheduleInput = ({int days, int quantity, DateTime firstDue});

/// Edits an interval, quantity and first due date.
Future<ShoppingScheduleInput?> showShoppingScheduleDialog(
  BuildContext context,
  ShoppingListItem item,
) => showDialog<ShoppingScheduleInput>(
  context: context,
  builder: (_) => _ScheduleDialog(item: item),
);

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.item});
  final ShoppingListItem item;
  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _form = GlobalKey<FormState>();
  late final _days = TextEditingController(
    text:
        '${widget.item.repeatEveryDays > 0 ? widget.item.repeatEveryDays : 7}',
  );
  late final _quantity = TextEditingController(
    text: '${_initialQuantity()}',
  );
  late DateTime _date =
      widget.item.nextDueDate ?? DateTime.now().add(const Duration(days: 7));

  int _initialQuantity() => widget.item.repeatEveryDays > 0
      ? widget.item.repeatQuantity
      : widget.item.quantity.clamp(1, 999);

  @override
  void dispose() {
    _days.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.shoppingListSchedule),
      scrollable: true,
      content: ShoppingScheduleForm(
        formKey: _form,
        days: _days,
        quantity: _quantity,
        date: _date,
        onPickDate: _pickDate,
      ),
      actions: _actions(l10n),
    );
  }

  List<Widget> _actions(AppLocalizations l10n) => [
    if (widget.item.repeatEveryDays > 0)
      TextButton(
        onPressed: () =>
            Navigator.pop(context, (days: 0, quantity: 1, firstDue: _date)),
        child: Text(l10n.shoppingListStopSchedule),
      ),
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.inventoryReceiptReviewCancelAction),
    ),
    FilledButton(
      onPressed: _save,
      child: Text(l10n.shoppingListSaveSettings),
    ),
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (
      days: int.parse(_days.text),
      quantity: int.parse(_quantity.text),
      firstDue: _date,
    ));
  }
}
