import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_search_result_builder.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_search_service.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_shell.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Result returned from the AI food creation page.
class ManualProductAiSearchResult {
  /// Creates a result.
  const ManualProductAiSearchResult({
    required this.item,
    required this.action,
    required this.globalPackageWeight,
    this.eatSelection,
  });

  /// Built inventory item.
  final InventoryItem item;

  /// Requested follow-up action.
  final InventoryReceiptManualProductAction action;

  /// Package weight to persist globally.
  final String globalPackageWeight;

  /// Generic eat selection for callers that continue into an eat flow.
  final EatSelection? eatSelection;
}

/// Read-only AI food creation page with limited user adjustments.
@Dependencies([inventoryManualAddQuickEatConfig])
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
  late DateTime _selectedLoggedAt;
  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    if (quickEatConfig.quickEatOnly) {
      _selectedAction = InventoryReceiptManualProductAction.eatNow;
    }
    _promptController = TextEditingController(text: widget.initialPrompt);
    _weightController = TextEditingController();
    _selectedLoggedAt = quickEatConfig.preselectedLoggedAt ?? DateTime.now();
    _selectedMealType =
        quickEatConfig.preselectedMealType ??
        MealType.defaultForDateTime(
          _selectedLoggedAt,
        );
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
    final isLoggedAtToday = _isLoggedAtToday();
    final loggedAtLabel = isLoggedAtToday
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(
            _selectedLoggedAt,
          );

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
        body: ManualProductAiSearchBody(
          draft: _draft,
          selection: selection,
          errorText: _errorText,
          weightController: _weightController,
          weightErrorText: weightErrorText,
          selectedAction: _selectedAction,
          showEatImmediatelyOption: widget.showEatImmediatelyOption,
          isLoggedAtToday: isLoggedAtToday,
          loggedAtLabel: loggedAtLabel,
          selectedMealType: _selectedMealType,
          onActionChanged: (action) {
            setState(() {
              _selectedAction = action;
            });
          },
          onPickLoggedAt: () {
            unawaited(_pickLoggedAt());
          },
          onMealTypeSelected: _selectMealType,
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

  ProductAiNutritionSelection? get _resolvedSelection {
    final draft = _draft;
    final weightGrams = _weightGrams;
    if (draft == null || weightGrams == null) {
      return null;
    }
    return buildProductAiNutritionSelection(
      draft: draft,
      weightGrams: weightGrams,
      selectedPer100Kcal: _selectedPer100Kcal ?? baseProductAiPer100Kcal(draft),
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

    final service = ref.read(productAiSearchServiceProvider);
    final draft = await service.generateDraft(prompt);
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

    final basePer100Kcal = baseProductAiPer100Kcal(draft);
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
      item: buildProductAiResultItem(
        baseItem: widget.item,
        selection: selection,
      ),
      action: _selectedAction,
      globalPackageWeight: selection.weightLabel,
      eatSelection: buildProductAiEatSelection(
        eatNow: _selectedAction == InventoryReceiptManualProductAction.eatNow,
        selection: selection,
        loggedAt: _selectedLoggedAt,
        mealType: _selectedMealType,
      ),
    );
    _closePage(result);
  }

  bool _isLoggedAtToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedLoggedAt);
    return selectedDay == today;
  }

  Future<void> _pickLoggedAt() async {
    final initialDate = DateUtils.dateOnly(_selectedLoggedAt);
    final lastDate = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: DateTime(2000),
      lastDate: lastDate,
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    final now = DateTime.now();
    setState(() {
      _selectedLoggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        now.hour,
        now.minute,
      );
    });
  }

  void _selectMealType(MealType mealType) {
    setState(() {
      _selectedMealType = mealType;
    });
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    popManualProductSearchPage(context, result);
  }
}
