import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
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
class DiaryDayPager extends ConsumerStatefulWidget {
  /// Creates the day pager.
  const new({super.key});

  @override
  ConsumerState<DiaryDayPager> createState() => _DiaryDayPagerState();
}

class _DiaryDayPagerState extends ConsumerState<DiaryDayPager> {
  /// Shared by the day pages so the weekly check-in section exists once.
  final GlobalKey _weeklyCheckInKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bounds = ref.watch(diaryCalendarBoundsProvider);
    // Moving the earliest day shifts every index, so new pages start on the
    // selected day. Jumping the old pages there stopped at their last page
    // while Flutter had not laid out the new page count yet, and that page
    // selected the wrong day (#817).
    return _DayPages(
      key: ValueKey(bounds.earliestDay),
      bounds: bounds,
      weeklyCheckInKey: _weeklyCheckInKey,
    );
  }
}

/// The pages of [bounds], starting on the selected day.
class _DayPages extends ConsumerStatefulWidget {
  const new({required this.bounds, required this.weeklyCheckInKey, super.key});

  /// Page 0 shows their earliest day.
  final DiaryCalendarBounds bounds;
  final GlobalKey weeklyCheckInKey;

  @override
  ConsumerState<_DayPages> createState() => _DayPagesState();
}

class _DayPagesState extends ConsumerState<_DayPages> {
  late final PageController _pageController;

  /// Page the pager last came to rest on, or is settling on after the finger
  /// lifted.
  late final ValueNotifier<int> _restingPage;

  /// Whether the last page movement came from a finger.
  var _isDragging = false;

  /// Whether the pages themselves select a day right now.
  var _pageSelectsDay = false;

  /// Whether a day selected elsewhere waits for the pages to move to it.
  /// Until then a running slide or settle must not select its own day
  /// again, or it would undo the newer one (#920).
  var _selectedDayWaits = false;

  @override
  void initState() {
    super.initState();
    final bounds = widget.bounds;
    final selectedDay = ref.read(diaryCalendarControllerProvider).selectedDay;
    final initialPage = bounds.indexOf(bounds.clamp(selectedDay));
    _pageController = PageController(initialPage: initialPage);
    _restingPage = ValueNotifier(initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _restingPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    ref.listen(
      diaryCalendarControllerProvider.select((state) => state.selectedDay),
      (_, _) {
        if (!_pageSelectsDay) {
          _selectedDayWaits = true;
          // The frame after it clears the wait, so a swipe selects again.
          WidgetsBinding.instance.ensureVisualUpdate();
        }
        _showSelectedDay();
      },
    );

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
      child: PageView.builder(
        controller: _pageController,
        itemCount: bounds.dayCount,
        allowImplicitScrolling: true,
        onPageChanged: (index) {
          if (_selectedDayWaits) return;
          _pageSelectsDay = true;
          try {
            ref
                .read(diaryCalendarControllerProvider.notifier)
                .selectDay(bounds.dayAt(index));
          } finally {
            _pageSelectsDay = false;
          }
        },
        itemBuilder: (context, index) => DiaryRestingDayGate(
          index: index,
          restingPage: _restingPage,
          child: DiaryDayView(
            day: bounds.dayAt(index),
            weeklyCheckInKey: widget.weeklyCheckInKey,
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

  /// Moves the pages to the selected day after the frame.
  ///
  /// While the diary shows, never moves them while the user swipes or while
  /// the pages slide or settle on a day they selected themselves. A day
  /// selected elsewhere, such as today from the „Heute“ button, takes over a
  /// running slide or settle, or it would end on the old day (#920).
  void _showSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final takesOver = _selectedDayWaits;
      _selectedDayWaits = false;
      // A hidden diary (another tab, a page on top) jumps, also during a
      // slide: its muted ticker would hold the slide until it shows and then
      // undo a newer day (#753).
      final isVisible = mounted && TickerMode.valuesOf(context).enabled;
      final isScrolling =
          _pageController.hasClients &&
          _pageController.position.isScrollingNotifier.value;
      if (!mounted ||
          !_pageController.hasClients ||
          (isVisible && (_isDragging || (isScrolling && !takesOver)))) {
        return;
      }
      // Bounds that moved while the diary was hidden start new pages on the
      // selected day once it shows.
      final bounds = widget.bounds;
      final selectedDay = ref.read(diaryCalendarControllerProvider).selectedDay;
      if (!bounds.contains(selectedDay)) {
        return;
      }
      final target = bounds.indexOf(selectedDay);
      // A slide stops even on the target, or it would go on later.
      final page = _pageController.page;
      if (page == target && !isScrolling) {
        return;
      }
      final current = page?.round();
      if (isVisible && current != null && (current - target).abs() == 1) {
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
