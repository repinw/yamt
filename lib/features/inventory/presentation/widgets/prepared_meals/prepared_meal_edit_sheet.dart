import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_image_picker_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal edit sheet result.
class PreparedMealEditSheetResult {
  /// The prepared meal edit sheet result.
  const PreparedMealEditSheetResult({
    required this.name,
    required this.imageChanged,
    required this.imageBytes,
    required this.totalPortions,
    required this.items,
    this.requestIngredientSelection = false,
  });

  /// The name.
  final String name;

  /// The image changed.
  final bool imageChanged;

  /// The image bytes.
  final Uint8List? imageBytes;

  /// The total portions.
  final int totalPortions;

  /// The edited ingredient inputs.
  final List<PreparedMealItemInput> items;

  /// Whether user wants to select more ingredients from inventory.
  final bool requestIngredientSelection;

  /// Copy with.
  PreparedMealEditSheetResult copyWith({
    String? name,
    bool? imageChanged,
    Uint8List? imageBytes,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
    bool? requestIngredientSelection,
  }) {
    return PreparedMealEditSheetResult(
      name: name ?? this.name,
      imageChanged: imageChanged ?? this.imageChanged,
      imageBytes: imageBytes ?? this.imageBytes,
      totalPortions: totalPortions ?? this.totalPortions,
      items: items ?? this.items,
      requestIngredientSelection:
          requestIngredientSelection ?? this.requestIngredientSelection,
    );
  }
}

/// Show prepared meal edit sheet.
@Dependencies([preparedMealImagePicker])
Future<PreparedMealEditSheetResult?> showPreparedMealEditSheet({
  required BuildContext context,
  required PreparedMeal meal,
  required List<InventoryItem> inventoryItems,
  PreparedMealEditSheetResult? initialValue,
}) {
  return showModalBottomSheet<PreparedMealEditSheetResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PreparedMealEditSheet(
      meal: meal,
      inventoryItems: inventoryItems,
      initialValue: initialValue,
    ),
  );
}

/// Defines prepared meal edit sheet.
@Dependencies([preparedMealImagePicker])
class PreparedMealEditSheet extends ConsumerStatefulWidget {
  /// The prepared meal edit sheet.
  const PreparedMealEditSheet({
    required this.meal,
    required this.inventoryItems,
    super.key,
    this.initialValue,
  });

  /// The meal.
  final PreparedMeal meal;

  /// Inventory items available for adding to the meal.
  final List<InventoryItem> inventoryItems;

  /// Initial sheet value when resuming after inventory selection.
  final PreparedMealEditSheetResult? initialValue;

  @override
  ConsumerState<PreparedMealEditSheet> createState() =>
      _PreparedMealEditSheetState();
}

class _PreparedMealEditSheetState extends ConsumerState<PreparedMealEditSheet>
    with PreparedMealImagePickerStateMixin<PreparedMealEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _portionsController;
  late final List<_PreparedMealEditItemDraft> _drafts;
  Uint8List? _imageBytes;
  var _imageChanged = false;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    _nameController = TextEditingController(
      text: initialValue?.name ?? widget.meal.name,
    );
    _portionsController = TextEditingController(
      text: (initialValue?.totalPortions ?? widget.meal.totalPortions)
          .toString(),
    );
    _imageChanged = initialValue?.imageChanged ?? false;
    _imageBytes = initialValue?.imageBytes;
    _drafts = _buildInitialDrafts(initialValue);
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
    final imageRef = maybeLocalImageAssetRef(widget.meal.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final previewImageBytes = _imageChanged ? _imageBytes : storedImageBytes;
    final isContentEditingLocked = _isContentEditingLocked;

    return PreparedMealSheetContainer(
      formKey: _formKey,
      children: [
        Text(
          l10n.preparedMealEditTitle,
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
          enabled: !isContentEditingLocked,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.preparedMealPortionsLabel,
          ),
          validator: (value) => _validatePortions(value, l10n),
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealImagePickerField(
          label: _nameController.text,
          imageBytes: previewImageBytes,
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
        if (_drafts.isEmpty) _PreparedMealNoIngredientsMessage(l10n: l10n),
        ..._drafts.map(
          (draft) => _buildDraftCard(
            draft,
            enabled: !isContentEditingLocked,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isContentEditingLocked
                ? null
                : _requestIngredientSelection,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.preparedMealAddIngredientAction),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealSheetActions(
          primaryLabel: l10n.inventoryReceiptReviewSaveAction,
          onPrimaryPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildDraftCard(
    _PreparedMealEditItemDraft draft, {
    required bool enabled,
  }) {
    return Padding(
      key: ValueKey(draft.itemId),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: _PreparedMealEditItemEditorCard(
          draft: draft,
          enabled: enabled,
          onRemove: enabled ? () => _removeDraft(draft) : null,
        ),
      ),
    );
  }

  List<_PreparedMealEditItemDraft> _buildInitialDrafts(
    PreparedMealEditSheetResult? initialValue,
  ) {
    final inputs = initialValue?.items;
    if (inputs == null) {
      return widget.meal.components
          .map((component) {
            return _PreparedMealEditItemDraft.existing(
              component: component,
              usedAmount: component.usedAmount,
              maxAmount: _maxAmountForComponent(component),
            );
          })
          .toList(growable: true);
    }

    return inputs
        .map(_draftFromInput)
        .whereType<_PreparedMealEditItemDraft>()
        .toList(growable: true);
  }

  _PreparedMealEditItemDraft? _draftFromInput(PreparedMealItemInput input) {
    final component = _findComponent(widget.meal.components, input.itemId);
    if (component != null) {
      return _PreparedMealEditItemDraft.existing(
        component: component,
        usedAmount: input.usedAmount,
        maxAmount: _maxAmountForComponent(component),
      );
    }
    final item = _findInventoryItem(widget.inventoryItems, input.itemId);
    if (item == null) {
      return null;
    }
    return _PreparedMealEditItemDraft.inventory(
      item: item,
      usedAmount: input.usedAmount,
      maxAmount: _maxAmountForNewItem(item),
      manualNutrition: input.manualNutrition,
    );
  }

  Future<void> _pickImage(PreparedMealImageSource source) {
    return pickPreparedMealImage(
      source: source,
      onPicked: (imageBytes) {
        _imageBytes = imageBytes;
        _imageChanged = true;
      },
    );
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageChanged = true;
    });
  }

  void _removeDraft(_PreparedMealEditItemDraft draft) {
    if (_isContentEditingLocked) {
      return;
    }
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  void _requestIngredientSelection() {
    if (_isContentEditingLocked) {
      return;
    }
    final request = _buildResult(
      requestIngredientSelection: true,
      allowEmptyIngredients: true,
    );
    if (request == null) {
      return;
    }
    Navigator.of(context).pop(request);
  }

  void _submit() {
    final result = _buildResult(
      requestIngredientSelection: false,
      allowEmptyIngredients: false,
    );
    if (result == null) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  PreparedMealEditSheetResult? _buildResult({
    required bool requestIngredientSelection,
    required bool allowEmptyIngredients,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      _showSubmitError(l10n.preparedMealFixFormErrorsMessage);
      return null;
    }
    final portions = int.tryParse(_portionsController.text.trim());
    if (portions == null) {
      return null;
    }

    final canSaveEmptyIngredients = _canSaveWithoutIngredientDrafts(portions);
    if (!allowEmptyIngredients && _drafts.isEmpty && !canSaveEmptyIngredients) {
      _showSubmitError(l10n.preparedMealEmptyIngredientsMessage);
      return null;
    }

    final inputs = _buildInputs(l10n);
    if (inputs == null) {
      return null;
    }

    return PreparedMealEditSheetResult(
      name: _nameController.text.trim(),
      imageChanged: _imageChanged,
      imageBytes: _imageBytes == null ? null : Uint8List.fromList(_imageBytes!),
      totalPortions: portions,
      items: inputs,
      requestIngredientSelection: requestIngredientSelection,
    );
  }

  List<PreparedMealItemInput>? _buildInputs(AppLocalizations l10n) {
    final inputs = <PreparedMealItemInput>[];
    for (final draft in _drafts) {
      final amount = int.tryParse(draft.amountController.text.trim());
      if (amount == null || amount < 1) {
        _showSubmitError(l10n.preparedMealInvalidIngredientAmount);
        return null;
      }
      final manualNutrition = _manualNutritionForDraft(draft, l10n);
      if (draft.requiresManualNutrition && manualNutrition == null) {
        return null;
      }
      inputs.add(
        PreparedMealItemInput(
          itemId: draft.itemId,
          usedAmount: amount,
          manualNutrition: manualNutrition,
        ),
      );
    }
    return inputs;
  }

  bool _canSaveWithoutIngredientDrafts(int portions) {
    return widget.meal.components.isEmpty &&
        widget.meal.pendingRecipeIngredients.isNotEmpty &&
        portions == widget.meal.totalPortions;
  }

  GlobalFoodNutrition? _manualNutritionForDraft(
    _PreparedMealEditItemDraft draft,
    AppLocalizations l10n,
  ) {
    if (!draft.requiresManualNutrition) {
      return null;
    }

    final per100Kcal = _parseDouble(draft.kcalController.text);
    final per100Protein = _parseDouble(draft.proteinController.text);
    final per100Carbs = _parseDouble(draft.carbsController.text);
    final per100Fat = _parseDouble(draft.fatController.text);
    if (per100Kcal == null ||
        per100Protein == null ||
        per100Carbs == null ||
        per100Fat == null) {
      _showSubmitError(l10n.caloriesNonNegativeNumberValidation);
      return null;
    }
    return GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
    );
  }

  String? _validatePortions(String? value, AppLocalizations l10n) {
    final portions = int.tryParse(value?.trim() ?? '');
    if (portions == null || portions < 1) {
      return l10n.preparedMealInvalidPortions;
    }
    if (portions < _consumedPortions) {
      return l10n.preparedMealInvalidPortionsRange;
    }
    return null;
  }

  void _showSubmitError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  double? _parseDouble(String rawValue) {
    return double.tryParse(rawValue.trim().replaceAll(',', '.'));
  }

  void _onNameChanged(String _) {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  num get _consumedPortions {
    final consumed = widget.meal.totalPortions - widget.meal.remainingPortions;
    return consumed < 0 ? 0 : consumed;
  }

  bool get _isContentEditingLocked => _consumedPortions > 0;

  int? _maxAmountForComponent(PreparedMealComponent component) {
    if (widget.meal.remainingPortions <= 0) {
      return null;
    }
    final available = _availableAmountForItem(component.inventoryItemId);
    final restorable = remainingPreparedMealShareAmount(
      usedAmount: component.usedAmount,
      totalPortions: widget.meal.totalPortions,
      remainingPortions: widget.meal.remainingPortions,
    );
    final maxAmount =
        ((available + restorable) * widget.meal.totalPortions) ~/
        widget.meal.remainingPortions;
    return _maxInt(maxAmount, component.usedAmount);
  }

  int? _maxAmountForNewItem(InventoryItem item) {
    if (widget.meal.remainingPortions <= 0) {
      return null;
    }
    return (_defaultAmount(item) * widget.meal.totalPortions) ~/
        widget.meal.remainingPortions;
  }

  int _availableAmountForItem(String itemId) {
    final item = _findInventoryItem(widget.inventoryItems, itemId);
    return item == null ? 0 : _defaultAmount(item);
  }
}

class _PreparedMealEditItemEditorCard extends StatelessWidget {
  const _PreparedMealEditItemEditorCard({
    required this.draft,
    required this.enabled,
    required this.onRemove,
  });

  final _PreparedMealEditItemDraft draft;
  final bool enabled;
  final VoidCallback? onRemove;

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
          color: AppEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreparedMealEditItemHeader(draft: draft, onRemove: onRemove),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: draft.amountController,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.preparedMealUsedAmountLabel,
                helperText: draft.availableLabel(l10n),
              ),
              validator: (value) => _validateAmount(value, l10n),
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
              _ManualNutritionField(
                controller: draft.kcalController,
                label: l10n.caloriesPer100KcalLabel,
                enabled: enabled,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ManualNutritionField(
                controller: draft.proteinController,
                label: l10n.caloriesPer100ProteinLabel,
                enabled: enabled,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ManualNutritionField(
                controller: draft.carbsController,
                label: l10n.caloriesPer100CarbsLabel,
                enabled: enabled,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ManualNutritionField(
                controller: draft.fatController,
                label: l10n.caloriesPer100FatLabel,
                enabled: enabled,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateAmount(String? value, AppLocalizations l10n) {
    final parsed = int.tryParse(value?.trim() ?? '');
    final maxAmount = draft.maxAmount;
    if (parsed == null ||
        parsed < 1 ||
        (maxAmount != null && parsed > maxAmount)) {
      return l10n.preparedMealInvalidIngredientAmount;
    }
    return null;
  }
}

class _PreparedMealEditItemHeader extends StatelessWidget {
  const _PreparedMealEditItemHeader({
    required this.draft,
    required this.onRemove,
  });

  final _PreparedMealEditItemDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((draft.brand ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  draft.brand!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: l10n.preparedMealRemoveIngredientAction,
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _ManualNutritionField extends StatelessWidget {
  const _ManualNutritionField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(
          (value ?? '').trim().replaceAll(',', '.'),
        );
        if (parsed == null || parsed < 0) {
          return l10n.caloriesNonNegativeNumberValidation;
        }
        return null;
      },
    );
  }
}

class _PreparedMealNoIngredientsMessage extends StatelessWidget {
  const _PreparedMealNoIngredientsMessage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        l10n.preparedMealEmptyIngredientsMessage,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _PreparedMealEditItemDraft {
  _PreparedMealEditItemDraft.existing({
    required PreparedMealComponent component,
    required int usedAmount,
    required this.maxAmount,
  }) : itemId = component.inventoryItemId,
       name = component.name,
       brand = component.brand,
       unit = component.usedUnit,
       inventoryItem = null,
       amountController = TextEditingController(
         text: usedAmount.toString(),
       ),
       kcalController = TextEditingController(),
       proteinController = TextEditingController(),
       carbsController = TextEditingController(),
       fatController = TextEditingController();

  _PreparedMealEditItemDraft.inventory({
    required InventoryItem item,
    required int usedAmount,
    required this.maxAmount,
    GlobalFoodNutrition? manualNutrition,
  }) : itemId = item.id,
       name = item.name,
       brand = item.brand,
       unit = _usedUnitForItem(item),
       inventoryItem = item,
       amountController = TextEditingController(
         text: usedAmount.toString(),
       ),
       kcalController = TextEditingController(
         text: _nutritionText(manualNutrition?.per100Kcal),
       ),
       proteinController = TextEditingController(
         text: _nutritionText(manualNutrition?.per100Protein),
       ),
       carbsController = TextEditingController(
         text: _nutritionText(manualNutrition?.per100Carbs),
       ),
       fatController = TextEditingController(
         text: _nutritionText(manualNutrition?.per100Fat),
       );

  final String itemId;
  final String name;
  final String? brand;
  final InventoryAmountUnit unit;
  final InventoryItem? inventoryItem;
  final int? maxAmount;
  final TextEditingController amountController;
  final TextEditingController kcalController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;

  bool get requiresManualNutrition {
    final item = inventoryItem;
    return item != null && !_hasCompleteNutrition(item.nutrition);
  }

  bool get usesPieceNutrition => unit == InventoryAmountUnit.piece;

  String? availableLabel(AppLocalizations l10n) {
    final max = maxAmount;
    if (max == null) {
      return null;
    }
    return l10n.preparedMealAvailableAmount(max, unit.localizedName(l10n));
  }

  void dispose() {
    amountController.dispose();
    kcalController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }
}

InventoryItem? _findInventoryItem(List<InventoryItem> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) {
      return item;
    }
  }
  return null;
}

PreparedMealComponent? _findComponent(
  List<PreparedMealComponent> components,
  String itemId,
) {
  for (final component in components) {
    if (component.inventoryItemId == itemId) {
      return component;
    }
  }
  return null;
}

InventoryAmountUnit _usedUnitForItem(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.amountUnit ?? InventoryAmountUnit.piece;
  }
  return InventoryAmountUnit.piece;
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

int _maxInt(int left, int right) {
  return left > right ? left : right;
}

String _nutritionText(double? value) {
  return value?.toString() ?? '';
}
