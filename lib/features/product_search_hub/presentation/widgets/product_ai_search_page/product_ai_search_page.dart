import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
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
  });

  /// Key of the analyze button.
  static const analyzeKey = Key('food_estimate_analyze_button');

  /// Key of the description field.
  static const descriptionKey = Key('food_estimate_description_field');

  /// Base item to build from.
  final InventoryItem item;

  /// Quick-eat settings.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Initial description.
  final String initialPrompt;

  /// Whether the result is logged or goes to the Vorrat.
  final InventoryReceiptManualProductAction initialAction;

  @override
  ConsumerState<ManualProductAiSearchPage> createState() =>
      _ManualProductAiSearchPageState();
}

class _ManualProductAiSearchPageState
    extends ConsumerState<ManualProductAiSearchPage> {
  static const _maxPhotoWidth = 1600.0;
  static const _photoQuality = 80;

  late final _description = TextEditingController(text: widget.initialPrompt)
    ..addListener(() => setState(() {}));
  final _picker = ImagePicker();

  @override
  void dispose() {
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
      onSecondary: isLoading ? null : () => unawaited(_takePhoto()),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xs,
          children: [
            Text(
              l10n.foodEstimateHeadline,
              style: textTheme.displaySmall?.copyWith(
                fontFamily: AppFonts.display,
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
          onAdd: isLoading ? null : () => unawaited(_pickPhotos()),
          onRemove: ref
              .read(foodEstimateControllerProvider.notifier)
              .removePhoto,
        ),
        TextField(
          key: ManualProductAiSearchPage.descriptionKey,
          controller: _description,
          enabled: !isLoading,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.foodEstimateDescriptionLabel,
            hintText: l10n.foodEstimateDescriptionHint,
          ),
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

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxPhotoWidth,
      imageQuality: _photoQuality,
    );
    await _addFiles([?file]);
  }

  Future<void> _pickPhotos() async {
    final files = await _picker.pickMultiImage(
      maxWidth: _maxPhotoWidth,
      imageQuality: _photoQuality,
    );
    await _addFiles(files);
  }

  Future<void> _addFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    final photos = <FoodEstimatePhoto>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      photos.add((mimeType: _mimeType(file.name, bytes), bytes: bytes));
    }
    if (!mounted) return;
    ref.read(foodEstimateControllerProvider.notifier).addPhotos(photos);
  }

  Future<void> _analyze() async {
    FocusManager.instance.primaryFocus?.unfocus();
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
    popManualProductSearchPage(context, result);
  }

  static String _mimeType(String name, Uint8List bytes) =>
      lookupMimeType(name, headerBytes: bytes) ?? 'image/jpeg';
}
