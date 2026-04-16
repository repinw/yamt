import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_product_selection_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The inventory barcode candidate sheet key.
const inventoryBarcodeCandidateSheetKey = Key(
  'inventory_barcode_candidate_sheet',
);

/// Defines inventory barcode candidate picker sheet.
class InventoryBarcodeCandidatePickerSheet extends StatelessWidget {
  /// The inventory barcode candidate picker sheet.
  const InventoryBarcodeCandidatePickerSheet({
    required this.candidates,
    required this.onSelect,
    super.key,
  });

  /// The candidates.
  final List<InventoryBarcodeLookupCandidate> candidates;

  /// The on select.
  final ValueChanged<InventoryBarcodeLookupCandidate> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: DecoratedBox(
        key: inventoryBarcodeCandidateSheetKey,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _BarcodeCandidatePickerHeader(
                title: l10n.inventoryManualAddCandidateTitle,
                subtitle: l10n.inventoryManualAddCandidateSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return _BarcodeCandidateTile(
                      candidate: candidate,
                      onTap: () => onSelect(candidate),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeCandidatePickerHeader extends StatelessWidget {
  const _BarcodeCandidatePickerHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xxs * 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _close(context),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  void _close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop();
      return;
    }
    Navigator.of(context).pop();
  }
}

class _BarcodeCandidateTile extends StatelessWidget {
  const _BarcodeCandidateTile({required this.candidate, required this.onTap});

  final InventoryBarcodeLookupCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brand = candidate.brand?.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InventoryReceiptSelectionThumbnail(
                imageUrl: candidate.imageUrl,
                icon: Icons.inventory_2_outlined,
                dimension: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _BarcodeCandidateSourceTag(candidate: candidate),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      candidate.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (brand != null && brand.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs * 2),
                      Text(
                        brand,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs * 2),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.inventoryManualAddUnknownBrand,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_showsCandidateMetadata(candidate)) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      _BarcodeCandidateMetadata(candidate: candidate),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  bool _showsCandidateMetadata(InventoryBarcodeLookupCandidate candidate) {
    return (candidate.packageWeight?.trim().isNotEmpty ?? false) ||
        candidate.nutrition != null;
  }
}

class _BarcodeCandidateMetadata extends StatelessWidget {
  const _BarcodeCandidateMetadata({required this.candidate});

  final InventoryBarcodeLookupCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final nutrition = candidate.nutrition;
    if (nutrition != null) {
      return InventoryReceiptNutritionChips(
        leadingLabel: candidate.packageWeight,
        nutrition: nutrition,
      );
    }

    final packageWeight = candidate.packageWeight?.trim();
    if (packageWeight == null || packageWeight.isEmpty) {
      return const SizedBox.shrink();
    }

    return _BarcodeCandidateTag(label: packageWeight);
  }
}

class _BarcodeCandidateSourceTag extends StatelessWidget {
  const _BarcodeCandidateSourceTag({required this.candidate});

  final InventoryBarcodeLookupCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        candidate.source == InventoryBarcodeLookupCandidateSource.learned
        ? l10n.inventoryManualAddCandidateSourceLearned
        : l10n.inventoryManualAddCandidateSourceOff;
    return Align(
      alignment: Alignment.centerLeft,
      child: _BarcodeCandidateTag(label: label),
    );
  }
}

class _BarcodeCandidateTag extends StatelessWidget {
  const _BarcodeCandidateTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
