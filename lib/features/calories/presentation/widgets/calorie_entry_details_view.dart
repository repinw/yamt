import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Read-only details view for an existing diary entry.
class CalorieEntryDetailsView extends ConsumerWidget {
  /// The calorie entry details view.
  const CalorieEntryDetailsView({
    required this.entry,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.isSaving,
    required this.onClose,
    required this.onMealTypeChanged,
    required this.onPickLoggedAt,
    required this.onSave,
    required this.onReturnToInventory,
    super.key,
  });

  /// The displayed entry.
  final CalorieEntry entry;

  /// The currently selected meal type.
  final MealType selectedMealType;

  /// The currently selected logged day/time.
  final DateTime selectedLoggedAt;

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Called when closing the view.
  final VoidCallback onClose;

  /// Called when the meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Called when changing the logged day.
  final VoidCallback onPickLoggedAt;

  /// Called when saving the changed meal type.
  final VoidCallback onSave;

  /// Called when returning the entry to inventory.
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final hasMealChanges = selectedMealType != entry.mealType;
    final hasLoggedAtChanges = selectedLoggedAt != entry.loggedAt;
    final hasPendingChanges = hasMealChanges || hasLoggedAtChanges;
    final canReturn =
        entry.canRestoreToInventory || entry.canReturnPreparedMealToInventory;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.9;
    final sheetRadius = BorderRadius.circular(
      AppInventoryEditorial.cardRadius + AppSpacing.xs,
    );
    final sheetGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(
          colors.surfaceContainerLow.withValues(alpha: 0.96),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.99),
          colors.surface,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: maxSheetHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: sheetRadius,
                  boxShadow: [
                    AppInventoryEditorialSurfaces.ambientBoxShadow(
                      colors,
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: sheetRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppInventoryEditorial.glassBlur,
                      sigmaY: AppInventoryEditorial.glassBlur,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: sheetGradient,
                        borderRadius: sheetRadius,
                        border: Border.all(
                          color: AppInventoryEditorialSurfaces.ghostBorder(
                            colors,
                          ).withValues(alpha: 0.9),
                        ),
                      ),
                      child: Column(
                        children: [
                          _DetailsSheetHeader(
                            title: l10n.caloriesEditEntryTitle,
                            closeTooltip: material.closeButtonTooltip,
                            isSaving: isSaving,
                            onClose: onClose,
                          ),
                          Flexible(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              children: [
                                _EntryOverviewCard(
                                  entry: entry,
                                  isSaving: isSaving,
                                  selectedMealType: selectedMealType,
                                  selectedLoggedAt: selectedLoggedAt,
                                  onPickLoggedAt: onPickLoggedAt,
                                  onMealTypeChanged: onMealTypeChanged,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _CompactPanel(
                                  title:
                                      l10n.inventoryItemEatSheetNutritionLabel,
                                  child: NutritionMetricsStrip(
                                    key: CalorieEntryDetailKeys.nutritionStrip,
                                    metrics: _buildNutritionMetrics(
                                      l10n,
                                      entry,
                                    ),
                                    height: 64,
                                    radius: 20,
                                    dividerHeight: 22,
                                  ),
                                ),
                                if (entry.isBundle &&
                                    entry.bundleComponents.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _IngredientsTableCard(entry: entry),
                                ],
                              ],
                            ),
                          ),
                          _DetailsSheetFooter(
                            canReturn: canReturn,
                            isSaving: isSaving,
                            hasPendingChanges: hasPendingChanges,
                            onSave: onSave,
                            onReturnToInventory: onReturnToInventory,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsSheetHeader extends StatelessWidget {
  const _DetailsSheetHeader({
    required this.title,
    required this.closeTooltip,
    required this.isSaving,
    required this.onClose,
  });

  final String title;
  final String closeTooltip;
  final bool isSaving;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: isSaving ? null : onClose,
                tooltip: closeTooltip,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryOverviewCard extends ConsumerWidget {
  const _EntryOverviewCard({
    required this.entry,
    required this.isSaving,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.onPickLoggedAt,
    required this.onMealTypeChanged,
  });

  final CalorieEntry entry;
  final bool isSaving;
  final MealType selectedMealType;
  final DateTime selectedLoggedAt;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final brand = entry.brand?.trim();
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: Color.alphaBlend(
          colors.surfaceContainerLow.withValues(alpha: 0.78),
          colors.surface,
        ),
        blurRadius: 24,
        shadowOffset: const Offset(0, 12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EntryThumbnail(
                  entry: entry,
                  storedImageBytes: storedImageBytes,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      if (brand != null && brand.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          brand,
                          key: CalorieEntryDetailKeys.brandValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _EntryTag(
                  icon: Icons.restaurant_menu_rounded,
                  label: selectedMealType.localizedName(l10n),
                ),
                if (entry.isBundle)
                  _EntryTag(
                    icon: Icons.soup_kitchen_outlined,
                    label: l10n.preparedMealSectionTitle,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _EntryMetricChip(
                  title: l10n.caloriesEntryAmountLabel,
                  value: _consumedAmountLabel(l10n, entry),
                  icon: Icons.scale_outlined,
                  valueKey: CalorieEntryDetailKeys.amountValue,
                ),
                _EntryMetricChip(
                  title: l10n.preparedMealDiaryDayLabel,
                  value: material.formatShortDate(selectedLoggedAt),
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _EntryControlRow(
              isSaving: isSaving,
              selectedMealType: selectedMealType,
              selectedLoggedAt: selectedLoggedAt,
              onPickLoggedAt: onPickLoggedAt,
              onMealTypeChanged: onMealTypeChanged,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryThumbnail extends StatelessWidget {
  const _EntryThumbnail({required this.entry, required this.storedImageBytes});

  final CalorieEntry entry;
  final Uint8List? storedImageBytes;

  static const _imageSize = 76.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
      child: SizedBox.square(
        dimension: _imageSize,
        child: _EntryImage(
          entry: entry,
          storedImageBytes: storedImageBytes,
        ),
      ),
    );
  }
}

class _EntryImage extends StatelessWidget {
  const _EntryImage({required this.entry, required this.storedImageBytes});

  final CalorieEntry entry;
  final Uint8List? storedImageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedName = entry.name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    final imageUrl = entry.imageUrl?.trim();
    final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;

    if (storedImageBytes != null) {
      return Image.memory(
        storedImageBytes!,
        key: CaloriesPageKeys.entryImage(entry.id),
        fit: BoxFit.cover,
      );
    }

    if (hasImageUrl) {
      return AppCachedNetworkImage(
        imageUrl: imageUrl,
        key: CaloriesPageKeys.entryImage(entry.id),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _EntryImageFallback(initial: initial),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
      ),
      child: _EntryImageFallback(initial: initial),
    );
  }
}

class _EntryImageFallback extends StatelessWidget {
  const _EntryImageFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.onPrimaryContainer),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryMetricChip extends StatelessWidget {
  const _EntryMetricChip({
    required this.title,
    required this.value,
    required this.icon,
    this.valueKey,
  });

  final String title;
  final String value;
  final IconData icon;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(
            colors,
          ).withValues(alpha: 0.85),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  key: valueKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryControlRow extends StatelessWidget {
  const _EntryControlRow({
    required this.isSaving,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.onPickLoggedAt,
    required this.onMealTypeChanged,
    this.compact = false,
  });

  final bool isSaving;
  final MealType selectedMealType;
  final DateTime selectedLoggedAt;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        final dayCard = _CompactFieldCard(
          label: l10n.preparedMealDiaryDayLabel,
          compact: compact,
          child: _LoggedDayButton(
            loggedAt: selectedLoggedAt,
            isEnabled: !isSaving,
            onPressed: onPickLoggedAt,
            material: material,
          ),
        );
        final mealCard = _CompactFieldCard(
          label: l10n.caloriesEntryMealLabel,
          compact: compact,
          child: _MealTypeDropdown(
            selectedMealType: selectedMealType,
            isEnabled: !isSaving,
            onMealTypeChanged: onMealTypeChanged,
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              dayCard,
              SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
              mealCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: dayCard),
            SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
            Expanded(child: mealCard),
          ],
        );
      },
    );
  }
}

class _CompactFieldCard extends StatelessWidget {
  const _CompactFieldCard({
    required this.label,
    required this.child,
    this.compact = false,
  });

  final String label;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
        color: colors.surfaceContainerLowest.withValues(alpha: 0.82),
        blurRadius: compact ? 12 : 18,
        shadowOffset: Offset(0, compact ? 4 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 0 : AppSpacing.xxs),
            child,
          ],
        ),
      ),
    );
  }
}

class _LoggedDayButton extends StatelessWidget {
  const _LoggedDayButton({
    required this.loggedAt,
    required this.isEnabled,
    required this.onPressed,
    required this.material,
  });

  final DateTime loggedAt;
  final bool isEnabled;
  final VoidCallback onPressed;
  final MaterialLocalizations material;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isEnabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: CalorieEntryDetailKeys.loggedDayButton,
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: isEnabled ? colors.primary : foregroundColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  material.formatShortDate(loggedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTypeDropdown extends StatelessWidget {
  const _MealTypeDropdown({
    required this.selectedMealType,
    required this.isEnabled,
    required this.onMealTypeChanged,
  });

  final MealType selectedMealType;
  final bool isEnabled;
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<MealType>(
        key: CalorieEntryDetailKeys.mealSelector,
        value: selectedMealType,
        isDense: true,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        dropdownColor: colors.surfaceContainerHigh,
        icon: Icon(
          Icons.expand_more_rounded,
          color: colors.onSurfaceVariant,
          size: 20,
        ),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isEnabled
              ? colors.onSurface
              : colors.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w700,
        ),
        items: MealType.sectionOrder
            .map((mealType) {
              return DropdownMenuItem<MealType>(
                value: mealType,
                child: Text(
                  mealType.localizedName(l10n),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            })
            .toList(growable: false),
        onChanged: isEnabled
            ? (value) {
                if (value == null) {
                  return;
                }
                onMealTypeChanged(value);
              }
            : null,
      ),
    );
  }
}

class _CompactPanel extends StatelessWidget {
  const _CompactPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: Color.alphaBlend(
          colors.surfaceContainerLow.withValues(alpha: 0.72),
          colors.surface,
        ),
        blurRadius: 20,
        shadowOffset: const Offset(0, 10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailsSheetFooter extends StatelessWidget {
  const _DetailsSheetFooter({
    required this.canReturn,
    required this.isSaving,
    required this.hasPendingChanges,
    required this.onSave,
    required this.onReturnToInventory,
  });

  final bool canReturn;
  final bool isSaving;
  final bool hasPendingChanges;
  final VoidCallback onSave;
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppInventoryEditorial.glassBlur * 0.75,
          sigmaY: AppInventoryEditorial.glassBlur * 0.75,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: AppInventoryEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.9),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canReturn) ...[
                    TextButton.icon(
                      key: CalorieEntryDetailKeys.returnToInventoryButton,
                      onPressed: isSaving ? null : onReturnToInventory,
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        foregroundColor: colors.primary,
                      ),
                      label: Text(
                        l10n.caloriesReturnPreparedMealConfirmAction,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: CalorieEntryEditorKeys.saveButton,
                      onPressed: isSaving || !hasPendingChanges ? null : onSave,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(l10n.caloriesSaveEntryAction),
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

class _IngredientsTableCard extends StatelessWidget {
  const _IngredientsTableCard({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _CompactPanel(
      title: l10n.preparedMealIngredientsTitle,
      trailing: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            entry.bundleComponents.length.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: DecoratedBox(
          key: CalorieEntryDetailKeys.ingredientsTable,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            border: Border.all(
              color: AppInventoryEditorialSurfaces.ghostBorder(
                colors,
              ).withValues(alpha: 0.8),
            ),
          ),
          child: Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(2.6),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(0.9),
            },
            children: [
              _ingredientHeaderRow(context, l10n),
              for (
                var index = 0;
                index < entry.bundleComponents.length;
                index += 1
              )
                _ingredientRow(
                  context,
                  component: entry.bundleComponents[index],
                  index: index,
                  kcalUnit: l10n.caloriesUnitKcal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _ingredientHeaderRow(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );

    return TableRow(
      decoration: BoxDecoration(color: colors.surfaceContainerLow),
      children: [
        _IngredientTableCell(
          child: Text(l10n.preparedMealIngredientsTitle, style: textStyle),
        ),
        _IngredientTableCell(
          child: Text(l10n.inventorySortQuantity, style: textStyle),
        ),
        _IngredientTableCell(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.inventoryNutritionCaloriesShortLabel,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  TableRow _ingredientRow(
    BuildContext context, {
    required CalorieEntryBundleComponent component,
    required int index,
    required String kcalUnit,
  }) {
    final colors = Theme.of(context).colorScheme;
    final brand = component.brand?.trim();

    return TableRow(
      key: ValueKey('ingredient_row_$index'),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppInventoryEditorialSurfaces.ghostBorder(colors),
          ),
        ),
      ),
      children: [
        _IngredientTableCell(
          child: Column(
            key: CalorieEntryDetailKeys.ingredientNameCell(index),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                component.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (brand != null && brand.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    brand,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _IngredientTableCell(
          child: Text(
            component.amountLabel,
            key: CalorieEntryDetailKeys.ingredientAmountCell(index),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _IngredientTableCell(
          alignment: Alignment.centerRight,
          child: Text(
            '${component.totalKcal.toStringAsFixed(0)} $kcalUnit',
            key: CalorieEntryDetailKeys.ingredientKcalCell(index),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientTableCell extends StatelessWidget {
  const _IngredientTableCell({
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Align(alignment: alignment, child: child),
    );
  }
}

List<NutritionMetric> _buildNutritionMetrics(
  AppLocalizations l10n,
  CalorieEntry entry,
) {
  return [
    NutritionMetric(
      label: l10n.inventoryNutritionCaloriesShortLabel,
      value: entry.totalKcal.round().toString(),
    ),
    NutritionMetric(
      label: l10n.inventoryNutritionCarbsShortLabel,
      value: '${formatNutritionMetricValue(entry.totalCarbs)}g',
    ),
    NutritionMetric(
      label: l10n.caloriesProteinLabel,
      value: '${formatNutritionMetricValue(entry.totalProtein)}g',
    ),
    NutritionMetric(
      label: l10n.caloriesFatLabel,
      value: '${formatNutritionMetricValue(entry.totalFat)}g',
    ),
  ];
}

String _consumedAmountLabel(AppLocalizations l10n, CalorieEntry entry) {
  if (entry.isBundle) {
    return l10n.caloriesBundlePortions(
      entry.bundleConsumedPortions ?? 0,
      entry.bundleTotalPortions ?? 0,
    );
  }

  return '${formatNutritionMetricValue(entry.consumedAmount)} '
      '${entry.consumedUnit.localizedName(l10n)}';
}
