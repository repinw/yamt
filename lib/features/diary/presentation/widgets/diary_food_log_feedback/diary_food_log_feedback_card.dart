import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_food_log_feedback/diary_food_log_feedback_macro_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A dismissible, accessible summary of confirmed food additions.
class DiaryFoodLogFeedbackCard extends StatefulWidget {
  /// Creates a card; the host provides its position above navigation.
  const DiaryFoodLogFeedbackCard({
    required this.feedback,
    required this.onDismiss,
    super.key,
  });

  /// Confirmed food and optional daily context.
  final DiaryFoodLogFeedback feedback;

  /// Advances the queue or closes the feedback.
  final VoidCallback onDismiss;

  @override
  State<DiaryFoodLogFeedbackCard> createState() =>
      _DiaryFoodLogFeedbackCardState();
}

class _DiaryFoodLogFeedbackCardState extends State<DiaryFoodLogFeedbackCard> {
  Timer? _timer;
  bool? _persistent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final persistent = MediaQuery.accessibleNavigationOf(context);
    if (_persistent == persistent) return;
    _persistent = persistent;
    _timer?.cancel();
    if (!persistent) {
      _timer = Timer(const Duration(seconds: 5), widget.onDismiss);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final l10n = AppLocalizations.of(context)!;
    final colors = MetricAccentColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final format = NumberFormat.decimalPattern(locale);
    final kcal = feedback.totalKcal;
    final protein = feedback.totalProtein;
    final carbs = feedback.totalCarbs;
    final fat = feedback.totalFat;
    final after = feedback.after;
    final before = feedback.before;
    final rows = [
      (
        l10n.caloriesProteinLabel,
        protein,
        after?.protein,
        before?.protein,
        after?.goals.protein,
        colors.protein,
      ),
      (
        l10n.caloriesCarbsLabel,
        carbs,
        after?.carbs,
        before?.carbs,
        after?.goals.carbs,
        colors.carbs,
      ),
      (
        l10n.caloriesFatLabel,
        fat,
        after?.fat,
        before?.fat,
        after?.goals.fat,
        colors.fat,
      ),
    ];
    return Material(
      key: const ValueKey('diary-food-log-feedback'),
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        feedback.entries.length == 1
                            ? '${l10n.diaryFoodLogged}: '
                                  '${feedback.entries.single.name}'
                            : l10n.diaryFoodsLoggedCount(
                                feedback.entries.length,
                              ),
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('diary-food-log-feedback-close'),
                    tooltip: l10n.diaryFoodFeedbackClose,
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${DateFormat.yMMMd(locale).format(feedback.day)} · '
                        '+${format.format(kcal.round())} '
                        '${l10n.caloriesUnitKcal}',
                      ),
                      for (final (
                            label,
                            added,
                            current,
                            previous,
                            target,
                            color,
                          )
                          in rows)
                        DiaryFoodLogFeedbackMacroRow(
                          label: label,
                          added: added,
                          current: current,
                          previous: previous,
                          startedAt: feedback.startedAt,
                          target: target,
                          color: color,
                          numberFormat: format,
                          unit: l10n.caloriesUnitGram,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
