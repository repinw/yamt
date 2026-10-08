import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_load_failed_page.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User;

Future<void> _pumpPage(WidgetTester tester, {required bool isAnonymous}) async {
  final user = _MockUser();
  when(() => user.isAnonymous).thenReturn(isAnonymous);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWithValue(AsyncData<User?>(user)),
      ],
      child: const MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalorieGoalLoadFailedPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('an account can sign out', (tester) async {
    await _pumpPage(tester, isAnonymous: false);

    expect(
      find.byKey(CalorieGoalOnboardingKeys.loadFailedSignOutAction),
      findsOneWidget,
    );
  });

  testWidgets('a guest gets no sign-out, which would lose its data', (
    tester,
  ) async {
    await _pumpPage(tester, isAnonymous: true);

    expect(
      find.byKey(CalorieGoalOnboardingKeys.loadFailedSignOutAction),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalOnboardingKeys.loadFailedRetryAction),
      findsOneWidget,
    );
  });
}
