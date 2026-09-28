import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/router/hero_sheet_page.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_entry_label_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

const _openButtonKey = Key('diary_entry_details_flow_open');

CalorieEntry _entry() {
  final loggedAt = DateTime(2026, 5, 13, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final end = tester.binding.clock.fromNowBy(const Duration(seconds: 8));
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $finder.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('diary entry details save a changed amount', (tester) async {
    final logRepository = FakeCalorieLogRepository(initialEntries: [_entry()]);
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                key: _openButtonKey,
                onPressed: () => unawaited(
                  context.push<void>(
                    AppRoutes.homeCaloriesEntryDetailsPath('entry-1'),
                  ),
                ),
                child: const Icon(Icons.open_in_new),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.homeCaloriesEntryDetails,
          pageBuilder: (context, state) => HeroSheetPage<void>(
            key: state.pageKey,
            child: DiaryEntryDetailsPage(
              entryId: state.pathParameters['entryId']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('de'),
          routerConfig: router,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.tap(find.byKey(_openButtonKey));
    await _pumpUntilFound(tester, find.byKey(DiaryEntryLabelSection.labelKey));

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '150');
    await tester.pump();
    await tester.tap(find.byKey(DiaryEntryDetailsPage.saveButtonKey));
    await _pumpUntilFound(tester, find.byKey(_openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryDetailsPage), findsNothing);
    expect(logRepository.entries.single.consumedAmount, 150);
    expect(logRepository.entries.single.totalKcal, 150);
  });
}
