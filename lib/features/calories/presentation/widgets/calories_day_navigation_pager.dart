import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager_support.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

const _dayNavigationStripHeight = 208.0;
const _dayNavigationPastDayCount = 3650;
const _dayNavigationSnapDuration = Duration(milliseconds: 180);

/// Defines calories day navigation pager.
class CaloriesDayNavigationPager extends ConsumerStatefulWidget {
  /// The calories day navigation pager.
  const CaloriesDayNavigationPager({
    required this.selectedDay,
    required this.visibleWindowEnd,
    required this.goalKcal,
    required this.visibleDaysOverview,
    required this.onSelectDay,
    required this.onWindowSettled,
    super.key,
    this.referenceNow,
  });

  /// The selected day.
  final DateTime selectedDay;

  /// The visible window end.
  final DateTime visibleWindowEnd;

  /// The goal kcal.
  final double goalKcal;

  /// The visible days overview.
  final List<CalorieWeekDayOverview> visibleDaysOverview;

  /// The reference now.
  final DateTime? referenceNow;

  /// The on select day.
  final ValueChanged<DateTime> onSelectDay;

  /// The on window settled.
  final ValueChanged<DateTime> onWindowSettled;

  @override
  ConsumerState<CaloriesDayNavigationPager> createState() =>
      _CaloriesDayNavigationPagerState();
}

class _CaloriesDayNavigationPagerState
    extends ConsumerState<CaloriesDayNavigationPager> {
  final ScrollController _scrollController = ScrollController();

  bool _isPressEnabled = true;
  bool _isSnapping = false;
  Offset? _pointerDownPosition;

  DateTime get _referenceToday {
    final referenceNow = widget.referenceNow ?? DateTime.now();
    return normalizeDiaryDay(referenceNow);
  }

  DateTime get _earliestDay => _referenceToday.subtract(
    const Duration(days: _dayNavigationPastDayCount),
  );

  int get _itemCount => _dayNavigationPastDayCount + 1;

  int get _maxLeftmostIndex => _itemCount - diaryVisibleDayCount;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleDaysByKey = buildPrefetchedCaloriesDayOverviews(
      ref: ref,
      earliestDay: _earliestDay,
      referenceToday: _referenceToday,
      visibleWindowEnd: widget.visibleWindowEnd,
      visibleDaysOverview: widget.visibleDaysOverview,
    );
    final chartMaxKcal = resolveCaloriesDayNavigationChartMaxKcal(
      widget.visibleDaysOverview,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / diaryVisibleDayCount;
        _syncScrollPosition(itemWidth);

        return SizedBox(
          height: _dayNavigationStripHeight,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                return _handleScrollNotification(notification, itemWidth);
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const CaloriesDayNavigationScrollPhysics(),
                itemCount: _itemCount,
                itemExtent: itemWidth,
                itemBuilder: (context, index) {
                  final date = _dayForIndex(index);
                  final cachedOverview = visibleDaysByKey[diaryDayKey(date)];
                  final shouldWatchOverview =
                      cachedOverview != null || _isWithinActiveBuffer(date);
                  final overviewState =
                      cachedOverview == null && shouldWatchOverview
                      ? ref.watch(calorieWeekDayOverviewForDateProvider(date))
                      : null;
                  final overview =
                      cachedOverview ??
                      overviewState?.value ??
                      CalorieWeekDayOverview(
                        date: date,
                        totalKcal: 0,
                        goalKcal: widget.goalKcal,
                        entryCount: 0,
                      );

                  return CaloriesDayNavigationDayTile(
                    day: overview,
                    isToday: isSameDiaryDay(date, _referenceToday),
                    isSelected: isSameDiaryDay(date, widget.selectedDay),
                    chartMaxKcal: chartMaxKcal,
                    onTap: () => widget.onSelectDay(date),
                    isPressEnabled: _isPressEnabled,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    double itemWidth,
  ) {
    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollStartNotification && _isPressEnabled) {
      setState(() {
        _isPressEnabled = false;
      });
      return false;
    }

    if (notification is! ScrollEndNotification || _isSnapping) {
      return false;
    }

    _snapToNearestDay(itemWidth);
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final pointerDownPosition = _pointerDownPosition;
    if (pointerDownPosition == null || !_isPressEnabled) {
      return;
    }

    final delta = (event.position - pointerDownPosition).distance;
    if (delta <= kTouchSlop) {
      return;
    }

    setState(() {
      _isPressEnabled = false;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerDownPosition = null;
    _restorePressIfIdle();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    _restorePressIfIdle();
  }

  void _restorePressIfIdle() {
    if (!shouldRestoreCaloriesDayNavigationPress(
      isSnapping: _isSnapping,
      isPressEnabled: _isPressEnabled,
      scrollController: _scrollController,
    )) {
      return;
    }
    _setInteractionState(isPressEnabled: true);
  }

  void _syncScrollPosition(double itemWidth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _isSnapping) {
        return;
      }

      final targetOffset =
          _leftmostIndexForWindowEnd(widget.visibleWindowEnd) * itemWidth;
      final currentOffset = _scrollController.offset;
      if ((currentOffset - targetOffset).abs() < 0.5) {
        return;
      }
      _scrollController.jumpTo(targetOffset);
    });
  }

  Future<void> _snapToNearestDay(double itemWidth) async {
    if (!_scrollController.hasClients) {
      return;
    }

    final rawIndex = _scrollController.offset / itemWidth;
    final targetLeftmostIndex = rawIndex.round().clamp(0, _maxLeftmostIndex);
    final targetOffset = targetLeftmostIndex * itemWidth;

    setState(() {
      _isSnapping = true;
    });

    await animateCaloriesDayNavigationToTargetIfNeeded(
      scrollController: _scrollController,
      targetOffset: targetOffset,
      duration: _dayNavigationSnapDuration,
    );

    if (!mounted) {
      return;
    }

    final windowEnd = _dayForIndex(
      targetLeftmostIndex + diaryVisibleDayCount - 1,
    );
    widget.onWindowSettled(windowEnd);

    if (!mounted) {
      return;
    }
    _setInteractionState(isPressEnabled: true, isSnapping: false);
  }

  int _leftmostIndexForWindowEnd(DateTime windowEnd) {
    final rightmostIndex = _indexForDay(windowEnd);
    return (rightmostIndex - diaryVisibleDayCount + 1).clamp(
      0,
      _maxLeftmostIndex,
    );
  }

  int _indexForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    return normalizedDay
        .difference(_earliestDay)
        .inDays
        .clamp(0, _itemCount - 1);
  }

  DateTime _dayForIndex(int index) {
    return _earliestDay.add(Duration(days: index));
  }

  bool _isWithinActiveBuffer(DateTime day) {
    final visibleDays = buildDiaryVisibleDays(
      anchorDay: widget.visibleWindowEnd,
    );
    final bufferStart = visibleDays.first.subtract(
      const Duration(days: caloriesDayNavigationPrefetchDayCount),
    );
    final bufferEnd = visibleDays.last.add(
      const Duration(days: caloriesDayNavigationPrefetchDayCount),
    );
    final normalizedDay = normalizeDiaryDay(day);
    if (normalizedDay.isBefore(normalizeDiaryDay(bufferStart))) {
      return false;
    }
    return !normalizedDay.isAfter(_referenceToday) &&
        !normalizedDay.isAfter(normalizeDiaryDay(bufferEnd));
  }

  void _setInteractionState({bool? isPressEnabled, bool? isSnapping}) {
    setState(() {
      if (isPressEnabled != null) {
        _isPressEnabled = isPressEnabled;
      }
      if (isSnapping != null) {
        _isSnapping = isSnapping;
      }
    });
  }
}
