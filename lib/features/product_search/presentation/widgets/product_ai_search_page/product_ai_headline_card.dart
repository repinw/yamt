import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';

/// Headline summary card for an AI product draft.
class AiHeadlineCard extends StatelessWidget {
  /// Creates an AI headline card.
  const AiHeadlineCard({required this.draft, super.key});

  /// Current AI draft.
  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const Key('manual_product_ai_result_card'),
      width: double.infinity,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (draft.brand case final String brand) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              brand,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AiMetaWrap(
            labels: <String>[
              draft.totalWeightLabel,
              draft.totalKcalRangeLabel,
              '${formatManualProductDouble(draft.defaultKcal)} kcal',
            ],
          ),
        ],
      ),
    );
  }
}

/// Wrap of small metadata chips.
class AiMetaWrap extends StatelessWidget {
  /// Creates metadata chips.
  const AiMetaWrap({required this.labels, super.key});

  /// Labels displayed as chips.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(label),
            ),
          ),
      ],
    );
  }
}
