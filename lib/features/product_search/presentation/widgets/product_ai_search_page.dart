import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/nutrition_profile_card.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_components.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_utils.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Result returned from the AI food creation page.
class ManualProductAiSearchResult {
  /// Creates a result.
  const ManualProductAiSearchResult({
    required this.item,
    required this.action,
    required this.globalPackageWeight,
  });

  /// Built inventory item.
  final InventoryItem item;

  /// Requested follow-up action.
  final InventoryReceiptManualProductAction action;

  /// Package weight to persist globally.
  final String globalPackageWeight;
}

/// Read-only AI food creation page with limited user adjustments.
class ManualProductAiSearchPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const ManualProductAiSearchPage({
    required this.item,
    super.key,
    this.initialPrompt = '',
    this.showEatImmediatelyOption = false,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
  });

  /// Base item to build from.
  final InventoryItem item;

  /// Initial prompt text.
  final String initialPrompt;

  /// Whether eat-now action is available.
  final bool showEatImmediatelyOption;

  /// Initially selected action.
  final InventoryReceiptManualProductAction initialAction;

  @override
  ConsumerState<ManualProductAiSearchPage> createState() =>
      _ManualProductAiSearchPageState();
}

class _ManualProductAiSearchPageState
    extends ConsumerState<ManualProductAiSearchPage> {
  late final VoiceSearchService _voiceSearchService;
  final _voiceSearchController = TextVoiceSearchController();
  late final TextEditingController _promptController;
  late final TextEditingController _weightController;
  late InventoryReceiptManualProductAction _selectedAction =
      widget.initialAction;
  ProductAiSearchDraft? _draft;
  bool _isLoading = false;
  bool _hasWeightError = false;
  String? _errorText;
  double? _weightGrams;
  double? _selectedPer100Kcal;

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _promptController = TextEditingController(text: widget.initialPrompt);
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _promptController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selection = _resolvedSelection;
    final weightErrorText = _hasWeightError
        ? l10n.inventoryManualAddAiSearchWeightRequired
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ManualProductSearchShell(
        title: l10n.inventoryManualAddAiSearchTitle,
        onClose: _closePage,
        searchBar: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextVoiceSearchBar(
              controller: _promptController,
              label: l10n.inventoryManualAddAiSearchPromptLabel,
              hintText: l10n.inventoryManualAddAiSearchPromptHint,
              fieldKey: const Key('manual_product_ai_prompt_field'),
              voiceButtonKey: const Key(
                'manual_product_ai_voice_search_button',
              ),
              clearButtonKey: const Key(
                'manual_product_ai_prompt_clear_button',
              ),
              autofocus: widget.initialPrompt.trim().isEmpty,
              enabled: !_isLoading,
              voiceSearchService: _voiceSearchService,
              voiceSearchController: _voiceSearchController,
              prefixIcon: const Icon(Icons.auto_awesome_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('manual_product_ai_generate_button'),
                onPressed: _isLoading ? null : () => unawaited(_generate()),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(l10n.inventoryManualAddAiSearchGenerateAction),
              ),
            ),
          ],
        ),
        body: _ManualProductAiSearchBody(
          draft: _draft,
          selection: selection,
          errorText: _errorText,
          weightController: _weightController,
          weightErrorText: weightErrorText,
          selectedAction: _selectedAction,
          showEatImmediatelyOption: widget.showEatImmediatelyOption,
          onActionChanged: (action) {
            setState(() {
              _selectedAction = action;
            });
          },
          onWeightChanged: _handleWeightChanged,
          onPer100KcalChanged: (value) {
            setState(() {
              _selectedPer100Kcal = value;
            });
          },
          onSave: _draft != null && !_hasWeightError && selection != null
              ? _saveDraft
              : null,
        ),
      ),
    );
  }

  _AiNutritionSelection? get _resolvedSelection {
    final draft = _draft;
    final weightGrams = _weightGrams;
    if (draft == null || weightGrams == null) {
      return null;
    }
    return _buildSelection(
      draft: draft,
      weightGrams: weightGrams,
      selectedPer100Kcal: _selectedPer100Kcal ?? _basePer100Kcal(draft),
    );
  }

  Future<void> _generate() async {
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final prompt = normalizeManualProductText(_promptController.text);
    if (prompt == null) {
      setState(() {
        _errorText = l10n.inventoryManualAddAiSearchPromptRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final draft = await ref
        .read(productAiSearchRepositoryProvider)
        .generateFoodFromText(prompt: prompt);
    if (!mounted) {
      return;
    }

    if (draft == null) {
      setState(() {
        _isLoading = false;
        _draft = null;
        _errorText = l10n.inventoryManualAddAiSearchFailed;
      });
      return;
    }

    final basePer100Kcal = _basePer100Kcal(draft);
    setState(() {
      _isLoading = false;
      _draft = draft;
      _errorText = null;
      _hasWeightError = false;
      _weightGrams = draft.totalWeightGrams;
      _selectedPer100Kcal = basePer100Kcal;
      _weightController.text = formatManualProductDouble(
        draft.totalWeightGrams,
      );
    });
  }

  void _handleWeightChanged(String value) {
    final parsedValue = parseManualProductDouble(value);
    setState(() {
      if (parsedValue == null || parsedValue <= 0) {
        _hasWeightError = true;
        return;
      }
      _hasWeightError = false;
      _weightGrams = parsedValue;
    });
  }

  void _saveDraft() {
    final selection = _resolvedSelection;
    if (selection == null) {
      return;
    }

    final result = ManualProductAiSearchResult(
      item: _buildResultItem(selection),
      action: _selectedAction,
      globalPackageWeight: selection.weightLabel,
    );
    _closePage(result);
  }

  InventoryItem _buildResultItem(_AiNutritionSelection selection) {
    final parsedAmount = InventoryAmountParseResult(
      amount: selection.weightGrams.round(),
      unit: InventoryAmountUnit.gram,
    );

    return widget.item
        .copyWith(
          name: selection.draft.name,
          brand: selection.draft.brand,
          barcode: '',
          weight: selection.weightLabel,
          servingSize: selection.weightLabel,
          servingQuantity: selection.weightGrams,
          servingQuantityUnit: InventoryAmountUnit.gram.code,
          nutrition: selection.per100Nutrition,
          imageUrl: null,
        )
        .withResolvedAmount(
          weight: selection.weightLabel,
          parsedAmount: parsedAmount,
          quantity: widget.item.quantity,
        );
  }

  double _basePer100Kcal(ProductAiSearchDraft draft) {
    return _roundToTwoDecimals(
      draft.defaultKcal * 100 / draft.totalWeightGrams,
    );
  }

  _AiNutritionSelection _buildSelection({
    required ProductAiSearchDraft draft,
    required double weightGrams,
    required double selectedPer100Kcal,
  }) {
    final basePer100Kcal = _basePer100Kcal(draft);
    final minPer100Kcal = _roundToTwoDecimals(
      draft.totalKcalMin * 100 / draft.totalWeightGrams,
    );
    final maxPer100Kcal = _roundToTwoDecimals(
      draft.totalKcalMax * 100 / draft.totalWeightGrams,
    );
    final resolvedPer100Kcal = _roundToTwoDecimals(
      selectedPer100Kcal.clamp(
        minPer100Kcal,
        maxPer100Kcal,
      ),
    );
    final selectedTotalKcal = _roundToTwoDecimals(
      resolvedPer100Kcal * draft.totalWeightGrams / 100,
    );
    final fullPortionNutrition = draft.nutritionForKcal(selectedTotalKcal);
    final portionNutrition = fullPortionNutrition.scaleBy(
      weightGrams / draft.totalWeightGrams,
    );
    final per100Nutrition = fullPortionNutrition.toPer100Nutrition(
      grams: draft.totalWeightGrams,
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    );

    return _AiNutritionSelection(
      draft: draft,
      weightGrams: weightGrams,
      weightLabel: '${formatManualProductDouble(weightGrams)} g',
      minPer100Kcal: minPer100Kcal,
      maxPer100Kcal: maxPer100Kcal,
      basePer100Kcal: basePer100Kcal,
      per100Kcal: resolvedPer100Kcal,
      per100Nutrition: per100Nutrition,
      portionNutrition: portionNutrition,
    );
  }

  double _roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }
}

class _ManualProductAiSearchBody extends StatelessWidget {
  const _ManualProductAiSearchBody({
    required this.draft,
    required this.selection,
    required this.errorText,
    required this.weightController,
    required this.weightErrorText,
    required this.selectedAction,
    required this.showEatImmediatelyOption,
    required this.onActionChanged,
    required this.onWeightChanged,
    required this.onPer100KcalChanged,
    required this.onSave,
  });

  final ProductAiSearchDraft? draft;
  final _AiNutritionSelection? selection;
  final String? errorText;
  final TextEditingController weightController;
  final String? weightErrorText;
  final InventoryReceiptManualProductAction selectedAction;
  final bool showEatImmediatelyOption;
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<double> onPer100KcalChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final resolvedDraft = draft;
    final resolvedSelection = selection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchReadOnlyHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (errorText case final String message) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.error),
          ),
        ],
        if (resolvedDraft != null && resolvedSelection != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _AiHeadlineCard(draft: resolvedDraft),
          const SizedBox(height: AppSpacing.lg),
          _AiDensityAdjustCard(
            selection: resolvedSelection,
            onChanged: onPer100KcalChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          NutritionProfileCard(
            title: l10n.inventoryManualAddAiSearchPer100CardTitle,
            kcal: resolvedSelection.per100Kcal,
            kcalUnitLabel: l10n.caloriesUnitKcal,
            protein: resolvedSelection.per100Nutrition.per100Protein,
            carbs: resolvedSelection.per100Nutrition.per100Carbs,
            fat: resolvedSelection.per100Nutrition.per100Fat,
            proteinLabel: l10n.caloriesProteinLabel,
            carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
            fatLabel: l10n.caloriesFatLabel,
            accentColor: colors.tertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          NutritionProfileCard(
            title: l10n.inventoryManualAddAiSearchPortionCardTitle,
            titleColor: colors.primary,
            kcal: resolvedSelection.portionNutrition.kcal,
            kcalUnitLabel: l10n.caloriesUnitKcal,
            protein: resolvedSelection.portionNutrition.protein,
            carbs: resolvedSelection.portionNutrition.carbs,
            fat: resolvedSelection.portionNutrition.fat,
            proteinLabel: l10n.caloriesProteinLabel,
            carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
            fatLabel: l10n.caloriesFatLabel,
            accentColor: colors.primary,
            trailing: _AiWeightField(
              controller: weightController,
              errorText: weightErrorText,
              labelText: l10n.inventoryManualAddAiSearchWeightLabel,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AiIngredientTable(draft: resolvedDraft),
          const SizedBox(height: AppSpacing.lg),
          if (showEatImmediatelyOption) ...[
            ManualProductActionSelector(
              selectedAction: selectedAction,
              onChanged: onActionChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('manual_product_ai_save_button'),
              onPressed: onSave,
              icon: Icon(
                selectedAction ==
                        InventoryReceiptManualProductAction.addToInventory
                    ? Icons.inventory_2_outlined
                    : Icons.restaurant_outlined,
              ),
              label: Text(
                selectedAction ==
                        InventoryReceiptManualProductAction.addToInventory
                    ? l10n.inventoryManualAddResultActionInventory
                    : l10n.inventoryManualAddResultActionEat,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AiHeadlineCard extends StatelessWidget {
  const _AiHeadlineCard({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const Key('manual_product_ai_result_card'),
      width: double.infinity,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (draft.brand case final String brand) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              brand,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _AiMetaWrap(
            labels: <String>[
              draft.totalWeightLabel,
              draft.totalKcalRangeLabel,
              '${formatManualProductDouble(draft.defaultKcal)} kcal',
            ],
          ),
        ],
      ),
    );
  }
}

class _AiDensityAdjustCard extends StatelessWidget {
  const _AiDensityAdjustCard({
    required this.selection,
    required this.onChanged,
  });

  final _AiNutritionSelection selection;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryManualAddAiSearchDensityTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.inventoryManualAddAiSearchDensityHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Slider(
              key: const Key('manual_product_ai_density_slider'),
              value: selection.per100Kcal,
              min: selection.minPer100Kcal,
              max: selection.maxPer100Kcal,
              onChanged: onChanged,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMinLabel(
                      formatManualProductDouble(selection.minPer100Kcal),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.inventoryManualAddAiSearchDensityBaseLabel(
                    formatManualProductDouble(selection.basePer100Kcal),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMaxLabel(
                      formatManualProductDouble(selection.maxPer100Kcal),
                    ),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiWeightField extends StatelessWidget {
  const _AiWeightField({
    required this.controller,
    required this.errorText,
    required this.labelText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final String labelText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextField(
        key: const Key('manual_product_ai_weight_field'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          manualProductSingleDecimalInputFormatter,
        ],
        textAlign: TextAlign.end,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          suffixText: 'g',
          errorText: errorText,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _AiMetaWrap extends StatelessWidget {
  const _AiMetaWrap({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(label),
            ),
          ),
      ],
    );
  }
}

class _AiIngredientTable extends StatelessWidget {
  const _AiIngredientTable({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchIngredientsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                l10n.inventoryManualAddAiSearchAmountColumn,
                style: headerStyle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCaloriesShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesProteinLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCarbsShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesFatLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Divider(color: colors.outlineVariant),
        for (final ingredient in draft.ingredients) ...[
          _AiIngredientRow(ingredient: ingredient),
          const SizedBox(height: AppSpacing.sm),
        ],
        Divider(color: colors.outlineVariant),
        _AiIngredientTotalRow(draft: draft),
      ],
    );
  }
}

class _AiIngredientRow extends StatelessWidget {
  const _AiIngredientRow({required this.ingredient});

  final ProductAiSearchIngredientRow ingredient;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ingredient.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(ingredient.amountText, style: valueStyle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _buildKcalText(),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.protein),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.carbs),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.fat),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buildKcalText() {
    if (ingredient.kcalMin == ingredient.kcalMax) {
      return formatManualProductDouble(ingredient.kcalMin);
    }
    return '${formatManualProductDouble(ingredient.kcalMin)} - '
        '${formatManualProductDouble(ingredient.kcalMax)}';
  }

  String _formatMacro(double? value) {
    if (value == null) {
      return '-';
    }
    return formatManualProductDouble(value);
  }
}

class _AiIngredientTotalRow extends StatelessWidget {
  const _AiIngredientTotalRow({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            AppLocalizations.of(context)!.inventoryManualAddAiSearchTotalLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 4,
          child: Text(draft.totalWeightLabel, style: valueStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            draft.totalKcalRangeLabel,
            style: valueStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _AiNutritionSelection {
  const _AiNutritionSelection({
    required this.draft,
    required this.weightGrams,
    required this.weightLabel,
    required this.minPer100Kcal,
    required this.maxPer100Kcal,
    required this.basePer100Kcal,
    required this.per100Kcal,
    required this.per100Nutrition,
    required this.portionNutrition,
  });

  final ProductAiSearchDraft draft;
  final double weightGrams;
  final String weightLabel;
  final double minPer100Kcal;
  final double maxPer100Kcal;
  final double basePer100Kcal;
  final double per100Kcal;
  final GlobalFoodNutrition per100Nutrition;
  final ProductAiSearchNutritionEstimate portionNutrition;
}
