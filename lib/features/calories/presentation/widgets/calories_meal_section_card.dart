import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesMealSectionCard extends StatelessWidget {
  const CaloriesMealSectionCard({
    super.key,
    required this.section,
    required this.title,
    required this.emptyMessage,
    required this.deleteTooltip,
    required this.onTapEntry,
    required this.onDeleteEntry,
    required this.onAddEntry,
  });

  final CalorieMealSection section;
  final String title;
  final String emptyMessage;
  final String deleteTooltip;
  final ValueChanged<CalorieEntry> onTapEntry;
  final ValueChanged<CalorieEntry> onDeleteEntry;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kcalUnit = l10n.caloriesUnitKcal;

    return Column(
      key: CaloriesPageKeys.sectionCard(section.mealType.name),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '${section.totalKcal.toStringAsFixed(0)} $kcalUnit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              key: CaloriesPageKeys.sectionAddButton(section.mealType.name),
              tooltip: l10n.caloriesAddEntryTitle,
              onPressed: onAddEntry,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppInventoryEditorial.primary.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: AppInventoryEditorial.primary,
              ),
            ),
          ],
        ),
        if (section.entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...section.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DiaryMealEntryCard(
                entry: entry,
                kcalUnit: kcalUnit,
                onTap: () => onTapEntry(entry),
                onDelete: () => onDeleteEntry(entry),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _DiaryMealEntryCard extends StatelessWidget {
  const _DiaryMealEntryCard({
    required this.entry,
    required this.kcalUnit,
    required this.onTap,
    required this.onDelete,
  });

  final CalorieEntry entry;
  final String kcalUnit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final metadata = <String>[
      '${entry.consumedAmount.toStringAsFixed(0)} '
          '${entry.consumedUnit.localizedName(l10n)}',
      if ((entry.brand ?? '').trim().isNotEmpty) entry.brand!.trim(),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: CaloriesPageKeys.entryTile(entry.id),
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _MealThumb(
                  entryId: entry.id,
                  label: entry.name,
                  imageUrl: entry.imageUrl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        metadata.join(' • ').toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${entry.totalKcal.toStringAsFixed(0)} $kcalUnit',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealThumb extends StatelessWidget {
  const _MealThumb({
    required this.entryId,
    required this.label,
    required this.imageUrl,
  });

  final String entryId;
  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = _normalizeImageUrl(imageUrl);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppInventoryEditorial.primary.withValues(alpha: 0.14),
            Theme.of(context).colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SizedBox.square(
        dimension: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: normalizedImageUrl == null
              ? _MealThumbFallback(label: label)
              : Image.network(
                  normalizedImageUrl,
                  key: CaloriesPageKeys.entryImage(entryId),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _MealThumbFallback(label: label);
                  },
                ),
        ),
      ),
    );
  }
}

class _MealThumbFallback extends StatelessWidget {
  const _MealThumbFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppInventoryEditorial.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _normalizeImageUrl(String? value) {
  if (value == null) {
    return null;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return 'https://world.openfoodfacts.org$trimmed';
  }

  final uri = Uri.tryParse(trimmed);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return trimmed;
  }

  return null;
}
