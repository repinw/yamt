import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_nutrition_facts.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the diary entry details page: the entry's image, brand line and
/// name, and its nutrition label for the eaten amount.
///
/// The image tile is the landing spot of the image that flies in from the
/// diary row.
class DiaryEntryLabelSection extends ConsumerWidget {
  /// Creates the section for [entry].
  const new({required this.entry, super.key});

  /// Key of the nutrition label.
  static const labelKey = Key('diary_entry_details_label');

  /// Key of the placeholder shown without an image.
  static const imageFallbackKey = Key('diary_entry_details_image_fallback');

  /// The entry, with the totals of the entered amount.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final per100 = calorieEntryPer100Facts(entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxl,
      children: [
        EatPageHeader(
          title: entry.name,
          brand: _brandLine(l10n, entry),
          imageUrl: entry.imageUrl,
          imageBytes: imageBytes,
          collageImageUrls: [
            for (final food in entry.bundleComponents) food.imageUrl,
          ],
          fallbackKey: imageFallbackKey,
          heroTag: HeroTags.loggedEntryImage(entry.id),
        ),
        EatLabelTable(
          key: labelKey,
          rows: nutritionFactsRows(
            context,
            eaten: calorieEntryEatenFacts(entry),
            per100: per100,
          ),
          per100Header: per100 == null
              ? null
              : l10n.caloriesEntryPer100Label(
                  consumedUnitSymbol(l10n, entry.consumedUnit),
                ),
          eatenHeader: _eatenHeader(l10n, entry),
        ),
      ],
    );
  }

  /// The first brand, or what kind of bundle the entry is. Product
  /// databases often list the retailer, the maker, and the label in one
  /// comma-separated field.
  static String? _brandLine(AppLocalizations l10n, CalorieEntry entry) {
    final brand = entry.brand?.split(',').first.trim();
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }
    if (entry.isCombined) {
      return l10n.caloriesCombinedEntryLabel;
    }
    return entry.isBundle ? l10n.preparedMealSectionTitle : null;
  }

  static String _eatenHeader(AppLocalizations l10n, CalorieEntry entry) {
    if (entry.isQuickEntry) {
      return l10n.diaryQuickEntryValuesHeader;
    }
    final number = NumberFormat.decimalPattern(l10n.localeName)
      ..maximumFractionDigits = 1;
    if (entry.isCombined) {
      return l10n.caloriesCombinedFoodCount(entry.bundleComponents.length);
    }
    if (entry.isBundle) {
      return l10n.caloriesBundlePortions(
        number.format(entry.bundleConsumedPortions ?? 0),
        entry.bundleTotalPortions ?? 0,
      );
    }
    return l10n.inventoryEatSheetAmountWithUnit(
      number.format(entry.consumedAmount),
      consumedUnitSymbol(l10n, entry.consumedUnit),
    );
  }
}
