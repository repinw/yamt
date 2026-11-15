import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What "Timer" on the cooking list offers.
const kochmodusTimerChoices = [
  Duration(minutes: 5),
  Duration(minutes: 10),
  Duration(minutes: 15),
];

/// "Timer": one big button per duration; a tap starts the timer [name].
/// Says when the timer may not ring as it should ([KochmodusTimerHint]).
class KochmodusTimerSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({required this.name, required this.choices, super.key});

  /// Key of the button of the choice at [index].
  static ValueKey<String> choiceKey(int index) =>
      ValueKey<String>('kochmodus-timer-choice-$index');

  /// Key of "Erlauben" on the hint that the timer may ring late, in the
  /// sheet and in the guide ([KochmodusTimerHint]).
  static const allowExactKey = ValueKey<String>('kochmodus-timer-allow-exact');

  /// Key of "Erlauben" on the hint that notifications are off, in the sheet
  /// and in the guide ([KochmodusTimerHint]).
  static const allowNotificationsKey = ValueKey<String>(
    'kochmodus-timer-allow-notifications',
  );

  /// The timer's name, such as "Timer 2" or "Schritt 3".
  final String name;

  /// The durations offered, in their order.
  final List<Duration> choices;

  /// Shows the sheet and returns the chosen duration, or `null` when it is
  /// closed.
  static Future<Duration?> show(
    BuildContext context, {
    required String name,
    required List<Duration> choices,
  }) => showModalBottomSheet<Duration>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => KochmodusTimerSheet(name: name, choices: choices),
  );

  /// [duration] as a button names it: "5 Min", "30 Sek" below a minute,
  /// or "1 Min 30 Sek".
  static String durationText(AppLocalizations l10n, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(Duration.secondsPerMinute);
    if (minutes == 0) return l10n.kochmodusTimerSeconds(duration.inSeconds);
    if (seconds == 0) return l10n.kochmodusTimerMinutes(minutes);
    return l10n.kochmodusTimerMinutesSeconds(minutes, seconds);
  }

  /// The [choices] of one time in a sentence as its button names them:
  /// "8–10 Min" for a span of whole minutes, else the first.
  static String choicesText(AppLocalizations l10n, List<Duration> choices) =>
      switch (choices) {
        [final from, final to] when _wholeMinutes(from) && _wholeMinutes(to) =>
          l10n.kochmodusTimerMinuteRange(from.inMinutes, to.inMinutes),
        _ => durationText(l10n, choices.first),
      };

  static bool _wholeMinutes(Duration duration) =>
      duration.inMinutes > 0 &&
      duration.inSeconds.remainder(Duration.secondsPerMinute) == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.muted);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.kochmodusTimerAction.toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: colors.muted,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Text(
              name,
              style: textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              spacing: AppSpacing.sm,
              children: [
                for (final (index, choice) in choices.indexed)
                  Expanded(
                    child: OutlinedButton(
                      key: choiceKey(index),
                      onPressed: () => Navigator.of(context).pop(choice),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppGraphit.toolButton,
                        ),
                      ),
                      child: Text(durationText(l10n, choice)),
                    ),
                  ),
              ],
            ),
            Text(l10n.kochmodusTimerSheetHint, style: muted),
            const KochmodusTimerHint(),
          ],
        ),
      ),
    );
  }
}

/// Why a timer may not ring as it should, with "Erlauben": notifications
/// are off, or Android lets it ring late. Nothing while timers ring on time.
/// The sheet shows it, and the guide under the times of a step, whose tap
/// starts a timer without the sheet.
class KochmodusTimerHint extends ConsumerWidget {
  /// Creates the hint.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Unknown counts as on time: no hint while it loads or fails.
    final exact = ref.watch(cookTimerExactAllowedProvider).value ?? true;
    final blocked = ref.watch(cookTimerNotificationsBlockedProvider);
    // Without notifications exact alarms do not matter.
    if (blocked) {
      return _AllowHint(
        buttonKey: KochmodusTimerSheet.allowNotificationsKey,
        text: l10n.kochmodusTimerNotificationsOffHint,
        onAllow: () => ref
            .read(cookTimerAlarmControllerProvider.notifier)
            .openNotificationSettings(),
      );
    }
    if (!exact) {
      return _AllowHint(
        buttonKey: KochmodusTimerSheet.allowExactKey,
        text: l10n.kochmodusTimerInexactHint,
        onAllow: () => ref
            .read(cookTimerAlarmControllerProvider.notifier)
            .allowExactAlarms(),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A hint why a timer may not ring as it should, with "Erlauben".
class _AllowHint extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.text,
    required this.onAllow,
  });

  final Key buttonKey;
  final String text;
  final Future<void> Function() onAllow;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.muted);
    return Row(
      spacing: AppSpacing.xs,
      children: [
        Expanded(child: Text(text, style: muted)),
        TextButton(
          key: buttonKey,
          onPressed: () => unawaited(onAllow()),
          child: Text(AppLocalizations.of(context)!.kochmodusTimerAllowExact),
        ),
      ],
    );
  }
}
