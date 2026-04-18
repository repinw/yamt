import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/calories_page_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie week balance summary banner.
class CalorieWeekBalanceSummaryBanner extends StatelessWidget {
  /// The calorie week balance summary banner.
  const CalorieWeekBalanceSummaryBanner({
    required this.overview,
    required this.referenceNow,
    super.key,
  });

  /// The overview.
  final CalorieWeekOverview overview;

  /// The reference now.
  final DateTime referenceNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final content = resolveWeekBalanceSummaryBannerContent(
      overview: overview,
      l10n: l10n,
      referenceNow: referenceNow,
      positiveAccentColor: colors.primary,
      warningColor: colors.error,
    );

    return DecoratedBox(
      key: CaloriesPageKeys.weekBalanceSummary,
      decoration: BoxDecoration(
        color: content.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              key: CaloriesPageKeys.weekBalanceSummaryIcon,
              size: 18,
              color: content.accentColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                content.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: content.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
