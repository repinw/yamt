import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_async_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, AsyncValue<String?> value) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipeAsyncView<String>(
            value: value,
            notFoundKey: const Key('not-found'),
            retryKey: const Key('retry'),
            data: Text.new,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the view, a missing recipe, and a retry', (tester) async {
    await _pump(tester, const AsyncData('Bauerntopf'));
    expect(find.text('Bauerntopf'), findsOneWidget);

    await _pump(tester, const AsyncData(null));
    expect(find.byKey(const Key('not-found')), findsOneWidget);

    await _pump(tester, const AsyncError('offline', StackTrace.empty));
    expect(find.byKey(const Key('retry')), findsOneWidget);
  });
}
