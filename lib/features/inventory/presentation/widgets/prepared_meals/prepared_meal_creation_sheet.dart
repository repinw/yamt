import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_image_picker_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal creation sheet result.
class PreparedMealCreationSheetResult {
  /// The prepared meal creation sheet result.
  const PreparedMealCreationSheetResult({
    required this.name,
    required this.imageBytes,
    required this.totalPortions,
    required this.items,
  });

  /// The name.
  final String name;

  /// The image bytes.
  final Uint8List? imageBytes;

  /// The total portions.
  final int totalPortions;

  /// The items.
  final List<PreparedMealItemInput> items;
}

/// Show prepared meal creation sheet.
@Dependencies([preparedMealImagePicker])
Future<PreparedMealCreationSheetResult?> showPreparedMealCreationSheet({
  required BuildContext context,
  required List<InventoryItem> items,
}) {
  return showModalBottomSheet<PreparedMealCreationSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PreparedMealCreationSheet(items: items),
  );
}

/// Defines prepared meal creation sheet.
@Dependencies([preparedMealImagePicker])
class PreparedMealCreationSheet extends ConsumerStatefulWidget {
  /// The prepared meal creation sheet.
  const PreparedMealCreationSheet({required this.items, super.key});

  /// The items.
  final List<InventoryItem> items;

  @override
  ConsumerState<PreparedMealCreationSheet> createState() =>
      _PreparedMealCreationSheetState();
}

class _PreparedMealCreationSheetState
    extends ConsumerState<PreparedMealCreationSheet>
    with PreparedMealImagePickerStateMixin<PreparedMealCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _portionsController;
  late final List<_PreparedMealItemDraft> _drafts;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _buildSuggestedMealName(widget.items),
    );
    _portionsController = TextEditingController(text: '1');
    _drafts = widget.items
        .map((item) => _PreparedMealItemDraft(item: item))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionsController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PreparedMealSheetContainer(
      formKey: _formKey,
      children: [
        Text(
          l10n.preparedMealCreateTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        PreparedMealNameField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          onChanged: _onNameChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _portionsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.preparedMealPortionsLabel,
          ),
          validator: (value) {
            final portions = int.tryParse(value?.trim() ?? '');
            if (portions == null || portions < 1) {
              return l10n.preparedMealInvalidPortions;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealImagePickerField(
          label: _nameController.text,
          imageBytes: _imageBytes,
          supportsCamera: supportsPreparedMealCamera,
          isPickingImage: isPickingPreparedMealImage,
          onPickImage: _pickImage,
          onClearImage: _clearImage,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.preparedMealIngredientsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._drafts.map((draft) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _PreparedMealItemEditorCard(draft: draft),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        PreparedMealSheetActions(
          primaryLabel: l10n.preparedMealCreateAction,
          onPrimaryPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final formState = _formKey.currentState;
    if (formState == null) {
      _showSubmitError(l10n.preparedMealActionFailed);
      return;
    }
    if (!formState.validate()) {
      _showSubmitError(l10n.preparedMealFixFormErrorsMessage);
      return;
    }

    final portions = int.tryParse(_portionsController.text.trim());
    if (portions == null || portions < 1) {
      _showSubmitError(l10n.preparedMealInvalidPortions);
      return;
    }

    final inputs = <PreparedMealItemInput>[];
    for (final draft in _drafts) {
      final amount = int.tryParse(draft.amountController.text.trim());
      if (amount == null || amount < 1 || amount > draft.maxAmount) {
        _showSubmitError(l10n.preparedMealInvalidIngredientAmount);
        return;
      }

      GlobalFoodNutrition? manualNutrition;
      if (draft.requiresManualNutrition) {
        final per100Kcal = _parseDouble(draft.kcalController.text);
        final per100Protein = _parseDouble(draft.proteinController.text);
        final per100Carbs = _parseDouble(draft.carbsController.text);
        final per100Fat = _parseDouble(draft.fatController.text);
        if (per100Kcal == null ||
            per100Protein == null ||
            per100Carbs == null ||
            per100Fat == null) {
          _showSubmitError(l10n.caloriesNonNegativeNumberValidation);
          return;
        }
        manualNutrition = GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: per100Kcal,
          per100Protein: per100Protein,
          per100Carbs: per100Carbs,
          per100Fat: per100Fat,
        );
      }

      inputs.add(
        PreparedMealItemInput(
          itemId: draft.item.id,
          usedAmount: amount,
          manualNutrition: manualNutrition,
        ),
      );
    }

    Navigator.of(context).pop(
      PreparedMealCreationSheetResult(
        name: _nameController.text.trim(),
        imageBytes: _imageBytes == null
            ? null
            : Uint8List.fromList(_imageBytes!),
        totalPortions: portions,
        items: inputs,
      ),
    );
  }

  void _showSubmitError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  double? _parseDouble(String rawValue) {
    return double.tryParse(rawValue.trim().replaceAll(',', '.'));
  }

  Future<void> _pickImage(PreparedMealImageSource source) {
    return pickPreparedMealImage(
      source: source,
      onPicked: (imageBytes) {
        _imageBytes = imageBytes;
      },
    );
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
    });
  }

  void _onNameChanged(String _) {
    if (!mounted) {
      return;
    }
    setState(() {});
  }
}

class _PreparedMealItemEditorCard extends StatelessWidget {
  const _PreparedMealItemEditorCard({required this.draft});

  final _PreparedMealItemDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final hintText = draft.usesPieceNutrition
        ? l10n.preparedMealNutritionPerPieceHint
        : l10n.preparedMealNutritionPerHundredHint;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.item.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if ((draft.item.brand ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                draft.item.brand!.trim(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: draft.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.preparedMealUsedAmountLabel,
                helperText: l10n.preparedMealAvailableAmount(
                  draft.maxAmount,
                  draft.unitLabel(l10n),
                ),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1 || parsed > draft.maxAmount) {
                  return l10n.preparedMealInvalidIngredientAmount;
                }
                return null;
              },
            ),
            if (draft.requiresManualNutrition) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                hintText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: draft.kcalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100KcalLabel,
                ),
                validator: _manualNutritionValidator(l10n),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: draft.proteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100ProteinLabel,
                ),
                validator: _manualNutritionValidator(l10n),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: draft.carbsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100CarbsLabel,
                ),
                validator: _manualNutritionValidator(l10n),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: draft.fatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesPer100FatLabel,
                ),
                validator: _manualNutritionValidator(l10n),
              ),
            ],
          ],
        ),
      ),
    );
  }

  FormFieldValidator<String> _manualNutritionValidator(AppLocalizations l10n) {
    return (value) {
      final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
      if (parsed == null || parsed < 0) {
        return l10n.caloriesNonNegativeNumberValidation;
      }
      return null;
    };
  }
}

class _PreparedMealItemDraft {
  _PreparedMealItemDraft({required this.item})
    : amountController = TextEditingController(
        text: _defaultAmount(item).toString(),
      ),
      kcalController = TextEditingController(),
      proteinController = TextEditingController(),
      carbsController = TextEditingController(),
      fatController = TextEditingController();

  final InventoryItem item;
  final TextEditingController amountController;
  final TextEditingController kcalController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;

  int get maxAmount => _defaultAmount(item);

  bool get requiresManualNutrition => !_hasCompleteNutrition(item.nutrition);

  bool get usesPieceNutrition {
    if (!item.usesAmountProgress) {
      return true;
    }
    return item.amountUnit == InventoryAmountUnit.piece;
  }

  String unitLabel(AppLocalizations l10n) {
    if (!item.usesAmountProgress || item.amountUnit == null) {
      return l10n.inventoryUnitPiece;
    }
    return item.amountUnit!.localizedName(l10n);
  }

  void dispose() {
    amountController.dispose();
    kcalController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }
}

int _defaultAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount;
  }
  return item.quantity;
}

bool _hasCompleteNutrition(GlobalFoodNutrition? nutrition) {
  if (nutrition == null) {
    return false;
  }
  return nutrition.per100Kcal != null &&
      nutrition.per100Protein != null &&
      nutrition.per100Carbs != null &&
      nutrition.per100Fat != null;
}

String _buildSuggestedMealName(List<InventoryItem> items) {
  final names = items
      .map((item) => item.name.trim())
      .where((name) => name.isNotEmpty)
      .take(3)
      .toList(growable: false);
  return names.join(', ');
}
