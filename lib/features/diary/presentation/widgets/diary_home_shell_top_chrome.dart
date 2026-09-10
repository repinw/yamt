import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions_menu.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_toggle.dart';
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
      middle: const DiaryDayTypeToggle(),
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
