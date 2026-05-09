import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/nutrition_profile_card.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Read-only details view for an existing diary entry.
class CalorieEntryDetailsView extends ConsumerWidget {
  /// The calorie entry details view.
  const CalorieEntryDetailsView({
    required this.title,
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

  /// The visible sheet title.
  final String title;

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
          colors.surfaceContainerHigh.withValues(alpha: 0.9),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.surfaceContainerLow.withValues(alpha: 0.96),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.99),
          colors.surface,
        ),
      ],
      stops: const [0, 0.45, 1],
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
                            title: title,
                            closeTooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            isSaving: isSaving,
                            onClose: onClose,
                          ),
                          Flexible(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                0,
                                AppSpacing.xl,
                                AppSpacing.lg,
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
                                const SizedBox(height: AppSpacing.lg),
                                _NutritionSummaryCard(entry: entry),
                                if (entry.isBundle &&
                                    entry.bundleComponents.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xxl),
                                  _IngredientsSection(entry: entry),
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
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 6,
            decoration: BoxDecoration(
              color: colors.outlineVariant.withValues(alpha: 0.85),
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
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.92,
                  ),
                ),
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
            _EntryThumbnail(entry: entry, storedImageBytes: storedImageBytes),
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
                        final amountMeta = _EntryMetaItem(
                          icon: Icons.scale_outlined,
                          label: _consumedAmountLabel(l10n, entry),
                          valueKey: CalorieEntryDetailKeys.amountValue,
                        );
                        final timeMeta = _EntryMetaItem(
                          icon: Icons.schedule_rounded,
                          label: _loggedAtMetaLabel(
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
        _EntryControlRow(
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

class _EntryMetaItem extends StatelessWidget {
  const _EntryMetaItem({
    required this.icon,
    required this.label,
    this.valueKey,
  });

  final IconData icon;
  final String label;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
  });

  final bool isSaving;
  final MealType selectedMealType;
  final DateTime selectedLoggedAt;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        final dayCard = _CompactFieldCard(
          label: l10n.preparedMealDiaryDayLabel,
          child: _LoggedDayButton(
            loggedAt: selectedLoggedAt,
            isEnabled: !isSaving,
            onPressed: onPickLoggedAt,
            material: material,
          ),
        );
        final mealCard = _CompactFieldCard(
          label: l10n.caloriesEntryMealLabel,
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
              const SizedBox(height: AppSpacing.sm),
              mealCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: dayCard),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: mealCard),
          ],
        );
      },
    );
  }
}

class _CompactFieldCard extends StatelessWidget {
  const _CompactFieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
        color: Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.94),
          colors.surface,
        ),
        blurRadius: 18,
        shadowOffset: const Offset(0, 8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
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
    final l10n = AppLocalizations.of(context)!;
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
              Expanded(
                child: Text(
                  _loggedDayLabel(context, l10n, material, loggedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: isEnabled ? colors.onSurfaceVariant : foregroundColor,
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
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isEnabled
              ? colors.onSurface
              : colors.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        items: MealType.sectionOrder
            .map((mealType) {
              return DropdownMenuItem<MealType>(
                value: mealType,
                child: Text(
                  mealType.localizedName(l10n),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NutritionProfileCard(
      key: CalorieEntryDetailKeys.nutritionStrip,
      kcal: entry.totalKcal,
      kcalUnitLabel: l10n.caloriesUnitKcal,
      carbs: entry.totalCarbs,
      protein: entry.totalProtein,
      fat: entry.totalFat,
      carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
      proteinLabel: l10n.caloriesProteinLabel,
      fatLabel: l10n.caloriesFatLabel,
      accentColor: Theme.of(context).colorScheme.primary,
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
            color: colors.surfaceContainerLowest.withValues(alpha: 0.94),
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
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReturn) ...[
                    TextButton.icon(
                      key: CalorieEntryDetailKeys.returnToInventoryButton,
                      onPressed: isSaving ? null : onReturnToInventory,
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colors.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.caloriesReturnPreparedMealConfirmAction,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: CalorieEntryEditorKeys.saveButton,
                      onPressed: isSaving || !hasPendingChanges ? null : onSave,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Color.alphaBlend(
                          colors.primary.withValues(alpha: 0.14),
                          colors.surfaceContainerLowest,
                        ),
                        disabledBackgroundColor: colors.surfaceContainerLow,
                        foregroundColor: colors.primary,
                        disabledForegroundColor: colors.onSurfaceVariant
                            .withValues(alpha: 0.45),
                        side: BorderSide(
                          color: AppInventoryEditorialSurfaces.ghostBorder(
                            colors,
                          ).withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        elevation: 0,
                      ),
                      label: Text(
                        l10n.caloriesSaveEntryAction,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
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

class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.preparedMealIngredientsTitle.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: DecoratedBox(
            key: CalorieEntryDetailKeys.ingredientsTable,
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              color: Color.alphaBlend(
                colors.surfaceContainerLowest.withValues(alpha: 0.96),
                colors.surface,
              ),
              blurRadius: 16,
              shadowOffset: const Offset(0, 8),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < entry.bundleComponents.length;
                  index++
                ) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppInventoryEditorialSurfaces.ghostBorder(
                        colors,
                      ).withValues(alpha: 0.9),
                    ),
                  _IngredientRow(
                    component: entry.bundleComponents[index],
                    index: index,
                    accentColor: _ingredientAccentColor(index),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.component,
    required this.index,
    required this.accentColor,
  });

  final CalorieEntryBundleComponent component;
  final int index;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brand = component.brand?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: accentColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  key: CalorieEntryDetailKeys.ingredientNameCell(index),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          const SizedBox(width: AppSpacing.sm),
          Text(
            component.amountLabel,
            key: CalorieEntryDetailKeys.ingredientAmountCell(index),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

String _loggedDayLabel(
  BuildContext context,
  AppLocalizations l10n,
  MaterialLocalizations material,
  DateTime loggedAt,
) {
  if (DateUtils.isSameDay(loggedAt, DateTime.now())) {
    return l10n.caloriesTodayAction;
  }
  return material.formatShortDate(loggedAt);
}

String _loggedAtMetaLabel(
  BuildContext context,
  AppLocalizations l10n,
  MaterialLocalizations material,
  DateTime loggedAt,
) {
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(loggedAt),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${_loggedDayLabel(context, l10n, material, loggedAt)}, $timeLabel';
}

Color _ingredientAccentColor(int index) {
  const palette = <Color>[
    Color(0xFF0F7A52),
    Color(0xFF67DEA8),
    Color(0xFF8AF5C5),
    Color(0xFFFFA271),
  ];
  return palette[index % palette.length];
}

String _consumedAmountLabel(AppLocalizations l10n, CalorieEntry entry) {
  if (entry.isBundle) {
    return l10n.caloriesBundlePortions(
      formatPreparedMealPortions(entry.bundleConsumedPortions ?? 0),
      entry.bundleTotalPortions ?? 0,
    );
  }

  return '${_formatNutritionMetricValue(entry.consumedAmount)} '
      '${entry.consumedUnit.localizedName(l10n)}';
}

String _formatNutritionMetricValue(double value) {
  final hasFraction = value % 1 != 0;
  return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
