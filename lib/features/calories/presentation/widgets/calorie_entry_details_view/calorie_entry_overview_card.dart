import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
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
///
/// The image next to the name is the landing spot of the hero image from the
/// diary row. Entries without an image show their initial and do not fly.
class CalorieEntryOverviewCard extends ConsumerWidget {
  /// Creates the calorie entry overview card.
  const new({
    required this.entry,
    required this.isSaving,
    required this.onPickLoggedAt,
    required this.onMealTypeChanged,
    required this.onPickAmount,
    super.key,
  });

  /// Entry shown in the overview.
  final CalorieEntry entry;

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Called when changing the logged day and time.
  final VoidCallback onPickLoggedAt;

  /// Called when changing the meal type.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Called when tapping the amount, or `null` when it is not editable.
  final VoidCallback? onPickAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImage = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef));
    final storedImageBytes = storedImage?.asData?.value;
    final imageUrl = entry.imageUrl?.trim();
    final hasImage =
        storedImageBytes != null ||
        (storedImage?.isLoading ?? false) ||
        (imageUrl != null && imageUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalorieEntryThumbnail(
              entry: entry,
              storedImageBytes: storedImageBytes,
              heroEnabled: hasImage,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _EntryTitle(
                entry: entry,
                onPickAmount: isSaving ? null : onPickAmount,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        CalorieEntryControlRow(
          isSaving: isSaving,
          selectedMealType: entry.mealType,
          selectedLoggedAt: entry.loggedAt,
          onPickLoggedAt: onPickLoggedAt,
          onMealTypeChanged: onMealTypeChanged,
        ),
      ],
    );
  }
}

class _EntryTitle extends StatelessWidget {
  const new({required this.entry, required this.onPickAmount});

  final CalorieEntry entry;
  final VoidCallback? onPickAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brand = calorieEntryPrimaryBrand(entry);
    final eyebrow =
        brand ?? (entry.isBundle ? l10n.preparedMealSectionTitle : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow,
            key: brand != null ? CalorieEntryDetailKeys.brandValue : null,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
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
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _AmountButton(
          label: calorieEntryConsumedAmountLabel(l10n, entry),
          tooltip: l10n.caloriesEditAmountTooltip,
          onPressed: onPickAmount,
        ),
      ],
    );
  }
}

/// Consumed amount; tappable with an edit icon when it can change.
class _AmountButton extends StatelessWidget {
  const new({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meta = CalorieEntryMetaItem(
      icon: Icons.scale_outlined,
      label: label,
      valueKey: CalorieEntryDetailKeys.amountValue,
    );
    final onPressed = this.onPressed;
    if (onPressed == null) {
      return meta;
    }

    return Tooltip(
      message: tooltip,
      child: AppInkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: meta),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.edit_outlined,
                size: AppSizes.compactMetricIcon,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
