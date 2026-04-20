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

part 'product_ai_search_page_components.dart';

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
    return _roundToWholeNumber(
      draft.defaultKcal * 100 / draft.totalWeightGrams,
    );
  }

  _AiNutritionSelection _buildSelection({
    required ProductAiSearchDraft draft,
    required double weightGrams,
    required double selectedPer100Kcal,
  }) {
    final basePer100Kcal = _basePer100Kcal(draft);
    final minPer100Kcal = _roundToWholeNumber(
      draft.totalKcalMin * 100 / draft.totalWeightGrams,
    );
    final maxPer100Kcal = _roundToWholeNumber(
      draft.totalKcalMax * 100 / draft.totalWeightGrams,
    );
    final resolvedPer100Kcal = _roundToWholeNumber(
      selectedPer100Kcal.clamp(
        minPer100Kcal,
        maxPer100Kcal,
      ),
    );
    final selectedTotalKcal = _roundToWholeNumber(
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

  double _roundToWholeNumber(double value) {
    return value.roundToDouble();
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
