import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_error_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'renders error message and retry button triggers callback',
    (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MealTemplatesErrorState(
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check text existence
      expect(
        find.text('Could not load templates.'),
        findsOneWidget,
      );

      // Check retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    },
  );
}
