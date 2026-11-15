import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_async_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'controllers/slow_cook_runs.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  testWidgets('a write the server rejects says the cooking was not saved '
      'and keeps the page', (tester) async {
    final runs = harness.runsOverride = SlowCookRuns(harness.cook.runs);
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.pots,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        lines: [
          textLine(
            'line-0',
            '500 g Hackfleisch',
            settlement: const LineIgnored(),
          ),
        ],
      ),
    );
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
    );
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);

    runs.serverRejects.add('recipe-t1');
    await harness.idle(tester);

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.kochmodusSaveFailed), findsOneWidget);
    expect(find.byKey(KochmodusAsyncView.goneBackKey), findsNothing);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
  });
}
