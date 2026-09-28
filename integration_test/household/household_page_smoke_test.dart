import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_leave_dialog.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_members_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_household.dart';

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('the admin opens the household page and the leave dialog', (
    tester,
  ) async {
    final backend = FakeHousehold.create();
    await backend.addMember(
      'shared',
      'admin',
      joinedAt: DateTime(2026),
      admin: true,
    );
    await backend.addMember('shared', 'member', joinedAt: DateTime(2026, 2));
    await backend.addUser(
      'admin',
      householdId: 'shared',
      ownHouseholdId: 'shared',
      displayName: 'Alex',
    );
    await backend.addUser(
      'member',
      householdId: 'shared',
      ownHouseholdId: 'own-member',
      displayName: 'Eli',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await backend.overrides('admin', displayName: 'Alex'),
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HouseholdPage(),
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    expect(find.byType(HouseholdSharingCard), findsOneWidget);
    expect(find.byKey(HouseholdMembersSection.adminBadgeKey), findsOneWidget);
    expect(
      find.byKey(HouseholdMembersSection.menuKey('member')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(HouseholdSharingCard.leaveKey));
    await _pumpVisibleStep(tester);
    expect(
      find.byKey(HouseholdLeaveDialog.successorKey('member')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(HouseholdLeaveDialog.cancelKey));
    await _pumpVisibleStep(tester);
    expect(find.byType(HouseholdLeaveDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
