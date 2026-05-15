import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/metric_card_shell/metric_card_shell.dart';
import 'package:yamt/core/widgets/metric_card_shell/metric_tap_shell.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact diary weight metric card.
class DiaryWeightCard extends ConsumerWidget {
  /// Creates a weight card.
  const DiaryWeightCard({
    required this.data,
    required this.selectedDay,
    required this.isExpanded,
    required this.onToggleExpanded,
    super.key,
  });

  /// Loaded activity and weight data.
  final DiaryActivityWeightData data;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Whether the detail panel is expanded.
  final bool isExpanded;

  /// Toggles the detail panel.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final weightFormat = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toLanguageTag(),
    );
    final accentColors = MetricAccentColors.of(context);
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    final dismissalController = ref.read(
      diaryWeightPromptDismissalControllerProvider.notifier,
    );
    final dismissedDayKey = ref.watch(
      diaryWeightPromptDismissalControllerProvider,
    );
    final weightActions = ref.watch(diaryWeightActionsProvider);
    final showWeightWarning =
        !data.hasSelectedDayWeight &&
        dismissedDayKey != diaryDayKey(normalizedSelectedDay);

    if (showWeightWarning) {
      return DiaryWeightMissingPromptCard(
        onTrack: () => unawaited(
          showDiaryWeightDialog(
            context: context,
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            day: normalizedSelectedDay,
            initialWeightKg: data.selectedWeightKg,
            hasManualWeight: false,
            canClearWeight: false,
            healthSample: null,
          ),
        ),
        onDismiss: () => unawaited(
          dismissalController.dismissForDay(normalizedSelectedDay),
        ),
      );
    }

    final profileWeightKg = data.profileWeightKg;
    return MetricTapShell(
      onTap: onToggleExpanded,
      child: MetricCardShell(
        accentColor: accentColors.weight,
        watermarkIcon: Icons.trending_down_rounded,
        titleIcon: Icons.trending_down_rounded,
        title: l10n.diaryWeightTitle,
        value: data.selectedWeightKg == null
            ? '—'
            : weightFormat.format(data.selectedWeightKg),
        unit: l10n.caloriesUnitKg,
        trend: data.weightTrend,
        footer: profileWeightKg == null
            ? l10n.diarySevenDaysLabel
            : l10n.diaryProfileWeightLabel(
                numberFormat.format(profileWeightKg),
              ),
        periodLabel: l10n.diarySevenDaysLabel,
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.25 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.chevron_right_rounded,
            color: accentColors.weight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
