import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions_menu.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_toggle.dart';

const double _diaryTopChromeMinHeight = 56;
const double _diaryTopChromeLabelLineHeight = 28;
const double _diaryTopChromeVerticalPadding = 28;

/// Home-shell top chrome for the diary tab: a day navigator pinned to the top.
class DiaryHomeShellTopChrome extends StatelessWidget {
  /// Creates diary top chrome.
  const DiaryHomeShellTopChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final scaledLabelHeight = MediaQuery.textScalerOf(
      context,
    ).scale(_diaryTopChromeLabelLineHeight);
    final height = math.max(
      _diaryTopChromeMinHeight,
      scaledLabelHeight + _diaryTopChromeVerticalPadding,
    );
    return SliverPersistentHeader(
      pinned: true,
      delegate: _DiaryPinnedTopBarDelegate(
        height: height + MediaQuery.paddingOf(context).top,
        child: _DiaryTopBar(height: height),
      ),
    );
  }
}

class _DiaryPinnedTopBarDelegate extends SliverPersistentHeaderDelegate {
  const _DiaryPinnedTopBarDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Opaque surface so scrolled content never shows through the bar.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _DiaryPinnedTopBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _DiaryTopBar extends ConsumerWidget {
  const _DiaryTopBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final bounds = ref.watch(diaryCalendarBoundsProvider);
    final controller = ref.read(diaryCalendarControllerProvider.notifier);
    final compact = shouldUseCompactHomeChrome(context);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.xs : AppSpacing.md,
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
                onPrevious: controller.selectPreviousDay,
                onNext: controller.selectNextDay,
                onOpenCalendar: () async {
                  final pickedDay = await showDiaryCalendarOverviewSheet(
                    context: context,
                    selectedDay: calendarState.selectedDay,
                    today: calendarState.today,
                    bounds: bounds,
                  );
                  if (pickedDay != null) {
                    controller.selectDay(pickedDay);
                  }
                },
                actions: const [
                  DiaryDayTypeToggle(),
                  if (kDebugMode) CalorieDebugActionsMenu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
