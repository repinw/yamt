import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_day_button.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_day_snap_scroll_physics.dart';

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
    required this.heartDayKeys,
    required this.onSelectDay,
    super.key,
  });

  /// The normalized current day.
  final DateTime today;

  /// The selected day.
  final DateTime selectedDay;

  /// Changes when the parent asks the strip to scroll back to today.
  final int todayRequest;

  /// Diary day keys protected by spent hearts.
  final Set<String> heartDayKeys;

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
    final accentColors = MetricAccentColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / _calendarVisibleDayCount;
        _syncInitialScrollPosition(itemWidth);

        return SizedBox(
          height: 58,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return _handleScrollNotification(notification, itemWidth);
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: DiaryDaySnapScrollPhysics(itemExtent: itemWidth),
              itemCount: _itemCount,
              itemExtent: itemWidth,
              itemBuilder: (context, index) {
                final day = _dayForIndex(index);
                return DiaryCalendarDayButton(
                  day: day,
                  isActive: isSameCalendarDay(
                    day,
                    widget.selectedDay,
                  ),
                  isToday: isSameCalendarDay(day, widget.today),
                  isHeartDay: widget.heartDayKeys.contains(
                    diaryDayKey(day),
                  ),
                  activeColor: accentColors.today,
                  heartColor: accentColors.heartFor(colors.brightness),
                  inactiveTextColor: colors.onSurfaceVariant,
                  onTap: () => widget.onSelectDay(day),
                );
              },
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
    return dateOnly(day)
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
