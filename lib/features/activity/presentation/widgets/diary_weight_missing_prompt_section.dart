import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_prompt_dismissal_controller.dart';

/// Missing-weight prompt for [day] without the weight metrics around it.
///
/// Shows nothing while the weight loads, once [day] has a weight, or after
/// the user dismissed the prompt for [day].
class DiaryWeightMissingPromptSection extends ConsumerWidget {
  /// Creates the missing-weight prompt for [day].
  const new({required this.day, super.key});

  /// Diary day that needs a weight.
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDay = normalizeLocalDay(day);
    final dismissedDayKey = ref.watch(
      diaryWeightPromptDismissalControllerProvider,
    );
    if (dismissedDayKey == localDayKey(normalizedDay)) {
      return const SizedBox.shrink();
    }

    return ref
        .watch(diaryActivityWeightDataProvider(normalizedDay))
        .when(
          data: (data) => data.hasSelectedDayWeight
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: DiaryWeightMissingPromptCard(
                    onTrack: () => unawaited(
                      ref
                          .read(diaryWeightTrackingFlowProvider)
                          .showDialogForDay(
                            context: context,
                            selectedDay: normalizedDay,
                            day: normalizedDay,
                            initialWeightKg: data.selectedWeightKg,
                          ),
                    ),
                    onDismiss: () => unawaited(
                      ref
                          .read(
                            diaryWeightPromptDismissalControllerProvider
                                .notifier,
                          )
                          .dismissForDay(normalizedDay),
                    ),
                  ),
                ),
          // The prompt is optional, so a failed load hides it. The weight
          // section on the Progress tab shows the error with a retry.
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
  }
}
