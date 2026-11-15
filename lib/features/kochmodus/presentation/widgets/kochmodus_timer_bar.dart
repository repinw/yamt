import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_timer_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

// The rest times show seconds.
const _tick = Duration(seconds: 1);

// The seconds of a rest time show two digits, such as "4:05".
const _secondDigits = 2;

// How many timer rows show before the bar scrolls, so the list or the
// guide above keeps its room.
const _visibleRows = 2.5;

/// Above this text scale the Kochmodus shows its row buttons, such as
/// "+1 Min", "Stopp" and "Timer", as icons, so their rows fit.
const kochmodusLargeText = 1.3;

/// The running timers, the soonest first: name, rest time, "+1 Min" and
/// "Stopp". A timer that rang shows "fertig" in the accent color, and the
/// phone buzzes once. Past two and a half rows the bar scrolls.
class KochmodusTimerBar extends ConsumerStatefulWidget {
  /// Creates the bar of [timers] for the cooking of [target].
  const new({required this.target, required this.timers, super.key});

  /// Key of "+1 Min" of the timer [timerId].
  static ValueKey<String> extendKey(String timerId) =>
      ValueKey<String>('kochmodus-timer-extend-$timerId');

  /// Key of "Stopp" of the timer [timerId].
  static ValueKey<String> stopKey(String timerId) =>
      ValueKey<String>('kochmodus-timer-stop-$timerId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The running timers, the soonest first.
  final List<CookTimer> timers;

  @override
  ConsumerState<KochmodusTimerBar> createState() => _KochmodusTimerBarState();
}

class _KochmodusTimerBarState extends ConsumerState<KochmodusTimerBar> {
  late DateTime _now;
  Timer? _ticker;
  // The timers that buzzed already, or had rung before the bar showed
  // them: only a timer that ends while the bar shows it buzzes.
  final Set<String> _rang = {};

  @override
  void initState() {
    super.initState();
    _now = ref.read(clockProvider)();
    _rang.addAll(_endedIds(widget.timers));
    _sync();
  }

  @override
  void didUpdateWidget(KochmodusTimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _now = ref.read(clockProvider)();
    // "+1 Min" on a timer that rang lets it buzz again when it ends.
    _rang
      ..removeWhere(
        (id) => widget.timers.any(
          (timer) => timer.id == id && timer.endsAt.isAfter(_now),
        ),
      )
      // A timer that reaches the bar after it rang, such as from a sync.
      ..addAll(
        _endedIds(
          widget.timers.where(
            (timer) => oldWidget.timers.every((old) => old.id != timer.id),
          ),
        ),
      );
    _sync();
  }

  Iterable<String> _endedIds(Iterable<CookTimer> timers) => [
    for (final timer in timers)
      if (!timer.endsAt.isAfter(_now)) timer.id,
  ];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Ticks only while a timer runs.
  void _sync() {
    if (widget.timers.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    setState(() => _now = ref.read(clockProvider)());
    for (final timer in widget.timers) {
      if (!timer.endsAt.isAfter(_now) && _rang.add(timer.id)) {
        AppHapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: AppGraphit.buttonHeight * _visibleRows,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final timer in widget.timers)
            _TimerRow(
              key: ValueKey<String>(timer.id),
              target: widget.target,
              timer: timer,
              left: timer.endsAt.difference(_now),
            ),
        ],
      ),
    ),
  );
}

class _TimerRow extends StatelessWidget {
  const new({
    required this.target,
    required this.timer,
    required this.left,
    super.key,
  });

  final KochmodusTarget target;
  final CookTimer timer;
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final done = left <= Duration.zero;
    final ink = done ? colors.onAccent : colors.ink;
    final seconds = left.inSeconds;
    return ColoredBox(
      color: done ? colors.accent : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            Icon(Icons.timer_outlined, color: ink),
            Expanded(
              child: Text(
                timer.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(color: ink),
              ),
            ),
            Text(
              done
                  ? l10n.kochmodusTimerDone
                  : l10n.kochmodusTimerLeft(
                      seconds ~/ Duration.secondsPerMinute,
                      (seconds % Duration.secondsPerMinute).toString().padLeft(
                        _secondDigits,
                        '0',
                      ),
                    ),
              style: textTheme.titleMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            _TimerAction(
              key: KochmodusTimerBar.extendKey(timer.id),
              label: l10n.kochmodusTimerExtend,
              icon: Icons.more_time,
              color: ink,
              onPressed: () => unawaited(
                KochmodusActionFlow.run(
                  context,
                  target,
                  (_) => ProviderScope.containerOf(context, listen: false)
                      .read(kochmodusTimerControllerProvider(target).notifier)
                      .extendTimer(timer.id),
                ),
              ),
            ),
            _TimerAction(
              key: KochmodusTimerBar.stopKey(timer.id),
              label: l10n.kochmodusTimerStop,
              icon: Icons.stop,
              color: ink,
              onPressed: () => unawaited(
                KochmodusActionFlow.run(
                  context,
                  target,
                  (_) => ProviderScope.containerOf(context, listen: false)
                      .read(kochmodusTimerControllerProvider(target).notifier)
                      .stopTimer(timer.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// "+1 Min" or "Stopp": the word, or at large text the icon with the word as
// its tooltip.
class _TimerAction extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > kochmodusLargeText
      ? IconButton(
          onPressed: onPressed,
          tooltip: label,
          color: color,
          icon: Icon(icon),
        )
      : TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: color),
          child: Text(label),
        );
}
