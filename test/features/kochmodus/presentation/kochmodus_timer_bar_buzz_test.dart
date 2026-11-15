import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _start = DateTime.utc(2026, 11, 7, 12);

CookTimer _timer(String id, Duration endsIn) =>
    CookTimer(id: id, label: id, endsAt: _start.add(endsIn), deviceId: 'dev-1');

void main() {
  var now = _start;
  var buzzes = 0;

  setUp(() {
    now = _start;
    buzzes = 0;
  });

  Future<void> pumpBar(WidgetTester tester, List<CookTimer> timers) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [clockProvider.overrideWithValue(() => now)],
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: KochmodusTimerBar(
                target: const KochmodusTarget.recipe(recipeId: 't1'),
                timers: timers,
              ),
            ),
          ),
        ),
      );

  Future<void> tick(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  void countBuzzes(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.heavyImpact') {
          buzzes++;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  // Takes the bar down, so no ticker is left running.
  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('buzz', () {
    testWidgets('a timer that ended before the bar mounted stays quiet', (
      tester,
    ) async {
      countBuzzes(tester);
      now = _start.add(const Duration(minutes: 6));

      await pumpBar(tester, [_timer('t-1', const Duration(minutes: 5))]);
      await tick(tester);
      await tick(tester);

      expect(buzzes, 0);
      await close(tester);
    });

    testWidgets('a timer that arrives already ended stays quiet', (
      tester,
    ) async {
      countBuzzes(tester);
      await pumpBar(tester, [_timer('t-1', const Duration(minutes: 5))]);
      now = _start.add(const Duration(minutes: 6));

      await pumpBar(tester, [
        _timer('t-1', const Duration(minutes: 5)),
        _timer('t-2', const Duration(minutes: 2)),
      ]);
      await tick(tester);
      await tick(tester);

      // t-1 ended while shown: one buzz. t-2 arrived ended: none.
      expect(buzzes, 1);
      await close(tester);
    });

    testWidgets('a timer that crosses its end while mounted buzzes once', (
      tester,
    ) async {
      countBuzzes(tester);
      await pumpBar(tester, [_timer('t-1', const Duration(minutes: 5))]);
      await tick(tester);
      expect(buzzes, 0);

      now = _start.add(const Duration(minutes: 5, seconds: 1));
      await tick(tester);
      await tick(tester);
      await tick(tester);

      expect(buzzes, 1);
      await close(tester);
    });

    testWidgets('a remount after a ring does not buzz again', (tester) async {
      countBuzzes(tester);
      final timers = [_timer('t-1', const Duration(minutes: 5))];
      await pumpBar(tester, timers);
      now = _start.add(const Duration(minutes: 5, seconds: 1));
      await tick(tester);
      expect(buzzes, 1);

      // The guide goes off and on: the bar mounts again on a rung timer.
      await close(tester);
      await pumpBar(tester, timers);
      await tick(tester);
      await tick(tester);

      expect(buzzes, 1);
      await close(tester);
    });
  });
}
