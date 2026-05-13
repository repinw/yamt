import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card shown when a failed run is scheduled to restart later.
class DiaryBalanceScheduledRestartCard extends StatelessWidget {
  /// Creates a scheduled restart card.
  const DiaryBalanceScheduledRestartCard({
    required this.scheduledRestartDate,
    super.key,
  });

  /// Date when Burn Week restarts.
  final DateTime scheduledRestartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colors = Theme.of(context).colorScheme;

    return DiaryBalanceShell(
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: colors.error,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.burnWeekRunOverTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.burnWeekRunRestartsOn(
              dateFormat.format(scheduledRestartDate),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
