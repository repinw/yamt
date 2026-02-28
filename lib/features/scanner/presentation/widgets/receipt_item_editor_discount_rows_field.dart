import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ReceiptEditorDiscountRowsField extends StatefulWidget {
  const ReceiptEditorDiscountRowsField({
    super.key,
    required this.initialEntries,
    required this.onChanged,
    required this.errorText,
    required this.onSubmit,
  });

  final List<MapEntry<String, String>> initialEntries;
  final ValueChanged<List<MapEntry<String, String>>> onChanged;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  State<ReceiptEditorDiscountRowsField> createState() {
    return _ReceiptEditorDiscountRowsFieldState();
  }
}

class _ReceiptEditorDiscountRowsFieldState
    extends State<ReceiptEditorDiscountRowsField> {
  late final List<_DiscountRowControllers> _rows;
  late int _nextRowId;

  @override
  void initState() {
    super.initState();
    _rows = _buildRows(widget.initialEntries);
    _nextRowId = _rows.length;
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inventoryReceiptReviewFieldDiscounts,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < _rows.length; index++)
            _buildRow(context, l10n, index),
          TextButton.icon(
            key: const Key('receipt_review_discount_add_button'),
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: Text(l10n.inventoryReceiptReviewAddDiscountAction),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppLocalizations l10n, int index) {
    final row = _rows[index];

    return Padding(
      key: ValueKey<int>(row.id),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('receipt_review_discount_name_${row.id}'),
              controller: row.nameController,
              textInputAction: TextInputAction.next,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (_) => _notifyRowsChanged(),
              decoration: InputDecoration(
                labelText: l10n.inventoryReceiptReviewDiscountNameLabel,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              key: Key('receipt_review_discount_amount_${row.id}'),
              controller: row.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => widget.onSubmit(),
              onChanged: (_) => _notifyRowsChanged(),
              decoration: InputDecoration(
                labelText: l10n.inventoryReceiptReviewDiscountAmountLabel,
              ),
            ),
          ),
          IconButton(
            key: Key('receipt_review_discount_remove_${row.id}'),
            onPressed: _rows.length > 1 ? () => _removeRow(index) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(_DiscountRowControllers.empty(id: _nextRowId));
      _nextRowId += 1;
    });
    _notifyRowsChanged();
  }

  void _removeRow(int index) {
    final removed = _rows.removeAt(index);
    removed.dispose();
    setState(() {});
    _notifyRowsChanged();
  }

  void _notifyRowsChanged() {
    widget.onChanged(
      _rows
          .map(
            (row) => MapEntry<String, String>(
              row.nameController.text,
              row.amountController.text,
            ),
          )
          .toList(growable: false),
    );
  }

  List<_DiscountRowControllers> _buildRows(
    List<MapEntry<String, String>> initialEntries,
  ) {
    if (initialEntries.isEmpty) {
      return <_DiscountRowControllers>[_DiscountRowControllers.empty(id: 0)];
    }
    return initialEntries.indexed
        .map(
          (indexedEntry) => _DiscountRowControllers(
            id: indexedEntry.$1,
            nameController: TextEditingController(text: indexedEntry.$2.key),
            amountController: TextEditingController(
              text: indexedEntry.$2.value,
            ),
          ),
        )
        .toList(growable: true);
  }
}

class _DiscountRowControllers {
  const _DiscountRowControllers({
    required this.id,
    required this.nameController,
    required this.amountController,
  });

  factory _DiscountRowControllers.empty({required int id}) {
    return _DiscountRowControllers(
      id: id,
      nameController: TextEditingController(),
      amountController: TextEditingController(),
    );
  }

  final int id;
  final TextEditingController nameController;
  final TextEditingController amountController;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
