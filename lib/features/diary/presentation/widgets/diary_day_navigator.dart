import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/l10n/app_localizations.dart';

const double _swipeVelocityThreshold = 300;
const double _pillHeight = 40;
const double _arrowButtonSize = 36;
const double _labelMinWidth = 72;
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

/// Centered single-day pill with previous/next arrows, leading and trailing
/// actions.
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

  /// Round top-bar actions aligned to the left edge.
  final List<Widget> leadingActions;

  /// Round top-bar actions aligned to the right edge.
  final List<Widget> actions;

  @override
  State<DiaryDayNavigator> createState() => _DiaryDayNavigatorState();
}

class _DiaryDayNavigatorState extends State<DiaryDayNavigator> {
  var _slideDirection = 1.0;

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
  Widget build(BuildContext context) {
    // Reserve the wider side's actions on both sides so the pill stays
    // centered.
    final actionsWidth = _actionsWidth(
      widget.leadingActions.length > widget.actions.length
          ? widget.leadingActions.length
          : widget.actions.length,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: actionsWidth),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _handleSwipe,
            child: _buildPill(context),
          ),
        ),
        if (widget.leadingActions.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: HomeTopBarActions(actions: widget.leadingActions),
          ),
        if (widget.actions.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: HomeTopBarActions(actions: widget.actions),
          ),
      ],
    );
  }

  double _actionsWidth(int count) {
    if (count == 0) {
      return 0;
    }
    return count * (AppSizes.homeTopBarIconButton + AppSpacing.xs) +
        AppSpacing.xs;
  }

  Widget _buildPill(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
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
    final theme = Theme.of(context);
    final isToday = isSameCalendarDay(widget.selectedDay, widget.today);
    final foregroundColor = isToday
        ? MetricAccentColors.of(context).today
        : theme.colorScheme.onSurface;

    return AppInkWell(
      key: DiaryDayNavigatorKeys.label,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: widget.onOpenCalendar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _labelMinWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxs,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: _dayChangeDuration,
                transitionBuilder: _buildTransition,
                child: Text(
                  _dayLabel(context),
                  key: ValueKey<DateTime>(dateOnly(widget.selectedDay)),
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dayLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isSameCalendarDay(widget.selectedDay, widget.today)) {
      return l10n.diaryTodayTitle;
    }
    if (isSameCalendarDay(widget.selectedDay, previousLocalDay(widget.today))) {
      return l10n.diaryYesterdayTitle;
    }
    return DateFormat('dd.MM').format(widget.selectedDay);
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
