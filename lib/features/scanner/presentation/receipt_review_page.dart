import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_review_controller.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_add_item_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_barcode_scanner.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_edit_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_bottom_bar.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_header.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_item_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Screen for reviewing and editing scanned receipt items before
/// inventory import.
class ReceiptReviewPage extends ConsumerStatefulWidget {
  /// Creates a [ReceiptReviewPage].
  const new({required this.initialReceipt, super.key});

  /// The initially parsed receipt.
  final ScannedReceipt initialReceipt;

  @override
  ConsumerState<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

class _ReceiptReviewPageState extends ConsumerState<ReceiptReviewPage> {
  ReceiptReviewController get _notifier =>
      ref.read(receiptReviewControllerProvider(widget.initialReceipt).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      receiptReviewControllerProvider(widget.initialReceipt),
    );

    ref.listen(receiptReviewControllerProvider(widget.initialReceipt), (
      prev,
      next,
    ) {
      if (next.saveSuccess) {
        Navigator.of(context).pop(true);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        _notifier.clearError();
      }
    });

    final receipt = state.receipt;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.receiptReviewTitle ?? 'Beleg prüfen'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                ReceiptReviewHeader(
                  receipt: receipt,
                  onEditStore: () => _editStoreName(receipt.storeName),
                  onEditDate: () => _editDate(receipt.dateTime),
                  onConfirmAllSuggestions: _notifier.confirmAllSuggestions,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...receipt.items.map(
                  (item) => ReceiptReviewItemCard(
                    item: item,
                    currencyCode: receipt.currency,
                    onTap: () => _openItemDetails(item),
                    onConfirmSuggestion: () => _notifier.updateItem(
                      item.copyWith(status: ReceiptItemStatus.confirmed),
                    ),
                    onToggleIgnore: () => _notifier.toggleIgnore(item.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton.icon(
                    key: const Key('add_item_button'),
                    icon: const Icon(Icons.add),
                    label: Text(
                      l10n?.receiptReviewAddItem ?? 'Position hinzufügen',
                    ),
                    onPressed: _addNewItem,
                  ),
                ),
              ],
            ),
          ),
          ReceiptReviewBottomBar(
            receipt: receipt,
            isSaving: state.isSaving,
            onSave: _notifier.saveReceipt,
          ),
        ],
      ),
    );
  }

  Future<void> _openItemDetails(ReceiptLineItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (bottomSheetContext) => ReceiptItemEditSheet(
        item: item,
        onUpdateQuantity: (q) {
          _notifier.updateQuantity(item.id, q);
          Navigator.of(bottomSheetContext).pop();
        },
        onUpdatePrice: (p) {
          _notifier.updatePrice(item.id, p);
          Navigator.of(bottomSheetContext).pop();
        },
        onSelectCandidate: (c) {
          _notifier.selectCandidate(item.id, c);
          Navigator.of(bottomSheetContext).pop();
        },
        onClearProduct: () {
          _notifier.clearProduct(item.id);
          Navigator.of(bottomSheetContext).pop();
        },
        onToggleIgnore: () {
          _notifier.toggleIgnore(item.id);
          Navigator.of(bottomSheetContext).pop();
        },
        onRemove: () {
          _notifier.removeItem(item.id);
          Navigator.of(bottomSheetContext).pop();
        },
        onScanBarcode: () => _scanBarcodeForItem(item, bottomSheetContext),
        onSearchProduct: () => _searchProductForItem(item, bottomSheetContext),
      ),
    );
  }

  Future<void> _scanBarcodeForItem(
    ReceiptLineItem item,
    BuildContext sheetContext,
  ) async {
    Navigator.of(sheetContext).pop();
    final barcode = await openReceiptBarcodeScanner(context);
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;

    final picker = ref.read(receiptManualProductPickerProvider);
    final candidate = await picker.pickOrEditProduct(
      context,
      initialQuery: barcode.trim(),
      barcode: barcode.trim(),
      rawName: item.rawName,
      storeName: ref
          .read(receiptReviewControllerProvider(widget.initialReceipt))
          .receipt
          .storeName,
      brand: item.rawBrand,
      weight: item.packageWeight,
    );
    if (!mounted || candidate == null) return;
    _notifier.selectCandidate(item.id, candidate);
  }

  Future<void> _searchProductForItem(
    ReceiptLineItem item, [
    BuildContext? sheetContext,
  ]) async {
    if (sheetContext != null) Navigator.of(sheetContext).pop();
    final picker = ref.read(receiptManualProductPickerProvider);
    final candidate = await picker.pickOrEditProduct(
      context,
      initialQuery: item.rawName,
      barcode: item.matchedProduct?.barcode,
      rawName: item.rawName,
      storeName: ref
          .read(receiptReviewControllerProvider(widget.initialReceipt))
          .receipt
          .storeName,
      brand: item.rawBrand,
      weight: item.packageWeight,
    );
    if (!mounted || candidate == null) return;
    _notifier.selectCandidate(item.id, candidate);
  }

  Future<void> _addNewItem() async {
    final newItem = await ReceiptAddItemDialog.show(context);
    if (mounted && newItem != null) _notifier.addItem(newItem);
  }

  Future<void> _editStoreName(String? currentName) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentName ?? '');
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.receiptReviewStoreEdit ?? 'Händler anpassen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n?.receiptReviewStoreLabel ?? 'Händlername',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n?.inventoryReceiptReviewCancelAction ?? 'Abbrechen',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(
                l10n?.inventoryReceiptReviewSaveAction ?? 'Speichern',
              ),
            ),
          ],
        ),
      );
      if (mounted && newName != null && newName.isNotEmpty) {
        _notifier.updateStoreName(newName);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editDate(DateTime? currentDate) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (mounted && pickedDate != null) _notifier.updateDateTime(pickedDate);
  }
}
