import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show calorie bundle details sheet.
Future<void> showCalorieBundleDetailsSheet(
  BuildContext context, {
  required CalorieEntry entry,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _CalorieBundleDetailsSheet(entry: entry),
  );
}

class _CalorieBundleDetailsSheet extends StatelessWidget {
  const _CalorieBundleDetailsSheet({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: DecoratedBox(
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(
                AppInventoryEditorial.cardRadius,
              ),
            ),
            child: Padding(
              padding: AppInsets.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.caloriesBundlePortions(
                      formatPreparedMealPortions(
                        entry.bundleConsumedPortions ?? 0,
                        localeName: l10n.localeName,
                      ),
                      entry.bundleTotalPortions ?? 0,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${entry.totalKcal.toStringAsFixed(0)} '
                    '${l10n.caloriesUnitKcal}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.preparedMealIngredientsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entry.bundleComponents.length,
                      itemBuilder: (context, index) {
                        final component = entry.bundleComponents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _BundleComponentTile(
                            entryId: entry.id,
                            index: index,
                            component: component,
                            kcalUnit: l10n.caloriesUnitKcal,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BundleComponentTile extends StatelessWidget {
  const _BundleComponentTile({
    required this.entryId,
    required this.index,
    required this.component,
    required this.kcalUnit,
  });

  final String entryId;
  final int index;
  final CalorieEntryBundleComponent component;
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brand = component.brand?.trim();
    final subtitleParts = <String>[
      component.amountLabel,
      if (brand != null && brand.isNotEmpty) brand,
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _BundleComponentThumb(
        entryId: entryId,
        index: index,
        label: component.name,
        imageUrl: component.imageUrl,
      ),
      title: Text(component.name),
      subtitle: Text(
        subtitleParts.join(' • '),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Text('${component.totalKcal.toStringAsFixed(0)} $kcalUnit'),
    );
  }
}

class _BundleComponentThumb extends StatelessWidget {
  const _BundleComponentThumb({
    required this.entryId,
    required this.index,
    required this.label,
    required this.imageUrl,
  });

  final String entryId;
  final int index;
  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.14),
            colors.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SizedBox.square(
        dimension: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: _hasImageUrl(imageUrl)
              ? AppCachedNetworkImage(
                  imageUrl: imageUrl!,
                  key: CaloriesPageKeys.bundleComponentImage(entryId, index),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _BundleComponentThumbFallback(label: label);
                  },
                )
              : _BundleComponentThumbFallback(label: label),
        ),
      ),
    );
  }
}

class _BundleComponentThumbFallback extends StatelessWidget {
  const _BundleComponentThumbFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

bool _hasImageUrl(String? imageUrl) {
  return imageUrl != null && imageUrl.trim().isNotEmpty;
}
