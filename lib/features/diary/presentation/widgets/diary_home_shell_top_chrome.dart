import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_today_button.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_header_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Height of the bar at normal text: a one-row header, whose tools are
/// [AppSizes.headerTool] tall, with the padding around it. Large text, or a
/// header in two rows, makes the bar taller.
const double _diaryTopChromeMinHeight = 68;
const double _diaryTopChromeVerticalPadding =
    (_diaryTopChromeMinHeight - AppSizes.headerTool) / 2;

/// A count that the shopping badge shows as "99+": its widest look.
const int _widestBadgeCount = 100;

/// Home-shell top chrome for the diary tab: a day navigator above the day
/// pages.
class DiaryHomeShellTopChrome extends StatelessWidget {
  /// Creates diary top chrome.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const _DiaryTopBar(),
    );
  }
}

class _DiaryTopBar extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final bounds = ref.watch(diaryCalendarBoundsProvider);
    DiaryCalendarController controller() =>
        ref.read(diaryCalendarControllerProvider.notifier);
    final compact = shouldUseCompactHomeChrome(context);

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _diaryTopChromeMinHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.xs : AppSpacing.md,
            vertical: _diaryTopChromeVerticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.narrowContentMaxWidth,
              ),
              child: DiaryDayNavigator(
                selectedDay: calendarState.selectedDay,
                today: calendarState.today,
                canGoBack: bounds.canGoBack(calendarState.selectedDay),
                canGoForward: bounds.canGoForward(calendarState.selectedDay),
                onPrevious: () => controller().selectPreviousDay(),
                onNext: () => controller().selectNextDay(),
                onOpenCalendar: () async {
                  final pickedDay = await showDiaryCalendarOverviewSheet(
                    context: context,
                    selectedDay: calendarState.selectedDay,
                    today: calendarState.today,
                    bounds: bounds,
                  );
                  if (pickedDay != null) {
                    controller().selectDay(pickedDay);
                  }
                },
                // The sides keep the room of the widest tool of any day, so
                // the header does not change its rows when the day changes.
                reservedTools: [
                  DiaryTodayButton(onPressed: () {}),
                  HomeHeaderTool(
                    symbol: const Icon(Icons.shopping_cart_rounded),
                    label: AppLocalizations.of(context)!.homeShopping,
                    badgeCount: _widestBadgeCount,
                    onPressed: null,
                  ),
                ],
                leadingActions: const [HomeShellMenuButton()],
                // On another day the Heute button takes Einkauf's place:
                // both do not fit beside the date.
                actions: [
                  if (!isSameCalendarDay(
                    calendarState.selectedDay,
                    calendarState.today,
                  ))
                    DiaryTodayButton(onPressed: () => controller().showToday())
                  else
                    const ShoppingHeaderTool(onlyWithOpenEntries: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
