import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_ai_search_service.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_search_shell.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_prompt_bar.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_search_body.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_search_support.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Read-only AI food creation page with limited user adjustments.
class ManualProductAiSearchPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const new({
    required this.item,
    super.key,
    this.initialPrompt = '',
    this.quickEatConfig = InventoryManualAddQuickEatConfig.standard,
    this.showEatImmediatelyOption = false,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
  });

  /// Base item to build from.
  final InventoryItem item;

  /// Quick-eat settings.
  final InventoryManualAddQuickEatConfig quickEatConfig;

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
    final quickEatConfig = widget.quickEatConfig;
    if (quickEatConfig.quickEatOnly) {
      _selectedAction = InventoryReceiptManualProductAction.eatNow;
    }
    _promptController = TextEditingController(text: widget.initialPrompt);
    _weightController = TextEditingController();
    _selectedLoggedAt =
        quickEatConfig.preselectedLoggedAt ?? ref.read(clockProvider)();
    _selectedMealType =
        quickEatConfig.preselectedMealType ??
        MealType.defaultForDateTime(_selectedLoggedAt);
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
    final now = ref.read(clockProvider)();
    final isLoggedAtToday = isProductAiLoggedAtToday(
      selectedLoggedAt: _selectedLoggedAt,
      now: now,
    );
    final loggedAtLabel = isLoggedAtToday
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(_selectedLoggedAt);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ManualProductSearchShell(
        title: l10n.inventoryManualAddAiSearchTitle,
        onClose: _closePage,
        searchBar: ProductAiPromptBar(
          promptController: _promptController,
          voiceSearchController: _voiceSearchController,
          voiceSearchService: _voiceSearchService,
          isLoading: _isLoading,
          autofocus: widget.initialPrompt.trim().isEmpty,
          onGenerate: () => unawaited(_generate()),
        ),
        body: ManualProductAiSearchBody(
          draft: _draft,
          selection: selection,
          errorText: _errorText,
          weightController: _weightController,
          weightErrorText: weightErrorText,
          quickEatConfig: widget.quickEatConfig,
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

  ProductAiNutritionSelection? get _resolvedSelection =>
      resolveProductAiNutritionSelection(
        draft: _draft,
        weightGrams: _weightGrams,
        selectedPer100Kcal: _selectedPer100Kcal,
      );

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

    final basePer100Kcal = resolveProductAiBasePer100Kcal(draft);
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
    final parsedValue = parseProductAiWeightInput(value);
    setState(() {
      _hasWeightError = parsedValue == null;
      if (parsedValue != null) {
        _weightGrams = parsedValue;
      }
    });
  }

  void _saveDraft() {
    final selection = _resolvedSelection;
    if (selection == null) {
      return;
    }

    final result = buildManualProductAiSearchResult(
      baseItem: widget.item,
      selection: selection,
      action: _selectedAction,
      loggedAt: _selectedLoggedAt,
      mealType: _selectedMealType,
    );
    _closePage(result);
  }

  Future<void> _pickLoggedAt() async {
    final pickedDate = await pickProductAiLoggedDate(
      context: context,
      selectedLoggedAt: _selectedLoggedAt,
      now: ref.read(clockProvider)(),
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _selectedLoggedAt = pickedDate;
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
