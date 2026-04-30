import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_product_selection_widgets.dart';
import 'package:yamt/features/product_search/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom sheet that lets the user choose a matching global food item.
enum ReceiptCandidatePickerSelectionKind {
  /// Documented member.
  candidate,

  /// Documented member.
  manualEntry,

  /// Documented member.
  aiEnrichment,
}

/// Defines receipt candidate picker selection.
class ReceiptCandidatePickerSelection {
  const ReceiptCandidatePickerSelection._({
    required this.kind,
    this.candidateId,
  });

  /// Creates a [ReceiptCandidatePickerSelection] for candidate.
  const ReceiptCandidatePickerSelection.candidate(String candidateId)
    : this._(
        kind: ReceiptCandidatePickerSelectionKind.candidate,
        candidateId: candidateId,
      );

  /// Creates a [ReceiptCandidatePickerSelection] for manual entry.
  const ReceiptCandidatePickerSelection.manualEntry()
    : this._(kind: ReceiptCandidatePickerSelectionKind.manualEntry);

  /// Creates a [ReceiptCandidatePickerSelection] for ai enrichment.
  const ReceiptCandidatePickerSelection.aiEnrichment()
    : this._(kind: ReceiptCandidatePickerSelectionKind.aiEnrichment);

  /// The kind.
  final ReceiptCandidatePickerSelectionKind kind;

  /// The candidate id.
  final String? candidateId;
}

/// Defines inventory receipt candidate picker sheet.
class InventoryReceiptCandidatePickerSheet extends StatelessWidget {
  /// The inventory receipt candidate picker sheet.
  const InventoryReceiptCandidatePickerSheet({
    required this.draft,
    super.key,
    this.showAiEnrichmentAction = true,
  });

  /// The draft.
  final ReceiptReviewItemDraft draft;

  /// The show ai enrichment action.
  final bool showAiEnrichmentAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CandidatePickerHeader(draft: draft),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in draft.candidates) ...[
                    _CandidatePickerTile(
                      candidate: candidate,
                      isSelected:
                          draft.selectedGlobalFoodItemId == candidate.item.id,
                      onTap: () => Navigator.of(context).pop(
                        ReceiptCandidatePickerSelection.candidate(
                          candidate.item.id,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _FallbackSelectionTile(
                    icon: Icons.edit_note,
                    isSelected:
                        draft.selectedGlobalFoodItemId == null &&
                        !draft.requestAiEnrichment,
                    onTap: () {
                      Navigator.of(context).pop(
                        const ReceiptCandidatePickerSelection.manualEntry(),
                      );
                    },
                    title: l10n.inventoryReceiptReviewManualDataAction,
                    subtitle: l10n.inventoryReceiptReviewManualDataHint,
                  ),
                  if (showAiEnrichmentAction) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _FallbackSelectionTile(
                      icon: Icons.auto_awesome,
                      isSelected: draft.requestAiEnrichment,
                      onTap: () {
                        Navigator.of(context).pop(
                          const ReceiptCandidatePickerSelection.aiEnrichment(),
                        );
                      },
                      title: l10n.inventoryReceiptReviewRequestEnrichmentAction,
                      subtitle:
                          l10n.inventoryReceiptReviewRequestEnrichmentHint,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidatePickerHeader extends StatelessWidget {
  const _CandidatePickerHeader({required this.draft});

  final ReceiptReviewItemDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inventoryReceiptReviewProductSelectionLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xxs * 2),
              Text(
                _sourceLabel(l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  String _sourceLabel(AppLocalizations l10n) {
    final ocrName = draft.ocrName?.trim();
    if (ocrName != null && ocrName.isNotEmpty) {
      return '${l10n.inventoryReceiptReviewReadAsPrefix}: "$ocrName"';
    }
    return draft.item.name;
  }
}

class _CandidatePickerTile extends StatelessWidget {
  const _CandidatePickerTile({
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  final GlobalFoodMatchCandidate candidate;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = isSelected ? colors.primary : colors.outlineVariant;
    final background = isSelected
        ? colors.primaryContainer.withValues(alpha: 0.35)
        : colors.surface;
    final item = candidate.item;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InventoryReceiptSelectionThumbnail(
                imageUrl: item.imageUrl,
                dimension: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (item.brand case final String brand
                        when brand.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs * 2),
                      Text(
                        brand,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (item.nutrition?.hasAnyNutritionValue ?? false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      InventoryReceiptNutritionChips(
                        leadingLabel: item.packageWeight,
                        nutrition: item.nutrition!,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackSelectionTile extends StatelessWidget {
  const _FallbackSelectionTile({
    required this.isSelected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isSelected
        ? colors.primaryContainer.withValues(alpha: 0.35)
        : colors.surface;
    final borderColor = isSelected ? colors.primary : colors.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(icon, color: colors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
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
