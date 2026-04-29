import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_day_button.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';

const int _calendarVisibleDayCount = 7;
const int _calendarCenterDayOffset = _calendarVisibleDayCount ~/ 2;
const int _calendarPastDayCount = 3650;
const int _calendarFutureDayCount = 365;
const Duration _calendarTodayJumpDuration = Duration(milliseconds: 260);

/// Horizontally scrollable diary calendar strip.
class DiaryCalendarStrip extends StatefulWidget {
  /// The diary calendar strip.
  const DiaryCalendarStrip({
    required this.today,
    required this.selectedDay,
    required this.todayRequest,
    required this.onSelectDay,
    super.key,
  });

  /// The normalized current day.
  final DateTime today;

  /// The selected day.
  final DateTime selectedDay;

  /// Changes when the parent asks the strip to scroll back to today.
  final int todayRequest;

  /// Called when a day is selected.
  final ValueChanged<DateTime> onSelectDay;

  @override
  State<DiaryCalendarStrip> createState() => _DiaryCalendarStripState();
}

class _DiaryCalendarStripState extends State<DiaryCalendarStrip> {
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  var _didSyncInitialPosition = false;
  var _isUserScrollSequence = false;
  int? _lastHapticIndex;

  DateTime get _earliestDay {
    return widget.today.subtract(const Duration(days: _calendarPastDayCount));
  }

  int get _itemCount => _calendarPastDayCount + _calendarFutureDayCount + 1;

  int get _maxLeftmostIndex => _itemCount - _calendarVisibleDayCount;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiaryCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.todayRequest != oldWidget.todayRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToToday();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _calendarVisibleDayCount;
          _syncInitialScrollPosition(itemWidth);

          return SizedBox(
            height: 64,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                return _handleScrollNotification(notification, itemWidth);
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: _DaySnapScrollPhysics(itemExtent: itemWidth),
                itemCount: _itemCount,
                itemExtent: itemWidth,
                itemBuilder: (context, index) {
                  final day = _dayForIndex(index);
                  return DiaryCalendarDayButton(
                    day: day,
                    isActive: isSameDiaryCalendarDay(
                      day,
                      widget.selectedDay,
                    ),
                    isToday: isSameDiaryCalendarDay(day, widget.today),
                    activeColor: const Color(0xFF10B981),
                    inactiveTextColor: colors.onSurfaceVariant,
                    onTap: () {
                      unawaited(HapticFeedback.lightImpact());
                      widget.onSelectDay(day);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    double itemWidth,
  ) {
    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isUserScrollSequence = true;
      return false;
    }

    if (notification is ScrollUpdateNotification && _isUserScrollSequence) {
      _handleUserScrollHaptic(itemWidth, notification.scrollDelta);
      return false;
    }

    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      _isUserScrollSequence = false;
    }

    return false;
  }

  void _syncInitialScrollPosition(double itemWidth) {
    if (_didSyncInitialPosition) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(_initialLeftmostIndex * itemWidth);
      _lastHapticIndex = _initialLeftmostIndex;
      _didSyncInitialPosition = true;
    });
  }

  void _handleUserScrollHaptic(double itemWidth, double? scrollDelta) {
    if (!_scrollController.hasClients || itemWidth <= 0) {
      return;
    }

    final delta = scrollDelta ?? 0;
    if (delta == 0) {
      return;
    }

    final rawIndex = _scrollController.offset / itemWidth;
    final edgeIndex = delta > 0 ? rawIndex.floor() : rawIndex.ceil();
    final currentIndex = edgeIndex.clamp(0, _maxLeftmostIndex);
    if (_lastHapticIndex == currentIndex) {
      return;
    }

    _lastHapticIndex = currentIndex;
    unawaited(HapticFeedback.lightImpact());
  }

  int get _initialLeftmostIndex =>
      _centeredLeftmostIndexForDay(widget.selectedDay);

  int _centeredLeftmostIndexForDay(DateTime day) {
    return (_indexForDay(day) - _calendarCenterDayOffset).clamp(
      0,
      _maxLeftmostIndex,
    );
  }

  int _indexForDay(DateTime day) {
    return diaryDayOnly(day)
        .difference(_earliestDay)
        .inDays
        .clamp(
          0,
          _itemCount - 1,
        );
  }

  DateTime _dayForIndex(int index) {
    return _earliestDay.add(Duration(days: index));
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) {
      return;
    }

    final viewportWidth = _scrollController.position.viewportDimension;
    final itemWidth = viewportWidth / _calendarVisibleDayCount;
    final targetIndex = _centeredLeftmostIndexForDay(widget.today);
    final targetOffset = targetIndex * itemWidth;
    _lastHapticIndex = targetIndex;

    unawaited(
      _scrollController.animateTo(
        targetOffset,
        duration: _calendarTodayJumpDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _DaySnapScrollPhysics extends ClampingScrollPhysics {
  const _DaySnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _DaySnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _DaySnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (itemExtent <= 0 || position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    if (velocity.abs() > tolerance.velocity) {
      return _DayCoastThenSnapSimulation(
        start: position.pixels,
        velocity: velocity,
        itemExtent: itemExtent,
        minScrollExtent: position.minScrollExtent,
        maxScrollExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }

    final target = _nearestSnapPixels(position.pixels, position);
    final distance = (target - position.pixels).abs();
    if (distance < tolerance.distance) {
      return null;
    }

    return _DaySnapSimulation(
      start: position.pixels,
      end: target,
      itemExtent: itemExtent,
    );
  }

  double _nearestSnapPixels(double pixels, ScrollMetrics position) {
    final targetIndex = (pixels / itemExtent).round();
    return (targetIndex * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }
}

class _DaySnapSimulation extends Simulation {
  _DaySnapSimulation({
    required this.start,
    required this.end,
    required double itemExtent,
  }) : duration = _resolveDuration(
         distance: (end - start).abs(),
         itemExtent: itemExtent,
       );

  final double start;
  final double end;
  final double duration;

  @override
  double x(double time) {
    if (time >= duration) {
      return end;
    }

    final t = (time / duration).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - t, 3);
    return start + ((end - start) * eased);
  }

  @override
  double dx(double time) {
    if (time >= duration) {
      return 0;
    }

    final t = (time / duration).clamp(0.0, 1.0);
    return (end - start) * 3 * math.pow(1 - t, 2) / duration;
  }

  @override
  bool isDone(double time) => time >= duration;

  static double _resolveDuration({
    required double distance,
    required double itemExtent,
  }) {
    if (distance == 0) {
      return 0.001;
    }

    final pages = itemExtent <= 0 ? 1.0 : distance / itemExtent;
    final pageDuration = 0.18 + (math.min(pages, 12) * 0.024);
    return pageDuration.clamp(0.16, 0.46);
  }
}

class _DayCoastThenSnapSimulation extends Simulation {
  _DayCoastThenSnapSimulation({
    required double start,
    required double velocity,
    required this.itemExtent,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required Tolerance tolerance,
  }) : _coast = ClampingScrollSimulation(
         position: start,
         velocity: velocity,
         tolerance: tolerance,
       ) {
    _coastDuration = _resolveCoastDuration(_coast);
    _snapStart = _clampPixels(_coast.x(_coastDuration));
    _snapEnd = _nearestSnapPixels(_snapStart);
    _snapDuration = _DaySnapSimulation._resolveDuration(
      distance: (_snapEnd - _snapStart).abs(),
      itemExtent: itemExtent,
    );
  }

  final double itemExtent;
  final double minScrollExtent;
  final double maxScrollExtent;
  final ClampingScrollSimulation _coast;

  late final double _coastDuration;
  late final double _snapStart;
  late final double _snapEnd;
  late final double _snapDuration;

  double get _duration => _coastDuration + _snapDuration;

  @override
  double x(double time) {
    if (time < _coastDuration) {
      return _clampPixels(_coast.x(time));
    }
    if (time >= _duration) {
      return _snapEnd;
    }

    final t = ((time - _coastDuration) / _snapDuration).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - t, 3);
    return _snapStart + ((_snapEnd - _snapStart) * eased);
  }

  @override
  double dx(double time) {
    if (time < _coastDuration) {
      return _coast.dx(time);
    }
    if (time >= _duration) {
      return 0;
    }

    final t = ((time - _coastDuration) / _snapDuration).clamp(0.0, 1.0);
    return (_snapEnd - _snapStart) * 3 * math.pow(1 - t, 2) / _snapDuration;
  }

  @override
  bool isDone(double time) => time >= _duration;

  double _clampPixels(double pixels) {
    return pixels.clamp(minScrollExtent, maxScrollExtent);
  }

  double _nearestSnapPixels(double pixels) {
    final targetIndex = (pixels / itemExtent).round();
    return (targetIndex * itemExtent).clamp(minScrollExtent, maxScrollExtent);
  }

  static double _resolveCoastDuration(Simulation simulation) {
    var time = 0.0;
    while (time < 4 && !simulation.isDone(time)) {
      time += 1 / 60;
    }
    return time;
  }
}
