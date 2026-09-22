import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/value_animation_handoff.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_placeholder.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_resting_day_gate.dart';

const Curve _dayPageAnimationCurve = Curves.easeOutCubic;

/// Horizontal pages with one [DiaryDayView] per selectable diary day.
///
/// Swiping selects the neighbouring day as soon as more than half of it
/// shows, so the day navigator follows the finger. When the day is selected
/// elsewhere, such as with the arrows or the calendar, the pages follow.
///
/// The pages next to the resting page are built ahead, so a swipe only moves
/// finished pages. Pages farther away, which the pager also keeps ready, show
/// a [DiaryDayPlaceholder] until the pager rests next to them. Building a
/// whole day while the finger moves would stall the swipe.
///
/// Only the selected day counts as visible for its bar animations. The bars
/// of the other days wait at the values the selected day shows and, once
/// their day is selected, animate from there to their own values.
class DiaryDayPager extends ConsumerStatefulWidget {
  /// Creates the day pager.
  const new({required this.showMacroStrip, super.key});

  /// Whether each day shows the compact macro strip.
  final bool showMacroStrip;

  @override
  ConsumerState<DiaryDayPager> createState() => _DiaryDayPagerState();
}

class _DiaryDayPagerState extends ConsumerState<DiaryDayPager> {
  late final PageController _pageController;

  /// Shared by the day pages so the weekly check-in section exists once.
  final GlobalKey _weeklyCheckInKey = GlobalKey();

  /// Page the pager last came to rest on, or is settling on after the finger
  /// lifted.
  late final ValueNotifier<int> _restingPage;

  /// Whether the last page movement came from a finger.
  var _isDragging = false;

  /// Hands the bar values of one day to the next selected day.
  final ValueAnimationHandoff _barHandoff = ValueAnimationHandoff();

  @override
  void initState() {
    super.initState();
    final bounds = ref.read(diaryCalendarBoundsProvider);
    final selectedDay = ref.read(diaryCalendarControllerProvider).selectedDay;
    final initialPage = bounds.indexOf(selectedDay);
    _pageController = PageController(initialPage: initialPage);
    _restingPage = ValueNotifier(initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _restingPage.dispose();
    _barHandoff.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounds = ref.watch(diaryCalendarBoundsProvider);
    ref
      ..listen(
        diaryCalendarControllerProvider.select((state) => state.selectedDay),
        (_, _) => _showSelectedDay(animate: true),
      )
      // Moving the earliest day shifts every index, so the page jumps.
      ..listen(diaryCalendarBoundsProvider, (previous, next) {
        if (previous?.earliestDay != next.earliestDay) {
          _showSelectedDay(animate: false);
        }
      });

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Deeper notifications come from the vertical scroll of a day.
        if (notification.depth == 0) {
          _trackRelease(notification);
          if (notification is ScrollEndNotification) {
            _restOnSettledPage();
          }
        }
        return false;
      },
      child: ValueAnimationHandoffScope(
        handoff: _barHandoff,
        child: PageView.builder(
          controller: _pageController,
          itemCount: bounds.dayCount,
          allowImplicitScrolling: true,
          onPageChanged: (index) => ref
              .read(diaryCalendarControllerProvider.notifier)
              .selectDay(bounds.dayAt(index)),
          itemBuilder: (context, index) => _SelectedDayVisibility(
            day: bounds.dayAt(index),
            child: DiaryRestingDayGate(
              index: index,
              restingPage: _restingPage,
              child: DiaryDayView(
                day: bounds.dayAt(index),
                showMacroStrip: widget.showMacroStrip,
                weeklyCheckInKey: _weeklyCheckInKey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Moves the resting page to the page the pager settles on as soon as the
  /// finger lifts. The day after it is then built during the settle
  /// animation, while no finger is down, instead of on the next swipe.
  void _trackRelease(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _isDragging = false;
    }
    if (notification is! ScrollUpdateNotification) {
      return;
    }
    if (notification.dragDetails != null) {
      _isDragging = true;
      return;
    }
    final delta = notification.scrollDelta;
    final page = _pageController.page;
    if (!_isDragging || delta == null || delta == 0 || page == null) {
      return;
    }
    _isDragging = false;
    // The settle animation runs towards the page it is heading to.
    _restingPage.value = delta > 0 ? page.ceil() : page.floor();
  }

  /// Marks the page the pager came to rest on as the resting page.
  ///
  /// A touch during the settle animation also ends it. Waiting a frame and
  /// skipping while the next swipe runs keeps the build of the next day out
  /// of that swipe, whose speed would otherwise be misread.
  void _restOnSettledPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final page = _pageController.hasClients ? _pageController.page : null;
      if (!mounted ||
          page == null ||
          _pageController.position.isScrollingNotifier.value) {
        return;
      }
      _restingPage.value = page.round();
    });
  }

  /// Moves the pages to the selected day once the new page count is laid
  /// out.
  ///
  /// Never moves them while the user swipes or a page settles, since the
  /// swipe selects its own day.
  void _showSelectedDay({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_pageController.hasClients ||
          _pageController.position.isScrollingNotifier.value) {
        return;
      }
      final bounds = ref.read(diaryCalendarBoundsProvider);
      final target = bounds.indexOf(
        ref.read(diaryCalendarControllerProvider).selectedDay,
      );
      final current = _pageController.page?.round();
      if (current == target) {
        return;
      }
      if (animate && current != null && (current - target).abs() == 1) {
        _pageController.animateToPage(
          target,
          duration: AppDurations.diaryDayPageSlide,
          curve: _dayPageAnimationCurve,
        );
      } else {
        // Show the full day right away instead of its placeholder.
        _restingPage.value = target;
        _pageController.jumpToPage(target);
      }
    });
  }
}

/// Lets the bar animations of [day] run only while it is the selected day.
///
/// [child] keeps its identity, so selecting another day only notifies the
/// animations below instead of rebuilding the page.
class _SelectedDayVisibility extends ConsumerWidget {
  const new({required this.day, required this.child});

  final DateTime day;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      diaryCalendarControllerProvider.select(
        (state) => isSameCalendarDay(state.selectedDay, day),
      ),
    );
    return ContentVisibility(
      isVisible: isSelected && ContentVisibility.of(context),
      child: child,
    );
  }
}
