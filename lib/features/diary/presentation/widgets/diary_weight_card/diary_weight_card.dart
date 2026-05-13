import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_today_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/diary/application/diary_activity_weight_service.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_metric_card_shell/diary_metric_card_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_metric_card_shell/diary_metric_tap_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_actions.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_missing_prompt_card.dart';
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
    final accentColors = DiaryAccentColors.of(context);
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    final dismissalController = ref.read(
      calorieTodayWeightPromptDismissalControllerProvider.notifier,
    );
    final dismissedDayKey = ref.watch(
      calorieTodayWeightPromptDismissalControllerProvider,
    );
    final weightActions = ref.read(diaryWeightActionsProvider);
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
    return DiaryMetricTapShell(
      onTap: onToggleExpanded,
      child: DiaryMetricCardShell(
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
