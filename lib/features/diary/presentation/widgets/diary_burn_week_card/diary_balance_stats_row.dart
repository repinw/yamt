import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_stat_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eaten and left stat tiles for the loaded Burn Week balance card.
class DiaryBalanceStatsRow extends StatelessWidget {
  /// Creates a loaded balance stats row.
  const DiaryBalanceStatsRow({
    required this.eatenValue,
    required this.leftValue,
    this.eatenSubtitle,
    this.leftSubtitle,
    super.key,
  });

  /// Eaten value label.
  final String eatenValue;

  /// Left value label.
  final String leftValue;

  /// Optional eaten subtitle.
  final String? eatenSubtitle;

  /// Optional left subtitle.
  final String? leftSubtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eatenValueColor = isDark
        ? const Color(0xFFBFDBFE)
        : const Color(0xFF2E4A79);
    final leftGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF047857), Color(0xFF065F46)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1FA86A), Color(0xFF168955)],
          );

    return Row(
      children: [
        Expanded(
          child: DiaryBalanceStatTile(
            label: l10n.diaryBalanceEatenLabel,
            value: eatenValue,
            subtitle: eatenSubtitle,
            style: DiaryBalanceStatTileStyle.eaten(
              isDark: isDark,
              valueColor: eatenValueColor,
              subtitleColor: colors.onSurfaceVariant,
              backgroundColor: isDark
                  ? colors.surfaceContainerLowest
                  : Colors.white,
              borderColor: isDark
                  ? colors.outlineVariant
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DiaryBalanceStatTile(
            label: l10n.diaryBalanceLeftLabel,
            value: leftValue,
            subtitle: leftSubtitle,
            style: DiaryBalanceStatTileStyle.left(
              gradient: leftGradient,
            ),
          ),
        ),
      ],
    );
  }
}
