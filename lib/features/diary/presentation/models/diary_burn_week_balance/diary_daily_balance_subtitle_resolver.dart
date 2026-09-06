import 'package:intl/intl.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Subtitle resolution result containing formatted text and individual parts.
typedef DiaryDailyBalanceSubtitleResult =
    ({String? text, List<DiaryDailyBalanceSubtitlePart> parts});

/// Resolves the subtitle text and components for a daily balance card.
DiaryDailyBalanceSubtitleResult resolveDiaryDailyBalanceSubtitle({
  required bool isFutureDay,
  required bool isHeartDay,
  required DiaryDailyBalanceMetrics metrics,
  required NumberFormat numberFormat,
  required AppLocalizations l10n,
}) {
  if (isFutureDay) {
    return _resolveFutureSubtitle(metrics, numberFormat, l10n);
  }
  if (isHeartDay) {
    return (
      text: l10n.diaryBalanceHeartDaySubtitle,
      parts: const <DiaryDailyBalanceSubtitlePart>[],
    );
  }
  if (metrics.heartAdjustmentKcal.round() != 0) {
    return _resolveHeartAdjustmentSubtitle(metrics, numberFormat, l10n);
  }
  return _buildSubtitleAdjustments(metrics, numberFormat, l10n);
}

DiaryDailyBalanceSubtitleResult _resolveFutureSubtitle(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) {
  if (metrics.carryoverKcal.round() != 0) {
    final formatted = formatDiarySignedKcal(
      metrics.carryoverKcal,
      numberFormat,
      l10n.caloriesUnitKcal,
    );
    return (
      text: l10n.diaryBalanceCarryoverShort(formatted),
      parts: const <DiaryDailyBalanceSubtitlePart>[],
    );
  }
  return (text: null, parts: const <DiaryDailyBalanceSubtitlePart>[]);
}

DiaryDailyBalanceSubtitleResult _resolveHeartAdjustmentSubtitle(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) {
  final realLeft = formatDiaryKcal(
    numberFormat,
    metrics.realDayLeftKcal,
    l10n.caloriesUnitKcal,
  );
  final adjustment = formatDiarySignedKcal(
    metrics.heartAdjustmentKcal,
    numberFormat,
    l10n.caloriesUnitKcal,
  );
  final text = '${l10n.diaryBalanceRealLeftLabel(realLeft)} · '
      '${l10n.diaryBalanceHeartAdjustmentLabel(adjustment)}';
  return (text: text, parts: const <DiaryDailyBalanceSubtitlePart>[]);
}

DiaryDailyBalanceSubtitleResult _buildSubtitleAdjustments(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) {
  final parts = <DiaryDailyBalanceSubtitlePart>[
    if (metrics.baseGoalKcal.round() > 0)
      _buildBaseGoalPart(metrics, numberFormat, l10n),
    if (metrics.carryoverKcal.round() != 0)
      _buildCarryoverPart(metrics, numberFormat, l10n),
    if (metrics.activitySegmentKcal.round() > 0)
      _buildSportPart(metrics, numberFormat, l10n),
  ];
  final text = parts.isEmpty
      ? null
      : parts.map((part) => '${part.label} ${part.value}').join(' · ');
  return (text: text, parts: parts);
}

DiaryDailyBalanceSubtitlePart _buildBaseGoalPart(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) {
  final hasOtherAdjustments =
      metrics.carryoverKcal.round() != 0 ||
      metrics.activitySegmentKcal.round() > 0;
  final baseValue = hasOtherAdjustments
      ? numberFormat.format(metrics.baseGoalKcal.round())
      : formatDiaryKcal(
          numberFormat,
          metrics.baseGoalKcal,
          l10n.caloriesUnitKcal,
        );
  return (
    label: l10n.diaryBalanceBaseGoalShort('').trim(),
    value: baseValue,
    type: DiaryDailyBalanceSubtitleType.base,
  );
}

DiaryDailyBalanceSubtitlePart _buildCarryoverPart(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) => (
  label: l10n.diaryBalanceCarryoverShort('').trim(),
  value: formatDiarySignedKcal(metrics.carryoverKcal, numberFormat, '').trim(),
  type: DiaryDailyBalanceSubtitleType.carryover,
);

DiaryDailyBalanceSubtitlePart _buildSportPart(
  DiaryDailyBalanceMetrics metrics,
  NumberFormat numberFormat,
  AppLocalizations l10n,
) => (
  label: l10n.diaryBalanceSportShort('').trim(),
  value: formatDiarySignedKcal(
    metrics.activitySegmentKcal,
    numberFormat,
    '',
  ).trim(),
  type: DiaryDailyBalanceSubtitleType.sport,
);
