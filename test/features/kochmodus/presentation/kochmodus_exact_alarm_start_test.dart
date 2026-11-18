import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

// The alarm listener of the real app keeps the controller alive.
Widget _withAlarms(Widget page) => Consumer(
  builder: (context, ref, _) {
    ref.watch(cookTimerAlarmControllerProvider);
    return page;
  },
);

// W1: the exact-alarm screen opens at a real start of cooking, never in the
// middle of a step.
void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    addRecipe(harness, kochmodusRecipe());
    // An Android-like phone: exact alarms off, never declined.
    harness.notifications
      ..exactAllowed = false
      ..grantsExact = false;
  });

  testWidgets('W1: reopening a running run at a cook step asks for no exact '
      'alarms', (tester) async {
    final run = buildCookRun(
      step: CookRunStep.cook,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      steps: const [],
      lines: [textLine('l-flour', 'Mehl', settlement: const LineIgnored())],
    );
    await harness.store(tester, run);

    // Like the real app: the alarm listener keeps the controller alive.
    await harness.pumpApp(
      tester,
      initialLocation: AppRoutes.homeCookRunPath(run.id),
    );

    expect(harness.notifications.exactRequests, 0);
  });

  testWidgets('W1: free cooking still asks for exact alarms once', (
    tester,
  ) async {
    await openPage(tester, harness, _withAlarms(const KochmodusPage.free()));

    expect(harness.notifications.exactRequests, 1);
  });

  testWidgets('W1: assigning a recipe still asks for exact alarms once', (
    tester,
  ) async {
    await openPage(
      tester,
      harness,
      _withAlarms(const KochmodusAssignPage(recipeId: 't1')),
    );

    expect(harness.notifications.exactRequests, 1);
  });
}
