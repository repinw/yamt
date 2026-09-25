import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the missing barcode prompt for manual inventory add.
Future<String?> showInventoryManualAddMissingBarcodeDialog({
  required BuildContext context,
}) {
  return showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      return const _ManualMissingBarcodeDialog();
    },
  );
}

class _ManualMissingBarcodeDialog extends StatefulWidget {
  const new();

  @override
  State<_ManualMissingBarcodeDialog> createState() {
    return _ManualMissingBarcodeDialogState();
  }
}

class _ManualMissingBarcodeDialogState
    extends State<_ManualMissingBarcodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.inventoryManualAddMissingBarcodeTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.inventoryManualAddMissingBarcodeMessage),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              key: const Key('inventory_manual_add_missing_barcode_field'),
              controller: _barcodeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryManualAddMissingBarcodeLabel,
              ),
              validator: _validateBarcode,
              onFieldSubmitted: (_) => _submitBarcode(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory_manual_add_missing_barcode_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        TextButton(
          key: const Key('inventory_manual_add_missing_barcode_skip_button'),
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(l10n.inventoryManualAddMissingBarcodeSaveWithout),
        ),
        FilledButton(
          key: const Key('inventory_manual_add_missing_barcode_save_button'),
          onPressed: _submitBarcode,
          child: Text(l10n.inventoryManualAddMissingBarcodeSave),
        ),
      ],
    );
  }

  String? _validateBarcode(String? value) {
    final barcode = normalizeBarcode(value ?? '');
    if (barcode.isEmpty) {
      return AppLocalizations.of(context)!
          .inventoryManualAddMissingBarcodeRequired;
    }
    return null;
  }

  void _submitBarcode() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    Navigator.of(context).pop(normalizeBarcode(_barcodeController.text));
  }
}
