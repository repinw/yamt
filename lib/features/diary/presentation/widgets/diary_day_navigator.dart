import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_label_text.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_header_layout.dart';
import 'package:yamt/l10n/app_localizations.dart';

const double _swipeVelocityThreshold = 300;
const double _pillHeight = 40;
const double _arrowButtonSize = 36;

/// Share of its full size that the day label may shrink to before the header
/// moves the day to a row of its own.
const double _labelMinScale = 0.85;
const Duration _dayChangeDuration = Duration(milliseconds: 220);

/// Keys used by [DiaryDayNavigator].
abstract final class DiaryDayNavigatorKeys {
  /// Previous day button.
  static const previous = ValueKey<String>('diary-day-navigator-previous');

  /// Next day button.
  static const next = ValueKey<String>('diary-day-navigator-next');

  /// Day label that opens the calendar overview.
  static const label = ValueKey<String>('diary-day-navigator-label');
}

/// Centered day with previous/next arrows: the date with its abbreviated
/// weekday, under a small "Today", "Yesterday", "Tomorrow", "Day after
/// tomorrow" or "3 days ago", between leading and trailing actions.
class DiaryDayNavigator extends StatefulWidget {
  /// Creates a diary day navigator.
  const new({
    required this.selectedDay,
    required this.today,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenCalendar,
    this.leadingActions = const <Widget>[],
    this.actions = const <Widget>[],
    this.reservedTools = const <Widget>[],
    super.key,
  });

  /// Selected day.
  final DateTime selectedDay;

  /// Normalized current day.
  final DateTime today;

  /// Whether the previous day is selectable.
  final bool canGoBack;

  /// Whether the next day is selectable.
  final bool canGoForward;

  /// Called to select the previous day.
  final VoidCallback onPrevious;

  /// Called to select the next day.
  final VoidCallback onNext;

  /// Called when the day label is tapped.
  final VoidCallback onOpenCalendar;

  /// Header tools aligned to the left edge.
  final List<Widget> leadingActions;

  /// Header tools aligned to the right edge.
  final List<Widget> actions;

  /// Tools that the sides may show on other days. They are laid out but never
  /// shown: both sides keep the room of the widest of them, so the header
  /// does not change its rows from day to day.
  final List<Widget> reservedTools;

  @override
  State<DiaryDayNavigator> createState() => _DiaryDayNavigatorState();
}

class _DiaryDayNavigatorState extends State<DiaryDayNavigator> {
  var _slideDirection = 1.0;
  var _labelTextWidth = 0.0;

  @override
  void didUpdateWidget(covariant DiaryDayNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameCalendarDay(widget.selectedDay, oldWidget.selectedDay)) {
      _slideDirection = widget.selectedDay.isAfter(oldWidget.selectedDay)
          ? 1.0
          : -1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _labelTextWidth = diaryDayLabelTextWidth(context);
  }

  @override
  Widget build(BuildContext context) {
    return DiaryHeaderLayout(
      // The label needs this width at the least before the day gets its own
      // row; the same on every day, so the header does not flip while swiping.
      dayWidth:
          2 * _arrowButtonSize +
          2 * AppSpacing.xxs +
          _labelMinScale * _labelTextWidth,
      leading: _buildTools(widget.leadingActions),
      trailing: _buildTools(widget.actions),
      references: widget.reservedTools,
      day: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleSwipe,
        child: Center(child: _buildPill(context)),
      ),
    );
  }

  Widget _buildTools(List<Widget> tools) {
    return Row(mainAxisSize: MainAxisSize.min, children: tools);
  }

  Widget _buildPill(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _pillHeight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildArrow(
            key: DiaryDayNavigatorKeys.previous,
            icon: Icons.chevron_left_rounded,
            onPressed: widget.canGoBack ? widget.onPrevious : null,
          ),
          Flexible(child: _buildLabel(context)),
          _buildArrow(
            key: DiaryDayNavigatorKeys.next,
            icon: Icons.chevron_right_rounded,
            onPressed: widget.canGoForward ? widget.onNext : null,
          ),
        ],
      ),
    );
  }

  Widget _buildArrow({
    required Key key,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      key: key,
      onPressed: AppHapticFeedback.wrap(onPressed),
      icon: Icon(icon),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _arrowButtonSize,
        height: _arrowButtonSize,
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final date = diaryDateLineOf(context)(widget.selectedDay);
    final relativeName = _relativeName(context);

    return AppInkWell(
      key: DiaryDayNavigatorKeys.label,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      onTap: widget.onOpenCalendar,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          // The text sits in a box of the reserved width, so the label scales
          // the same on every day.
          child: SizedBox(
            width: _labelTextWidth,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: _dayChangeDuration,
                transitionBuilder: _buildTransition,
                child: Column(
                  key: ValueKey<DateTime>(dateOnly(widget.selectedDay)),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      relativeName,
                      maxLines: 1,
                      softWrap: false,
                      style: diaryDayNameStyle(context),
                    ),
                    Text(
                      date,
                      maxLines: 1,
                      softWrap: false,
                      style: diaryDateStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The relative name of the day: a name from yesterday up to the day after
  /// tomorrow, else how many calendar days away it is.
  String _relativeName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final day = widget.selectedDay;
    final today = widget.today;
    final tomorrow = nextLocalDay(today);
    if (isSameCalendarDay(day, today)) {
      return l10n.diaryTodayTitle;
    }
    if (isSameCalendarDay(day, previousLocalDay(today))) {
      return l10n.diaryYesterdayTitle;
    }
    if (isSameCalendarDay(day, tomorrow)) {
      return l10n.diaryTomorrowTitle;
    }
    if (isSameCalendarDay(day, nextLocalDay(tomorrow))) {
      return l10n.diaryDayAfterTomorrowTitle;
    }
    final distance = localDaysBetween(today, day);
    return distance < 0
        ? l10n.diaryDaysAgo(-distance)
        : l10n.diaryInDays(distance);
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final isIncoming =
        child.key == ValueKey<DateTime>(dateOnly(widget.selectedDay));
    final beginX = (isIncoming ? 0.35 : -0.35) * _slideDirection;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(beginX, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocityThreshold && widget.canGoForward) {
      AppHapticFeedback.lightImpact();
      widget.onNext();
    } else if (velocity >= _swipeVelocityThreshold && widget.canGoBack) {
      AppHapticFeedback.lightImpact();
      widget.onPrevious();
    }
  }
}
