import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_overview_sheet/diary_calendar_month_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

const Duration _monthPageDuration = Duration(milliseconds: 260);

/// Keys used by the diary calendar overview sheet.
abstract final class DiaryCalendarOverviewKeys {
  /// Previous month button.
  static const previousMonth = ValueKey<String>('diary-calendar-prev-month');

  /// Next month button.
  static const nextMonth = ValueKey<String>('diary-calendar-next-month');

  /// Month page view.
  static const pageView = ValueKey<String>('diary-calendar-month-pages');

  /// Today button.
  static const today = ValueKey<String>('diary-calendar-today');
}

/// Shows the month overview and resolves with the picked day, if any.
Future<DateTime?> showDiaryCalendarOverviewSheet({
  required BuildContext context,
  required DateTime selectedDay,
  required DateTime today,
  required DiaryCalendarBounds bounds,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => DiaryCalendarOverview(
      selectedDay: selectedDay,
      today: today,
      bounds: bounds,
    ),
  );
}

/// Swipeable month overview used inside the calendar sheet.
class DiaryCalendarOverview extends StatefulWidget {
  /// Creates the calendar overview.
  const new({
    required this.selectedDay,
    required this.today,
    required this.bounds,
    super.key,
  });

  /// Selected day.
  final DateTime selectedDay;

  /// Normalized current day.
  final DateTime today;

  /// Selectable range.
  final DiaryCalendarBounds bounds;

  @override
  State<DiaryCalendarOverview> createState() => _DiaryCalendarOverviewState();
}

class _DiaryCalendarOverviewState extends State<DiaryCalendarOverview> {
  late final PageController _pageController;
  late int _pageIndex;

  DateTime get _firstMonth =>
      DateTime(widget.bounds.earliestDay.year, widget.bounds.earliestDay.month);

  int get _monthCount => _monthIndex(widget.bounds.latestDay) + 1;

  @override
  void initState() {
    super.initState();
    _pageIndex = _monthIndex(widget.bounds.clamp(widget.selectedDay));
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _monthIndex(DateTime day) {
    return (day.year - _firstMonth.year) * 12 + day.month - _firstMonth.month;
  }

  DateTime _monthForIndex(int index) {
    return DateTime(_firstMonth.year, _firstMonth.month + index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiaryCalendarMonthHeader(
              month: _monthForIndex(_pageIndex),
              onPrevious: _pageIndex > 0 ? () => _goToPage(-1) : null,
              onNext: _pageIndex < _monthCount - 1 ? () => _goToPage(1) : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            DiaryCalendarWeekdayRow(referenceDay: widget.today),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              height: DiaryCalendarMonthGrid.height,
              child: PageView.builder(
                key: DiaryCalendarOverviewKeys.pageView,
                controller: _pageController,
                itemCount: _monthCount,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) => DiaryCalendarMonthGrid(
                  month: _monthForIndex(index),
                  selectedDay: widget.selectedDay,
                  today: widget.today,
                  bounds: widget.bounds,
                  onSelectDay: (day) => Navigator.of(context).pop(day),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                key: DiaryCalendarOverviewKeys.today,
                onPressed: () => Navigator.of(context).pop(widget.today),
                child: Text(l10n.diaryTodayTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int delta) {
    _pageController.animateToPage(
      (_pageIndex + delta).clamp(0, _monthCount - 1),
      duration: _monthPageDuration,
      curve: Curves.easeOutCubic,
    );
  }
}

class _DiaryCalendarMonthHeader extends StatelessWidget {
  const new({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        IconButton(
          key: DiaryCalendarOverviewKeys.previousMonth,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(localeName).format(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          key: DiaryCalendarOverviewKeys.nextMonth,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
