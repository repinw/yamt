import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventorySectionHeader extends StatelessWidget {
  const InventorySectionHeader({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inventoryListSectionTitle.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.inventoryListSectionTitle,
                style: textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              itemCount.toString(),
              style: textTheme.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InventoryControlsCard extends StatelessWidget {
  const InventoryControlsCard({
    super.key,
    required this.itemCount,
    required this.modeToggle,
    required this.consumptionToggle,
  });

  final int itemCount;
  final Widget modeToggle;
  final Widget consumptionToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppInventoryEditorial.glassBlur,
          sigmaY: AppInventoryEditorial.glassBlur,
        ),
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.glassCardDecoration(
            colors,
            borderRadius: cardRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventorySectionHeader(itemCount: itemCount),
                const SizedBox(height: AppSpacing.xxl),
                modeToggle,
                const SizedBox(height: AppSpacing.md),
                consumptionToggle,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({
    super.key,
    required this.items,
    required this.currency,
  });

  final List<InventoryItem> items;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);
    final totalEntries = items.length;
    final totalQuantity = items.fold<int>(0, (sum, item) {
      return sum + item.quantity;
    });
    final totalValue = items.fold<double>(0, (sum, item) {
      return sum + (item.quantity * item.unitPrice);
    });
    final onHero = colors.onPrimary;
    final mutedOnHero = onHero.withValues(alpha: 0.8);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.soulGradient(colors),
        borderRadius: cardRadius,
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 48,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl,
          AppSpacing.xxxl,
          AppSpacing.xxxxl,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventorySummaryTitle.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(color: mutedOnHero),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              totalEntries.toString(),
              style: textTheme.displaySmall?.copyWith(color: onHero),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.inventoryListSectionTitle,
              style: textTheme.headlineSmall?.copyWith(
                color: onHero,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _InventoryMetricCard(
                  label: l10n.inventorySummaryQuantity,
                  value: totalQuantity.toString(),
                  foregroundColor: onHero,
                ),
                _InventoryMetricCard(
                  label: l10n.inventorySummaryEstimatedValue,
                  value: currency.format(totalValue),
                  foregroundColor: onHero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final emptyStateMessage = message ?? l10n.inventoryEmptyState;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Icon(
                  Icons.kitchen_outlined,
                  size: AppSizes.welcomeIcon * 0.42,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              emptyStateMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryMetricCard extends StatelessWidget {
  const _InventoryMetricCard({
    required this.label,
    required this.value,
    required this.foregroundColor,
  });

  final String label;
  final String value;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: foregroundColor.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
