import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions_menu.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/diary/application/diary_burn_week_run_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_heart_counter_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Home-shell top chrome for the diary tab.
class DiaryHomeShellTopChrome extends ConsumerWidget {
  /// Creates diary top chrome.
  const DiaryHomeShellTopChrome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final diaryCalendarState = ref.watch(diaryCalendarControllerProvider);
    final runState = ref.watch(diaryBurnWeekRunStateProvider).value;
    return HomeShellTabTopChrome(
      title: diaryCalendarState.isSelectedToday
          ? l10n.diaryTodayTitle
          : calendarWeekdayFullLabel(
              diaryCalendarState.selectedDay,
              localeName,
            ),
      subtitle: formatCalendarHeaderDate(
        diaryCalendarState.selectedDay,
        localeName,
      ),
      middle: _DiaryHeartCounter(runState: runState),
      actions: [
        if (kDebugMode) const CalorieDebugActionsMenu(),
        if (!diaryCalendarState.isSelectedToday)
          TextButton(
            onPressed: () {
              ref.read(diaryCalendarControllerProvider.notifier).selectToday();
            },
            child: Text(l10n.diaryTodayTitle),
          ),
      ],
    );
  }
}

class _DiaryHeartCounter extends StatelessWidget {
  const _DiaryHeartCounter({required this.runState});

  final BurnWeekRunState? runState;

  @override
  Widget build(BuildContext context) {
    final state = runState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    return DiaryHeartCounterButton(runState: state);
  }
}
