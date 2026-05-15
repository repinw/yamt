// Extracted internal widget bucket for manual product search form state sync.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as manual_product_models;
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_action_selector.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_optional_nutrition.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_recent_items.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_input.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_results.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ManualProductDetailsForm extends StatefulWidget {
  const ManualProductDetailsForm({
    required this.searchResults,
    required this.recentItems,
    required this.showDetails,
    required this.preview,
    required this.nameText,
    required this.brandText,
    required this.weightAmount,
    required this.selectedWeightUnit,
    required this.kcalText,
    required this.saturatedFatText,
    required this.polyunsaturatedFatText,
    required this.showPolyunsaturatedFatField,
    required this.fatText,
    required this.carbsText,
    required this.sugarText,
    required this.fiberText,
    required this.showFiberField,
    required this.proteinText,
    required this.saltText,
    required this.canAddOptionalNutrition,
    required this.isAddingOptionalNutrition,
    required this.optionalNutritionValueText,
    required this.optionalNutritionUnit,
    required this.optionalNutritionType,
    required this.availableOptionalNutritionTypes,
    required this.errorText,
    required this.showActionSelector,
    required this.selectedAction,
    required this.canSave,
    required this.isRunningNutritionOcr,
    required this.onSearchResultSelected,
    required this.onSearchResultStoreSelected,
    required this.onSearchResultEatSelected,
    required this.onRecentItemSelected,
    required this.onNameChanged,
    required this.onBrandChanged,
    required this.onWeightAmountChanged,
    required this.onWeightUnitChanged,
    required this.onScanNutritionLabel,
    required this.onKcalChanged,
    required this.onFatChanged,
    required this.onSaturatedFatChanged,
    required this.onCarbsChanged,
    required this.onSugarChanged,
    required this.onProteinChanged,
    required this.onSaltChanged,
    required this.onPolyunsaturatedFatChanged,
    required this.onFiberChanged,
    required this.onStartAddingOptionalNutrition,
    required this.onOptionalNutritionValueChanged,
    required this.onOptionalNutritionUnitChanged,
    required this.onOptionalNutritionTypeChanged,
    required this.onApplyOptionalNutrition,
    required this.onCancelOptionalNutrition,
    required this.onCancel,
    required this.onSave,
    super.key,
    this.onActionChanged,
  });

  final List<OffProductSearchResult> searchResults;
  final List<InventoryItem> recentItems;
  final bool showDetails;
  final InventoryReceiptManualProductPreviewData? preview;
  final String nameText;
  final String brandText;
  final String weightAmount;
  final InventoryAmountUnit selectedWeightUnit;
  final String kcalText;
  final String saturatedFatText;
  final String polyunsaturatedFatText;
  final bool showPolyunsaturatedFatField;
  final String fatText;
  final String carbsText;
  final String sugarText;
  final String fiberText;
  final bool showFiberField;
  final String proteinText;
  final String saltText;
  final bool canAddOptionalNutrition;
  final bool isAddingOptionalNutrition;
  final String optionalNutritionValueText;
  final InventoryAmountUnit optionalNutritionUnit;
  final manual_product_models.InventoryReceiptOptionalNutritionType?
  optionalNutritionType;
  final List<manual_product_models.InventoryReceiptOptionalNutritionType>
  availableOptionalNutritionTypes;
  final String? errorText;
  final bool showActionSelector;
  final manual_product_models.InventoryReceiptManualProductAction
  selectedAction;
  final bool canSave;
  final bool isRunningNutritionOcr;
  final ValueChanged<OffProductSearchResult> onSearchResultSelected;
  final ValueChanged<OffProductSearchResult>? onSearchResultStoreSelected;
  final ValueChanged<OffProductSearchResult>? onSearchResultEatSelected;
  final ValueChanged<InventoryItem> onRecentItemSelected;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onWeightAmountChanged;
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;
  final VoidCallback? onScanNutritionLabel;
  final ValueChanged<String> onKcalChanged;
  final ValueChanged<String> onFatChanged;
  final ValueChanged<String> onSaturatedFatChanged;
  final ValueChanged<String> onCarbsChanged;
  final ValueChanged<String> onSugarChanged;
  final ValueChanged<String> onProteinChanged;
  final ValueChanged<String> onSaltChanged;
  final ValueChanged<String> onPolyunsaturatedFatChanged;
  final ValueChanged<String> onFiberChanged;
  final VoidCallback onStartAddingOptionalNutrition;
  final ValueChanged<String> onOptionalNutritionValueChanged;
  final ValueChanged<InventoryAmountUnit> onOptionalNutritionUnitChanged;
  final ValueChanged<
    manual_product_models.InventoryReceiptOptionalNutritionType
  >
  onOptionalNutritionTypeChanged;
  final VoidCallback onApplyOptionalNutrition;
  final VoidCallback onCancelOptionalNutrition;
  final ValueChanged<manual_product_models.InventoryReceiptManualProductAction>?
  onActionChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<ManualProductDetailsForm> createState() {
    return _ManualProductDetailsFormState();
  }
}

class _ManualProductDetailsFormState extends State<ManualProductDetailsForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey _nutritionOcrButtonAnchorKey = GlobalKey();
  bool _isPatchingFormValues = false;

  @override
  void didUpdateWidget(covariant ManualProductDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _patchChangedFormValues(oldWidget);
    _scrollNutritionOcrButtonIntoViewIfNeeded(oldWidget);
  }

  void _patchChangedFormValues(ManualProductDetailsForm oldWidget) {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }

    final previousValues = _formValuesFor(oldWidget);
    final nextValues = _formValuesFor(widget);
    final changedValues = <String, dynamic>{};
    for (final entry in nextValues.entries) {
      if (previousValues[entry.key] == entry.value) {
        continue;
      }
      if (!formState.fields.containsKey(entry.key)) {
        continue;
      }
      changedValues[entry.key] = entry.value;
    }
    if (changedValues.isEmpty) {
      return;
    }

    _isPatchingFormValues = true;
    formState.patchValue(changedValues);
    _isPatchingFormValues = false;
  }

  void _scrollNutritionOcrButtonIntoViewIfNeeded(
    ManualProductDetailsForm oldWidget,
  ) {
    final didShowDetails = !oldWidget.showDetails && widget.showDetails;
    final didEnableNutritionScan =
        oldWidget.onScanNutritionLabel == null &&
        widget.onScanNutritionLabel != null;
    if (!widget.showDetails || (!didShowDetails && !didEnableNutritionScan)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final context = _nutritionOcrButtonAnchorKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: 0.24,
        ),
      );
    });
  }

  // TODO(wladik): Keep this map in sync with the registered form fields.
  Map<String, dynamic> _formValuesFor(ManualProductDetailsForm form) {
    return <String, dynamic>{
      ManualProductSearchFormFieldName.name: form.nameText,
      ManualProductSearchFormFieldName.brand: form.brandText,
      ManualProductSearchFormFieldName.weightAmount: form.weightAmount,
      ManualProductSearchFormFieldName.weightUnit: form.selectedWeightUnit,
      ManualProductSearchFormFieldName.kcal: form.kcalText,
      ManualProductSearchFormFieldName.fat: form.fatText,
      ManualProductSearchFormFieldName.saturatedFat: form.saturatedFatText,
      ManualProductSearchFormFieldName.carbs: form.carbsText,
      ManualProductSearchFormFieldName.sugar: form.sugarText,
      ManualProductSearchFormFieldName.protein: form.proteinText,
      ManualProductSearchFormFieldName.salt: form.saltText,
      ManualProductSearchFormFieldName.polyunsaturatedFat:
          form.polyunsaturatedFatText,
      ManualProductSearchFormFieldName.fiber: form.fiberText,
      ManualProductSearchFormFieldName.optionalNutritionValue:
          form.optionalNutritionValueText,
      ManualProductSearchFormFieldName.optionalNutritionUnit:
          form.optionalNutritionUnit,
      ManualProductSearchFormFieldName.optionalNutritionType:
          form.optionalNutritionType,
    };
  }

  void _onTextChanged(String? value, ValueChanged<String> onChanged) {
    if (_isPatchingFormValues) {
      return;
    }
    onChanged(value ?? '');
  }

  void _onUnitChanged(
    InventoryAmountUnit? value,
    ValueChanged<InventoryAmountUnit> onChanged,
  ) {
    if (_isPatchingFormValues || value == null) {
      return;
    }
    onChanged(value);
  }

  void _onOptionalNutritionTypeChanged(
    manual_product_models.InventoryReceiptOptionalNutritionType? value,
  ) {
    if (_isPatchingFormValues || value == null) {
      return;
    }
    widget.onOptionalNutritionTypeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.searchResults.isNotEmpty)
            ManualProductSearchResults(
              results: widget.searchResults,
              onSelect: widget.onSearchResultSelected,
              onStoreSelect: widget.onSearchResultStoreSelected,
              onEatSelect: widget.onSearchResultEatSelected,
            )
          else
            ManualProductRecentItems(
              items: widget.recentItems,
              onSelect: widget.onRecentItemSelected,
            ),
          if (widget.showDetails && widget.preview != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ManualProductPreview(preview: widget.preview!),
          ],
          if (widget.showDetails) ...[
            const SizedBox(height: AppSpacing.lg),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.name,
              initialValue: widget.nameText,
              label: l10n.inventoryReceiptReviewFieldName,
              fieldKey: const Key('receipt_review_manual_name_field'),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                _onTextChanged(value, widget.onNameChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.brand,
              initialValue: widget.brandText,
              label: l10n.inventoryReceiptReviewFieldBrand,
              fieldKey: const Key('receipt_review_manual_brand_field'),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                _onTextChanged(value, widget.onBrandChanged);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            ManualProductWeightFields(
              amountValue: widget.weightAmount,
              selectedUnit: widget.selectedWeightUnit,
              onAmountChanged: (value) {
                _onTextChanged(value, widget.onWeightAmountChanged);
              },
              onUnitChanged: (value) {
                _onUnitChanged(value, widget.onWeightUnitChanged);
              },
              amountFieldKey: const Key('receipt_review_manual_weight_field'),
              unitFieldKey: const Key(
                'receipt_review_manual_weight_unit_field',
              ),
              amountLabel: l10n.inventoryManualAddPackageSizeLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              key: _nutritionOcrButtonAnchorKey,
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('receipt_review_manual_nutrition_ocr_button'),
                onPressed: widget.onScanNutritionLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l10n.caloriesBarcodeNotFoundOcrAction),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.kcal,
              initialValue: widget.kcalText,
              label: l10n.caloriesPer100KcalLabel,
              fieldKey: const Key('receipt_review_manual_kcal_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onKcalChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.fat,
              initialValue: widget.fatText,
              label: l10n.caloriesPer100FatLabel,
              fieldKey: const Key('receipt_review_manual_fat_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onFatChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.saturatedFat,
              initialValue: widget.saturatedFatText,
              label: l10n.caloriesPer100SaturatedFatLabel,
              fieldKey: const Key(
                'receipt_review_manual_saturated_fat_field',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onSaturatedFatChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.carbs,
              initialValue: widget.carbsText,
              label: l10n.caloriesPer100CarbsLabel,
              fieldKey: const Key('receipt_review_manual_carbs_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onCarbsChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.sugar,
              initialValue: widget.sugarText,
              label: l10n.caloriesPer100SugarLabel,
              fieldKey: const Key('receipt_review_manual_sugar_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onSugarChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.protein,
              initialValue: widget.proteinText,
              label: l10n.caloriesPer100ProteinLabel,
              fieldKey: const Key('receipt_review_manual_protein_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onProteinChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ManualProductTextField(
              name: ManualProductSearchFormFieldName.salt,
              initialValue: widget.saltText,
              label: l10n.caloriesPer100SaltLabel,
              fieldKey: const Key('receipt_review_manual_salt_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: manualProductNumericInputFormatters,
              onChanged: (value) {
                _onTextChanged(value, widget.onSaltChanged);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.showPolyunsaturatedFatField) ...[
              ManualProductTextField(
                name: ManualProductSearchFormFieldName.polyunsaturatedFat,
                initialValue: widget.polyunsaturatedFatText,
                label: l10n.caloriesPer100PolyunsaturatedFatLabel,
                fieldKey: const Key(
                  'receipt_review_manual_polyunsaturated_fat_field',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: manualProductNumericInputFormatters,
                onChanged: (value) {
                  _onTextChanged(value, widget.onPolyunsaturatedFatChanged);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.showFiberField) ...[
              ManualProductTextField(
                name: ManualProductSearchFormFieldName.fiber,
                initialValue: widget.fiberText,
                label: l10n.caloriesPer100FiberLabel,
                fieldKey: const Key('receipt_review_manual_fiber_field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: manualProductNumericInputFormatters,
                onChanged: (value) {
                  _onTextChanged(value, widget.onFiberChanged);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.canAddOptionalNutrition ||
                widget.isAddingOptionalNutrition) ...[
              if (widget.isAddingOptionalNutrition)
                OptionalNutritionComposer(
                  valueText: widget.optionalNutritionValueText,
                  selectedUnit: widget.optionalNutritionUnit,
                  selectedType: widget.optionalNutritionType,
                  availableTypes: widget.availableOptionalNutritionTypes,
                  onValueChanged: (value) {
                    _onTextChanged(
                      value,
                      widget.onOptionalNutritionValueChanged,
                    );
                  },
                  onUnitChanged: (value) {
                    _onUnitChanged(
                      value,
                      widget.onOptionalNutritionUnitChanged,
                    );
                  },
                  onTypeChanged: _onOptionalNutritionTypeChanged,
                  onApply: widget.onApplyOptionalNutrition,
                  onCancel: widget.onCancelOptionalNutrition,
                )
              else
                OptionalNutritionAddRow(
                  label: l10n.inventoryReceiptReviewManualAddNutritionAction,
                  onPressed: widget.onStartAddingOptionalNutrition,
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.showActionSelector) ...[
              ManualProductActionSelector(
                selectedAction: widget.selectedAction,
                onChanged: widget.onActionChanged,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.errorText case final String message) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_manual_save_button'),
                    onPressed: widget.isRunningNutritionOcr || !widget.canSave
                        ? null
                        : widget.onSave,
                    child: Text(
                      l10n.inventoryReceiptReviewManualDataSaveAction,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
