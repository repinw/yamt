import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_control_row.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_meta_item.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_thumbnail.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header card for the calorie entry details sheet.
class CalorieEntryOverviewCard extends ConsumerWidget {
  /// Creates the calorie entry overview card.
  const CalorieEntryOverviewCard({
    required this.entry,
    required this.isSaving,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.onPickLoggedAt,
    required this.onMealTypeChanged,
    super.key,
  });

  /// Entry shown in the overview.
  final CalorieEntry entry;

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Currently selected meal type.
  final MealType selectedMealType;

  /// Currently selected logged day/time.
  final DateTime selectedLoggedAt;

  /// Called when changing the logged day.
  final VoidCallback onPickLoggedAt;

  /// Called when changing the meal type.
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final eyebrow = _entryEyebrow(l10n, entry);
    final brand = entry.brand?.trim();
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalorieEntryThumbnail(
              entry: entry,
              storedImageBytes: storedImageBytes,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow,
                        key: brand != null && brand.isNotEmpty
                            ? CalorieEntryDetailKeys.brandValue
                            : null,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      entry.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final amountMeta = CalorieEntryMetaItem(
                          icon: Icons.scale_outlined,
                          label: calorieEntryConsumedAmountLabel(l10n, entry),
                          valueKey: CalorieEntryDetailKeys.amountValue,
                        );
                        final timeMeta = CalorieEntryMetaItem(
                          icon: Icons.schedule_rounded,
                          label: calorieEntryLoggedAtMetaLabel(
                            context,
                            l10n,
                            material,
                            selectedLoggedAt,
                          ),
                        );

                        if (constraints.maxWidth < 220) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              amountMeta,
                              const SizedBox(height: AppSpacing.xs),
                              timeMeta,
                            ],
                          );
                        }

                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [amountMeta, timeMeta],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        CalorieEntryControlRow(
          isSaving: isSaving,
          selectedMealType: selectedMealType,
          selectedLoggedAt: selectedLoggedAt,
          onPickLoggedAt: onPickLoggedAt,
          onMealTypeChanged: onMealTypeChanged,
        ),
      ],
    );
  }
}

String? _entryEyebrow(AppLocalizations l10n, CalorieEntry entry) {
  final brand = entry.brand?.trim();
  if (brand != null && brand.isNotEmpty) {
    return brand;
  }
  if (entry.isBundle) {
    return l10n.preparedMealSectionTitle;
  }
  return null;
}
