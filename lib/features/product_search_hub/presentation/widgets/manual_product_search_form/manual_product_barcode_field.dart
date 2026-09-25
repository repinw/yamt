import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_search_input.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Barcode field with a button that opens the barcode scanner.
class ManualProductBarcodeField extends StatelessWidget {
  /// Creates the barcode field.
  const new({
    required this.initialValue,
    required this.onChanged,
    required this.onScan,
    super.key,
  });

  /// Initial barcode text.
  final String initialValue;

  /// Called when the barcode text changes.
  final ValueChanged<String?> onChanged;

  /// Opens the barcode scanner.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormBuilderTextField(
      key: const Key('receipt_review_manual_barcode_field'),
      name: ManualProductSearchFormFieldName.barcode,
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: l10n.inventoryManualAddMissingBarcodeLabel,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          key: const Key('receipt_review_manual_barcode_scan_button'),
          tooltip: l10n.inventoryManualAddScanBarcodeAction,
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
      ),
    );
  }
}
