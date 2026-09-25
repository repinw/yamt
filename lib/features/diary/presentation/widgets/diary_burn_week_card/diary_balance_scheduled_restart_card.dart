import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shown in place of the daily balance when a failed run is scheduled to
/// restart later. Like the balance, it has no card frame.
class DiaryBalanceScheduledRestartCard extends StatelessWidget {
  /// Creates a scheduled restart card.
  const new({required this.scheduledRestartDate, super.key});

  /// Date when Burn Week restarts.
  final DateTime scheduledRestartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.favorite_border_rounded, color: colors.error, size: 34),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.burnWeekRunOverTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: AppFonts.display,
              color: colors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.burnWeekRunRestartsOn(dateFormat.format(scheduledRestartDate)),
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
