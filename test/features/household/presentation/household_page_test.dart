import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_household.dart';

Widget _buildApp(List<Object> overrides) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: const MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HouseholdPage(),
    ),
  );
}

void main() {
  testWidgets('HouseholdPage shows the household of the signed-in user', (
    tester,
  ) async {
    final backend = FakeHousehold.create();
    final overrides = await tester.runAsync(() async {
      await backend.addMember(
        'own',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser('me', householdId: 'own', ownHouseholdId: 'own');
      return await backend.overrides('me');
    });

    await tester.pumpWidget(_buildApp(overrides!));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Household'), findsOneWidget);
    expect(find.byType(HouseholdSharingCard), findsOneWidget);
    expect(find.byKey(HouseholdJoinSection.linkFieldKey), findsOneWidget);
  });

  testWidgets(
    'HouseholdPage shows signed-out fallback when no session exists',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(null),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active account session.'), findsOneWidget);
      expect(find.byType(HouseholdSharingCard), findsNothing);
    },
  );
}
