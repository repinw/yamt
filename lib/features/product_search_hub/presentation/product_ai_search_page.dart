import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'food_estimate_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'food_estimate_result_page.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'food_estimate_photo_strip.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// AI food creation: photos and/or a description go to the AI, and the
/// estimate opens on the eat page.
class ManualProductAiSearchPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const new({
    required this.item,
    super.key,
    this.initialPrompt = '',
    this.quickEatConfig = InventoryManualAddQuickEatConfig.standard,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
    this.onResult,
  });

  /// Key of the analyze button.
  static const analyzeKey = Key('food_estimate_analyze_button');

  /// Key of the description field.
  static const descriptionKey = Key('food_estimate_description_field');

  /// Key of the button that dictates the description.
  static const voiceKey = Key('food_estimate_voice_button');

  /// Base item to build from.
  final InventoryItem item;

  /// Quick-eat settings.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Initial description.
  final String initialPrompt;

  /// Whether the result is logged or goes to the Vorrat.
  final InventoryReceiptManualProductAction initialAction;

  /// Receives the chosen food in place of popping the page's route, when the
  /// page is the content of another route.
  final ValueChanged<ManualProductAiSearchResult>? onResult;

  @override
  ConsumerState<ManualProductAiSearchPage> createState() =>
      _ManualProductAiSearchPageState();
}

class _ManualProductAiSearchPageState
    extends ConsumerState<ManualProductAiSearchPage> {
  late final _description = TextEditingController(text: widget.initialPrompt)
    ..addListener(() => setState(() {}));
  final _voice = TextVoiceSearchController();
  late final VoiceSearchService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceSearchServiceProvider);
  }

  @override
  void dispose() {
    _voice.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(foodEstimateControllerProvider);
    final isLoading = state.estimate.isLoading;
    final hasInput =
        state.photos.isNotEmpty || _description.text.trim().isNotEmpty;
    final error = state.estimate.error;

    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: null,
      confirmLabel: isLoading
          ? l10n.foodEstimateAnalyzing
          : l10n.foodEstimateAnalyze,
      confirmButtonKey: ManualProductAiSearchPage.analyzeKey,
      onConfirm: hasInput && !isLoading ? () => unawaited(_analyze()) : null,
      cancelButtonKey: const Key('food_estimate_close_button'),
      secondaryLabel: l10n.foodEstimateCamera,
      onSecondary: isLoading ? null : () => _addPhotos(fromCamera: true),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xs,
          children: [
            Text(
              l10n.foodEstimateHeadline,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.foodEstimateHint,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          ],
        ),
        FoodEstimatePhotoStrip(
          photos: [for (final photo in state.photos) photo.bytes],
          onAdd: isLoading ? null : () => _addPhotos(fromCamera: false),
          onRemove: (index) => ref
              .read(foodEstimateControllerProvider.notifier)
              .removePhoto(index),
        ),
        TextVoiceSearchBar(
          controller: _description,
          fieldKey: ManualProductAiSearchPage.descriptionKey,
          voiceButtonKey: ManualProductAiSearchPage.voiceKey,
          label: l10n.foodEstimateDescriptionLabel,
          hintText: l10n.foodEstimateDescriptionHint,
          enabled: !isLoading,
          voiceSearchService: _voiceService,
          voiceSearchController: _voice,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final phrase in [
              l10n.foodEstimateChipLargePortion,
              l10n.foodEstimateChipRestaurant,
              l10n.foodEstimateChipHomemade,
              l10n.foodEstimateChipHalfEaten,
            ])
              EatChip(
                label: phrase,
                isSelected: false,
                onPressed: () => _appendPhrase(phrase),
              ),
          ],
        ),
        if (error != null)
          Text(
            switch (error) {
              FoodEstimateNotFoodException() => l10n.foodEstimateNotFood,
              FoodEstimateUnclearException() => l10n.foodEstimateUnclear,
              _ => l10n.foodEstimateFailed,
            },
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }

  void _appendPhrase(String phrase) {
    final text = _description.text.trim();
    _description.text = text.isEmpty ? phrase : '$text, $phrase';
  }

  void _addPhotos({required bool fromCamera}) {
    unawaited(
      ref
          .read(foodEstimateControllerProvider.notifier)
          .addPhotos(fromCamera: fromCamera),
    );
  }

  Future<void> _analyze() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _voice.stopVoiceSearchIfNeeded();
    if (!mounted) return;
    final description = _description.text;
    final estimate = await ref
        .read(foodEstimateControllerProvider.notifier)
        .analyze(description);
    if (estimate == null || !mounted) return;

    final quickEat = widget.quickEatConfig;
    final loggedAt = quickEat.preselectedLoggedAt ?? ref.read(clockProvider)();
    final photos = ref.read(foodEstimateControllerProvider).photos;
    final result = await Navigator.of(context, rootNavigator: true)
        .push<ManualProductAiSearchResult>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => FoodEstimateResultPage(
              estimate: estimate,
              baseItem: widget.item,
              eatsNow:
                  quickEat.quickEatOnly ||
                  widget.initialAction ==
                      InventoryReceiptManualProductAction.eatNow,
              description: description,
              initialLoggedAt: loggedAt,
              initialMealType:
                  quickEat.preselectedMealType ??
                  MealType.defaultForDateTime(loggedAt),
              imageBytes: photos.isEmpty ? null : photos.first.bytes,
            ),
          ),
        );
    if (result == null || !mounted) return;
    final onResult = widget.onResult;
    if (onResult != null) {
      onResult(result);
      return;
    }
    popManualProductSearchPage(context, result);
  }
}
