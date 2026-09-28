import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_photo_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_photo_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The two package photos of the product editor, the front and the
/// nutrition table, and the barcode under them.
class ManualProductPhotoSection extends StatelessWidget {
  /// Creates the section.
  const new({
    required this.photoState,
    required this.barcode,
    required this.barcodeFocusNode,
    required this.barcodeOrigin,
    required this.hasNoBarcode,
    required this.onTakeFrontPhoto,
    required this.onTakeNutritionTablePhoto,
    required this.onBarcodeChanged,
    required this.onScanBarcode,
    required this.onNoBarcodeChanged,
    super.key,
  });

  /// Key of the front photo tile.
  static const frontKey = Key('manual_product_front_photo');

  /// Key of the nutrition table photo tile.
  static const nutritionTableKey = Key('manual_product_nutrition_table_photo');

  /// Key of the button that scans a barcode.
  static const scanBarcodeKey = Key(
    'receipt_review_manual_barcode_scan_button',
  );

  /// Key of the "has none" chip.
  static const noBarcodeKey = Key('receipt_review_manual_no_barcode_checkbox');

  /// The package photos.
  final ManualProductPhotoState photoState;

  /// Text of the barcode input.
  final TextEditingController barcode;

  /// Focus of the barcode input.
  final FocusNode barcodeFocusNode;

  /// Where a barcode from a photo came from.
  final ManualProductBarcodeOrigin? barcodeOrigin;

  /// Whether the product is marked as having no barcode.
  final bool hasNoBarcode;

  /// Takes a photo of the package front.
  final VoidCallback onTakeFrontPhoto;

  /// Takes a photo of the nutrition table.
  final VoidCallback onTakeNutritionTablePhoto;

  /// Called when the barcode is typed.
  final ValueChanged<String> onBarcodeChanged;

  /// Opens the barcode scanner.
  final VoidCallback onScanBarcode;

  /// Called when the "has none" mark changes.
  final ValueChanged<bool> onNoBarcodeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final photos = photoState;
    final caption = _barcodeCaption(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          l10n.productEditorPhotosHint,
          style: textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: ManualProductPhotoTile(
                key: frontKey,
                title: l10n.productEditorFrontPhoto,
                hint: l10n.productEditorFrontPhotoHint,
                photo: photos.front?.bytes,
                isReading: photos.isReadingFront,
                hasRead: photos.hasReadFront,
                readLabel: _frontReadLabel(l10n, photos.frontDetails),
                onPressed: photos.isReadingFront || photos.isSaving
                    ? null
                    : onTakeFrontPhoto,
              ),
            ),
            Expanded(
              child: ManualProductPhotoTile(
                key: nutritionTableKey,
                title: l10n.productEditorNutritionTablePhoto,
                hint: l10n.productEditorNutritionTablePhotoHint,
                photo: photos.nutritionTable?.bytes,
                isReading: photos.isReadingNutritionTable,
                hasRead: photos.hasReadNutritionTable,
                readLabel: l10n.productEditorPhotoReadValues(
                  photos.nutritionValueCount,
                ),
                onPressed: photos.isReadingNutritionTable || photos.isSaving
                    ? null
                    : onTakeNutritionTablePhoto,
              ),
            ),
          ],
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: TextField(
                key: ManualProductFormField.barcode.key,
                controller: barcode,
                focusNode: barcodeFocusNode,
                enabled: !hasNoBarcode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: colors.ink,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
                onChanged: onBarcodeChanged,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.inventoryManualAddMissingBarcodeLabel,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.rule),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.rule),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.ink,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                ),
              ),
            ),
            FilledButton.tonal(
              key: scanBarcodeKey,
              onPressed: hasNoBarcode ? null : onScanBarcode,
              child: Text(l10n.productEditorScanBarcode),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            EatChip(
              key: noBarcodeKey,
              label: l10n.productEditorNoBarcode,
              isSelected: hasNoBarcode,
              onPressed: () => onNoBarcodeChanged(!hasNoBarcode),
            ),
            if (caption != null)
              Text(
                caption.text,
                style: textTheme.bodySmall?.copyWith(
                  color: caption.isMissing ? colors.accentText : colors.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }

  ({String text, bool isMissing})? _barcodeCaption(AppLocalizations l10n) {
    if (hasNoBarcode) return null;
    return switch (barcodeOrigin) {
      ManualProductBarcodeOrigin.photo => (
        text: l10n.productEditorBarcodeFromPhoto,
        isMissing: false,
      ),
      ManualProductBarcodeOrigin.ai => (
        text: l10n.productEditorBarcodeFromAi,
        isMissing: false,
      ),
      null
          when barcode.text.trim().isEmpty &&
              photoState.hasPhoto &&
              !photoState.isBusy =>
        (text: l10n.productEditorBarcodeMissing, isMissing: true),
      null => null,
    };
  }
}

/// What the front photo filled in, such as "Name · 500 g".
String? _frontReadLabel(AppLocalizations l10n, ProductFrontDetails? details) {
  if (details == null) {
    return null;
  }
  final quantity = details.quantityLabel?.trim() ?? '';
  final parts = [
    if (details.name.trim().isNotEmpty) l10n.productEditorPhotoReadName,
    if (quantity.isNotEmpty) quantity,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
