import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/root_navigator_test_utils.dart';
import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('template card menu opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith((ref) async => null),
        ],
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: PreparedMealTemplateCard(
              template: preparedMealTestData().copyWith(
                recipeUrl: 'https://example.test',
              ),
              onOpenPressed: () {},
              onEditPressed: (_) async => true,
              onDeletePressed: (_) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.text('Edit'), findsOneWidget);
  });
}
