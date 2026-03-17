import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/provider/'
    'inventory_barcode_image_provider.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _newProductSelectionId = '__new_product__';
const _sheetBackground = Color(0xFFF3F4F6);
const _cardBorder = Color(0xFFE5E7EB);
const _mutedText = Color(0xFF64748B);
const _titleText = Color(0xFF0F172A);

BoxDecoration _receiptPanelDecoration(
  BuildContext context, {
  Color? backgroundColor,
}) {
  return BoxDecoration(
    color: backgroundColor ?? Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _cardBorder),
    boxShadow: const [
      BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 2)),
    ],
  );
}

class InventoryReceiptReviewSheet extends StatefulWidget {
  const InventoryReceiptReviewSheet({
    super.key,
    required this.items,
    required this.onCancelTap,
    required this.onSaveTap,
    this.receiptPreviewBytes,
  });

  final List<ReceiptReviewItemDraft> items;
  final VoidCallback onCancelTap;
  final Future<void> Function(List<ReceiptReviewItemDraft> items) onSaveTap;
  final Uint8List? receiptPreviewBytes;

  @override
  State<InventoryReceiptReviewSheet> createState() =>
      _InventoryReceiptReviewSheetState();
}

class _InventoryReceiptReviewSheetState
    extends State<InventoryReceiptReviewSheet> {
  static const _priceSummaryCalculator = ReceiptReviewPriceSummaryCalculator();
  static const _itemProcessor = ReceiptReviewItemProcessor();

  late final List<ReceiptReviewItemDraft> _items;
  late final ReceiptReviewMetadata _receiptMetadata;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final result = _itemProcessor.process(widget.items);
    _items = result.items;
    _receiptMetadata = result.metadata;
  }

  bool get _canSave {
    if (_isSaving) {
      return false;
    }
    return _items.any((item) => item.canBeSavedToInventory);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = _currencyFormat(context);
    final priceSummary = _priceSummaryCalculator.calculate(_items);

    return SafeArea(
      child: Material(
        color: _sheetBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReceiptReviewHeader(
                    isSaving: _isSaving,
                    canSave: _canSave,
                    onSaveTap: _saveReviewedItems,
                  ),
                  const SizedBox(height: 16),
                  _ReceiptPreviewButton(onTap: _openReceiptPreview),
                ],
              ),
            ),
            Container(height: 1, color: _cardBorder),
            Expanded(
              child: _buildContent(
                context: context,
                l10n: l10n,
                currency: currency,
                priceSummary: priceSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required NumberFormat currency,
    required ReceiptReviewPriceSummary priceSummary,
  }) {
    if (_items.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.inventoryReceiptReviewEmpty),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 32),
      children: [
        _ReceiptMetadataOverview(
          storeName: _receiptMetadata.storeName,
          receiptDate: _receiptMetadata.receiptDate,
          receiptTimeText: _receiptMetadata.receiptTimeText,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.inventoryReceiptReviewDetectedItems.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: _mutedText,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in _items.indexed) ...[
          _ReceiptItemCard(
            draft: entry.$2,
            index: entry.$1,
            currency: currency,
            onEditTap: _openItemEditor,
            onSwitchTap: _openCandidatePicker,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
        _PriceOverview(
          totalPrice: priceSummary.totalPrice,
          storablePrice: priceSummary.storablePrice,
          excludedPrice: priceSummary.excludedPrice,
          currency: currency,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _openItemEditor(int index) async {
    if (_items[index].item.isDiscount) {
      return;
    }

    final editedItem = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: _items[index].item);
      },
    );
    if (!mounted || editedItem == null) {
      return;
    }
    setState(() {
      _items[index] = _items[index].copyWith(item: editedItem);
    });
  }

  Future<void> _openCandidatePicker(int index) async {
    final draft = _items[index];
    if (!draft.canBeSavedToInventory || !draft.hasCandidates) {
      return;
    }

    final selection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CandidatePickerSheet(
          draft: draft,
          selectedValue:
              draft.selectedGlobalFoodItemId ?? _newProductSelectionId,
        );
      },
    );
    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _items[index] = selection == _newProductSelectionId
          ? _items[index].selectNewItem()
          : _items[index].selectCandidate(selection);
    });
  }

  Future<void> _openReceiptPreview() async {
    final l10n = AppLocalizations.of(context)!;
    final receiptPreviewBytes = widget.receiptPreviewBytes;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.inventoryReceiptReviewCancelAction,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      pageBuilder: (dialogContext, primaryAnimation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 420,
                          maxHeight:
                              MediaQuery.sizeOf(dialogContext).height * 0.72,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: AspectRatio(
                              aspectRatio: 1 / 1.9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    receiptPreviewBytes != null &&
                                        receiptPreviewBytes.isNotEmpty
                                    ? InteractiveViewer(
                                        child: Image.memory(
                                          receiptPreviewBytes,
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                        ),
                                      )
                                    : _ReceiptPreviewPlaceholder(
                                        title: l10n
                                            .inventoryReceiptReviewOriginalReceiptTitle,
                                        subtitle: l10n
                                            .inventoryReceiptReviewOriginalReceiptUnavailable,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReviewedItems() async {
    if (!_canSave) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    await widget.onSaveTap(List<ReceiptReviewItemDraft>.from(_items));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
  }

  NumberFormat _currencyFormat(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return NumberFormat.currency(locale: locale, symbol: '€');
  }
}

class _ReceiptReviewHeader extends StatelessWidget {
  const _ReceiptReviewHeader({
    required this.isSaving,
    required this.canSave,
    required this.onSaveTap,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.inventoryReceiptReviewTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _titleText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          key: const Key('receipt_review_save_button'),
          onPressed: canSave ? onSaveTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isSaving
              ? const SizedBox.square(
                  dimension: AppSpacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.inventoryReceiptReviewSaveAction),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReceiptPreviewButton extends StatelessWidget {
  const _ReceiptPreviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('receipt_review_preview_button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.inventoryReceiptReviewOriginalReceiptAction,
                    style: const TextStyle(
                      color: _mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: _mutedText, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviewPlaceholder extends StatelessWidget {
  const _ReceiptPreviewPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemCard extends StatelessWidget {
  const _ReceiptItemCard({
    required this.draft,
    required this.index,
    required this.currency,
    required this.onEditTap,
    required this.onSwitchTap,
  });

  final ReceiptReviewItemDraft draft;
  final int index;
  final NumberFormat currency;
  final ValueChanged<int> onEditTap;
  final ValueChanged<int> onSwitchTap;

  @override
  Widget build(BuildContext context) {
    final item = draft.item;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final muted = item.isReviewOnly;
    final visualState = _receiptItemVisualStateForDraft(draft);
    final display = _receiptDisplayDataForDraft(draft);
    final ocrHint = _receiptOcrHintForDraft(
      draft: draft,
      displayedName: display.name,
    );
    final titleStyle = muted
        ? textTheme.titleMedium?.copyWith(
            color: Theme.of(context).disabledColor,
          )
        : textTheme.titleMedium;
    final subtitleStyle = textTheme.bodySmall?.copyWith(
      color: muted ? Theme.of(context).disabledColor : Colors.grey[500],
      fontSize: 12,
    );
    final brand = display.brand?.trim();
    final hasBrand = brand != null && brand.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('receipt_review_edit_button_$index'),
        onTap: item.isDiscount ? null : () => onEditTap(index),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: _receiptPanelDecoration(
            context,
            backgroundColor: muted
                ? colors.surfaceContainerLow
                : colors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReceiptItemLeading(draft: draft, display: display),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  display.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _titleText,
                                  ),
                                ),
                                if (hasBrand) ...[
                                  const SizedBox(height: 2),
                                  Text(brand, style: subtitleStyle),
                                ],
                                if (ocrHint case final String value) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${l10n.inventoryReceiptReviewReadAsPrefix}: '
                                          '$value',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[400],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            currency.format(item.unitPrice),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _titleText,
                            ),
                          ),
                        ],
                      ),
                      if (display.nutrition?.hasAnyNutritionValue ?? false) ...[
                        const SizedBox(height: 10),
                        _NutritionChips(nutrition: display.nutrition!),
                      ],
                      _ReceiptItemDiscountRows(
                        item: item,
                        itemIndex: index,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _QuantityPill(label: '${item.quantity}x'),
                                if (muted)
                                  _StatusPill(
                                    label:
                                        l10n.inventoryReceiptReviewExcludedTag,
                                  ),
                              ],
                            ),
                          ),
                          if (_actionLabelForState(
                                context: context,
                                draft: draft,
                                visualState: visualState,
                              ) !=
                              null)
                            _ReceiptItemActionButton(
                              key: Key(
                                visualState ==
                                        _ReceiptItemVisualState.newProduct
                                    ? 'receipt_review_determine_button_$index'
                                    : 'receipt_review_switch_button_$index',
                              ),
                              visualState: visualState,
                              label: _actionLabelForState(
                                context: context,
                                draft: draft,
                                visualState: visualState,
                              )!,
                              onPressed: () {
                                if (visualState ==
                                    _ReceiptItemVisualState.newProduct) {
                                  onEditTap(index);
                                  return;
                                }
                                onSwitchTap(index);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptItemLeading extends StatelessWidget {
  const _ReceiptItemLeading({required this.draft, required this.display});

  final ReceiptReviewItemDraft draft;
  final _ReceiptDisplayData display;

  @override
  Widget build(BuildContext context) {
    final visualState = _receiptItemVisualStateForDraft(draft);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SelectionThumbnail(
          imageUrl: display.imageUrl,
          barcode: display.barcode,
          icon: Icons.inventory_2_outlined,
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.grey[400],
          dimension: 48,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs * 2),
              child: Icon(
                visualState.icon,
                size: 20,
                color: visualState.color(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ReceiptItemVisualState { matched, reviewNeeded, newProduct, excluded }

extension _ReceiptItemVisualStateX on _ReceiptItemVisualState {
  IconData get icon => switch (this) {
    _ReceiptItemVisualState.matched => Icons.check_circle,
    _ReceiptItemVisualState.reviewNeeded => Icons.error,
    _ReceiptItemVisualState.newProduct => Icons.error,
    _ReceiptItemVisualState.excluded => Icons.remove_circle_outline,
  };

  Color color(BuildContext context) {
    return switch (this) {
      _ReceiptItemVisualState.matched => Colors.green,
      _ReceiptItemVisualState.reviewNeeded => const Color(0xFFF59E0B),
      _ReceiptItemVisualState.newProduct => Colors.red,
      _ReceiptItemVisualState.excluded => Colors.grey,
    };
  }
}

_ReceiptItemVisualState _receiptItemVisualStateForDraft(
  ReceiptReviewItemDraft draft,
) {
  if (!draft.canBeSavedToInventory) {
    return _ReceiptItemVisualState.excluded;
  }
  if (!draft.hasCandidates) {
    return _ReceiptItemVisualState.newProduct;
  }
  if (draft.selectedCandidate == null) {
    return _ReceiptItemVisualState.reviewNeeded;
  }
  if (draft.selectionNeedsReview || draft.differsFromSelectedCandidate) {
    return _ReceiptItemVisualState.reviewNeeded;
  }
  return _ReceiptItemVisualState.matched;
}

class _ReceiptDisplayData {
  const _ReceiptDisplayData({
    required this.name,
    required this.brand,
    required this.barcode,
    required this.imageUrl,
    required this.nutrition,
  });

  final String name;
  final String? brand;
  final String? barcode;
  final String? imageUrl;
  final GlobalFoodNutrition? nutrition;
}

_ReceiptDisplayData _receiptDisplayDataForDraft(ReceiptReviewItemDraft draft) {
  final selectedCandidate = draft.selectedCandidate;
  if (selectedCandidate != null) {
    return _ReceiptDisplayData(
      name: selectedCandidate.item.name,
      brand: selectedCandidate.item.brand,
      barcode: selectedCandidate.item.normalizedBarcode,
      imageUrl: selectedCandidate.item.imageUrl,
      nutrition: selectedCandidate.item.nutrition,
    );
  }

  return _ReceiptDisplayData(
    name: draft.item.name,
    brand: draft.item.brand,
    barcode: draft.item.normalizedBarcode,
    imageUrl: draft.item.imageUrl,
    nutrition: draft.item.nutrition,
  );
}

String? _receiptOcrHintForDraft({
  required ReceiptReviewItemDraft draft,
  required String displayedName,
}) {
  final ocrName = draft.ocrName?.trim();
  if (ocrName == null || ocrName.isEmpty) {
    return null;
  }
  if (ocrName == displayedName.trim()) {
    return null;
  }
  return ocrName;
}

class _NutritionChips extends StatelessWidget {
  const _NutritionChips({required this.nutrition});

  final GlobalFoodNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (nutrition.per100Kcal != null)
        _NutritionChip(
          label: '${nutrition.per100Kcal!.round()} kcal',
          emphasized: true,
        ),
      if (nutrition.per100Carbs != null)
        _NutritionChip(label: 'KH ${_formatMacro(nutrition.per100Carbs!)}'),
      if (nutrition.per100Protein != null)
        _NutritionChip(
          label: 'Eiweiß ${_formatMacro(nutrition.per100Protein!)}',
        ),
      if (nutrition.per100Fat != null)
        _NutritionChip(label: 'Fett ${_formatMacro(nutrition.per100Fat!)}'),
      if (nutrition.per100Salt != null)
        _NutritionChip(label: 'Salz ${_formatMacro(nutrition.per100Salt!)}'),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }

  String _formatMacro(double value) {
    final rounded = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );
    return '$rounded g';
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background = emphasized ? Colors.green[50] : Colors.grey[100];
    final foreground = emphasized ? Colors.green[700] : Colors.grey[600];
    final borderColor = emphasized ? Colors.green[100]! : Colors.grey[200]!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: _mutedText,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

String? _actionLabelForState({
  required BuildContext context,
  required ReceiptReviewItemDraft draft,
  required _ReceiptItemVisualState visualState,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (!draft.canBeSavedToInventory) {
    return null;
  }
  if (visualState == _ReceiptItemVisualState.newProduct) {
    return l10n.inventoryReceiptReviewDetermineAction;
  }
  if (draft.hasCandidates && draft.candidates.length > 1) {
    return l10n.inventoryReceiptReviewSwitchAction;
  }
  return null;
}

class _ReceiptItemActionButton extends StatelessWidget {
  const _ReceiptItemActionButton({
    super.key,
    required this.visualState,
    required this.label,
    required this.onPressed,
  });

  final _ReceiptItemVisualState visualState;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDetermine = visualState == _ReceiptItemVisualState.newProduct;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDetermine ? const Color(0xFFEFF6FF) : Colors.white,
        foregroundColor: isDetermine ? Colors.blue[600] : _mutedText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isDetermine
              ? BorderSide.none
              : BorderSide(color: const Color(0xFFCBD5E1)),
        ),
      ),
      icon: Icon(isDetermine ? Icons.search : Icons.swap_horiz, size: 16),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReceiptItemDiscountRows extends StatelessWidget {
  const _ReceiptItemDiscountRows({
    required this.item,
    required this.itemIndex,
    required this.currency,
  });

  final InventoryItem item;
  final int itemIndex;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item.discounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final disabledColor = Theme.of(context).disabledColor;
    final discountTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: disabledColor);
    final entries = item.discounts.entries.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: entries.indexed
            .map((entryWithIndex) {
              final discountIndex = entryWithIndex.$1;
              final discount = entryWithIndex.$2;
              final discountName = discount.key.trim();
              final text = discountName.isEmpty
                  ? '${l10n.inventoryReceiptReviewFieldDiscounts} '
                        '(${currency.format(discount.value)})'
                  : '${l10n.inventoryReceiptReviewFieldDiscounts}: '
                        '$discountName (${currency.format(discount.value)})';
              return Padding(
                key: Key(
                  'receipt_review_discount_row_${itemIndex}_$discountIndex',
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: disabledColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(text, style: discountTextStyle)),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _CandidatePickerSheet extends StatelessWidget {
  const _CandidatePickerSheet({
    required this.draft,
    required this.selectedValue,
  });

  final ReceiptReviewItemDraft draft;
  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.inventoryReceiptReviewProductSelectionLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs * 2),
                      Text(
                        draft.ocrName?.trim().isNotEmpty ?? false
                            ? '${AppLocalizations.of(context)!.inventoryReceiptReviewReadAsPrefix}: '
                                  '"${draft.ocrName!.trim()}"'
                            : draft.item.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in draft.candidates) ...[
                    _CandidatePickerTile(
                      label: candidate.item.name,
                      subtitle: candidate.item.brand,
                      imageUrl: candidate.item.imageUrl,
                      barcode: candidate.item.normalizedBarcode,
                      isSelected: selectedValue == candidate.item.id,
                      icon: Icons.inventory_2_outlined,
                      nutrition: candidate.item.nutrition,
                      onTap: () {
                        Navigator.of(context).pop(candidate.item.id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop(_newProductSelectionId);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: selectedValue == _newProductSelectionId
                                ? Colors.blue[50]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedValue == _newProductSelectionId
                                  ? Colors.blue[400]!
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.inventoryReceiptReviewMissingProductAction,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.inventoryReceiptReviewMissingProductHint,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidatePickerTile extends StatelessWidget {
  const _CandidatePickerTile({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.barcode,
    this.nutrition,
  });

  final String label;
  final String? subtitle;
  final String? imageUrl;
  final String? barcode;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;
  final GlobalFoodNutrition? nutrition;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.blue[400]! : Colors.grey[200]!;
    final background = isSelected ? Colors.blue[50] : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectionThumbnail(
                imageUrl: imageUrl,
                barcode: barcode,
                icon: icon,
                dimension: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    if (subtitle case final String value
                        when value.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs * 2),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (nutrition?.hasAnyNutritionValue ?? false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _NutritionChips(nutrition: nutrition!),
                    ],
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionThumbnail extends ConsumerWidget {
  const _SelectionThumbnail({
    required this.imageUrl,
    this.barcode,
    this.icon = Icons.inventory_2_outlined,
    this.backgroundColor,
    this.foregroundColor,
    this.dimension = 28,
  });

  final String? imageUrl;
  final String? barcode;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double dimension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = _resolveImageUrl(ref);
    final hasImage =
        normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;
    final effectiveBackground =
        backgroundColor ?? colors.surfaceContainerHighest;
    final effectiveForeground = foregroundColor ?? colors.onSurfaceVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: dimension,
        child: hasImage
            ? Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: effectiveBackground,
                    child: Icon(
                      icon,
                      size: dimension * 0.5,
                      color: effectiveForeground,
                    ),
                  );
                },
              )
            : ColoredBox(
                color: effectiveBackground,
                child: Icon(
                  icon,
                  size: dimension * 0.5,
                  color: effectiveForeground,
                ),
              ),
      ),
    );
  }

  String? _resolveImageUrl(WidgetRef ref) {
    final directImageUrl = normalizeProductImageUrl(imageUrl);
    if (directImageUrl != null && directImageUrl.isNotEmpty) {
      return directImageUrl;
    }

    final normalizedBarcode = barcode?.trim();
    if (normalizedBarcode == null || normalizedBarcode.isEmpty) {
      return null;
    }

    final resolvedByBarcode = ref.watch(
      inventoryBarcodeImageUrlProvider(
        normalizedBarcode,
      ).select((asyncValue) => asyncValue.asData?.value),
    );
    return normalizeProductImageUrl(resolvedByBarcode);
  }
}

class _ReceiptMetadataOverview extends StatelessWidget {
  const _ReceiptMetadataOverview({
    required this.storeName,
    required this.receiptDate,
    required this.receiptTimeText,
  });

  final String storeName;
  final DateTime? receiptDate;
  final String? receiptTimeText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final receiptDateText = receiptDate == null
        ? l10n.inventoryReceiptReviewNoDate
        : DateFormat.yMd(locale).format(receiptDate!);
    final receiptMetaText = switch (receiptTimeText?.trim()) {
      final String time when time.isNotEmpty => '$receiptDateText • $time Uhr',
      _ => receiptDateText,
    };
    return DecoratedBox(
      decoration: _receiptPanelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.storefront, color: Colors.blue[600]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _titleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        receiptMetaText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceOverview extends StatelessWidget {
  const _PriceOverview({
    required this.totalPrice,
    required this.storablePrice,
    required this.excludedPrice,
    required this.currency,
  });

  final double totalPrice;
  final double storablePrice;
  final double excludedPrice;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const _DashedDivider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inventoryReceiptReviewPriceTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _titleText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.inventoryReceiptReviewPriceTotal,
                  style: const TextStyle(color: _mutedText, fontSize: 13),
                ),
              ],
            ),
            Text(
              currency.format(totalPrice),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _titleText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PriceRow(
          label: l10n.inventoryReceiptReviewPriceSavable,
          value: currency.format(storablePrice),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PriceRow(
          label: l10n.inventoryReceiptReviewPriceExcluded,
          value: currency.format(excludedPrice),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: style),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Row(
          children: List<Widget>.generate(
            dashCount,
            (_) => Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(right: 4),
                color: const Color(0xFFCBDCFB),
              ),
            ),
          ),
        );
      },
    );
  }
}
