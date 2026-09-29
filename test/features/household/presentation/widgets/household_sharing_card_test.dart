import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_confirm_dialog.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_invite_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_key_restore_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_leave_dialog.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_members_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_unlock_code_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_household.dart';

class _MockUser extends Mock implements User;

void main() {
  late FakeHousehold backend;

  setUp(() => backend = FakeHousehold.create());

  /// Lets the real repositories, crypto and streams run between frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpCard(
    WidgetTester tester,
    String uid, {
    bool isAnonymous = false,
    String? displayName = 'Me',
  }) async {
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.isAnonymous).thenReturn(isAnonymous);
    final overrides = await tester.runAsync(
      () => backend.overrides(
        uid,
        isAnonymous: isAnonymous,
        displayName: displayName,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides!,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HouseholdSharingCard(user: user),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> seed(Future<void> Function() setup, WidgetTester tester) async {
    await tester.runAsync(setup);
  }

  Future<void> sharedHousehold() async {
    await backend.addMember(
      'shared',
      'admin',
      joinedAt: DateTime(2026),
      admin: true,
    );
    await backend.addMember('shared', 'early', joinedAt: DateTime(2026, 2));
    await backend.addMember('shared', 'me', joinedAt: DateTime(2026, 3));
    await backend.addUser(
      'admin',
      householdId: 'shared',
      ownHouseholdId: 'shared',
      displayName: 'Alex',
    );
    await backend.addUser(
      'early',
      householdId: 'shared',
      ownHouseholdId: 'own-early',
      displayName: 'Eli',
    );
  }

  testWidgets('alone in the own household the user joins or invites', (
    tester,
  ) async {
    await seed(() async {
      await backend.addMember(
        'own',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser('me', householdId: 'own', ownHouseholdId: 'own');
    }, tester);

    await pumpCard(tester, 'me');

    expect(find.byKey(HouseholdJoinSection.linkFieldKey), findsOneWidget);
    expect(find.byKey(HouseholdInviteSection.createKey), findsOneWidget);
    expect(find.byKey(HouseholdSharingCard.leaveKey), findsNothing);
    expect(find.byType(HouseholdMembersSection), findsNothing);
  });

  testWidgets('a failed load says that the household did not load', (
    tester,
  ) async {
    await seed(() async {
      // A member entry without a join date cannot be read.
      await backend.firestore.doc('households/own/members/me').set(
        <String, dynamic>{'uid': 'me', 'role': 'admin'},
      );
      await backend.addUser('me', householdId: 'own', ownHouseholdId: 'own');
    }, tester);

    await pumpCard(tester, 'me');

    expect(
      tester.widget<Text>(find.byKey(HouseholdSharingCard.loadErrorKey)).data,
      'Could not load the household.',
    );
    expect(find.byKey(HouseholdSharingCard.leaveKey), findsNothing);
  });

  testWidgets('a guest sees the hint to link the account', (tester) async {
    await seed(() async {
      await backend.addMember(
        'own',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser('me', householdId: 'own', ownHouseholdId: 'own');
    }, tester);

    await pumpCard(tester, 'me', isAnonymous: true);

    expect(find.textContaining('link your guest account'), findsOneWidget);
    expect(find.byKey(HouseholdInviteSection.createKey), findsNothing);
    expect(find.byKey(HouseholdJoinSection.linkFieldKey), findsOneWidget);
  });

  testWidgets('a member sees the admin badge and leaves', (tester) async {
    await seed(() async {
      await sharedHousehold();
      await backend.addMember(
        'own-me',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser(
        'me',
        householdId: 'shared',
        ownHouseholdId: 'own-me',
        displayName: 'Me',
      );
    }, tester);

    await pumpCard(tester, 'me');

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Me (you)'), findsOneWidget);
    expect(find.byKey(HouseholdMembersSection.adminBadgeKey), findsOneWidget);
    expect(find.byKey(HouseholdMembersSection.menuKey('early')), findsNothing);
    expect(find.byKey(HouseholdInviteSection.createKey), findsNothing);
    expect(find.byKey(HouseholdJoinSection.linkFieldKey), findsNothing);

    await tester.tap(find.byKey(HouseholdSharingCard.leaveKey));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'You go back to your own household. The shared items stay here.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.tap(find.byKey(HouseholdLeaveDialog.confirmKey));
    await settle(tester);

    expect(find.text('Household left.'), findsOneWidget);
    expect(
      (await tester.runAsync(() => backend.read('users/me')))!['householdId'],
      'own-me',
    );
    expect(
      await tester.runAsync(() => backend.read('households/shared/members/me')),
      isNull,
    );
  });

  testWidgets('the admin hands the lead on', (tester) async {
    await seed(() async {
      await sharedHousehold();
      await backend.addUser(
        'me',
        householdId: 'shared',
        ownHouseholdId: 'own-me',
      );
    }, tester);

    await pumpCard(tester, 'admin', displayName: 'Alex');
    await tester.tap(find.byKey(HouseholdMembersSection.menuKey('early')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HouseholdMembersSection.makeAdminKey));
    await tester.pumpAndSettle();
    expect(find.text('Make Eli admin?'), findsOneWidget);
    await tester.tap(find.byKey(HouseholdConfirmDialog.confirmKey));
    await settle(tester);

    expect(find.text('Eli is now the admin.'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => backend.read('households/shared/members/early'),
      ))!['role'],
      'admin',
    );
    expect(
      (await tester.runAsync(
        () => backend.read('households/shared/members/admin'),
      ))!['role'],
      'member',
    );
  });

  testWidgets('the admin removes a member', (tester) async {
    await seed(sharedHousehold, tester);

    await pumpCard(tester, 'admin', displayName: 'Alex');
    await tester.tap(find.byKey(HouseholdMembersSection.menuKey('early')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HouseholdMembersSection.removeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HouseholdConfirmDialog.confirmKey));
    await settle(tester);

    expect(find.text('Member removed.'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => backend.read('households/shared/members/early'),
      ),
      isNull,
    );
    expect(find.text('Eli'), findsNothing);
  });

  testWidgets('the admin who leaves picks who leads next', (tester) async {
    await seed(sharedHousehold, tester);

    await pumpCard(tester, 'admin', displayName: 'Alex');
    await tester.tap(find.byKey(HouseholdSharingCard.leaveKey));
    await tester.pumpAndSettle();

    expect(find.text('Who leads the household after you?'), findsOneWidget);
    final proposed = tester.widget<RadioGroup<String>>(
      find.byType(RadioGroup<String>),
    );
    expect(proposed.groupValue, 'early');

    await tester.tap(find.byKey(HouseholdLeaveDialog.successorKey('me')));
    await tester.pump();
    await tester.tap(find.byKey(HouseholdLeaveDialog.confirmKey));
    await settle(tester);

    expect(
      (await tester.runAsync(
        () => backend.read('households/shared/members/me'),
      ))!['role'],
      'admin',
    );
    expect(
      await tester.runAsync(
        () => backend.read('households/shared/members/admin'),
      ),
      isNull,
    );
    final profile = (await tester.runAsync(() => backend.read('users/admin')))!;
    expect(profile['ownHouseholdId'], isNot('shared'));
  });

  testWidgets('a member who lost the key enters an unlock code', (
    tester,
  ) async {
    await seed(() async {
      await sharedHousehold();
      await backend.addUser(
        'me',
        householdId: 'shared',
        ownHouseholdId: 'own-me',
      );
      await backend.loseKey('shared', 'me');
    }, tester);
    final code = await tester.runAsync(
      () => HouseholdKeyRepository(firestore: backend.firestore)
          .saveRestoreCode(
            householdId: 'shared',
            memberUid: 'me',
            householdKey: backend.householdKeys['shared']!,
          ),
    );

    await pumpCard(tester, 'me');
    await tester.enterText(
      find.byKey(HouseholdKeyRestoreSection.codeFieldKey),
      code!.formatted,
    );
    await tester.tap(find.byKey(HouseholdKeyRestoreSection.restoreButtonKey));
    await settle(tester);

    expect(find.text('Pantry unlocked.'), findsOneWidget);
    expect(find.byKey(HouseholdKeyRestoreSection.codeFieldKey), findsNothing);
  });

  testWidgets('another member creates the unlock code', (tester) async {
    await seed(() async {
      await sharedHousehold();
      await backend.addUser(
        'me',
        householdId: 'shared',
        ownHouseholdId: 'own-me',
      );
      await backend.loseKey('shared', 'early');
    }, tester);

    await pumpCard(tester, 'me');
    expect(find.textContaining('Eli started fresh'), findsOneWidget);
    await tester.tap(
      find.byKey(HouseholdUnlockCodeSection.createCodeButtonKey),
    );
    await settle(tester);

    expect(
      find.byKey(HouseholdUnlockCodeSection.createdCodeKey),
      findsOneWidget,
    );
    expect(
      await tester.runAsync(
        () => backend.read('households/shared/key_restores/early'),
      ),
      contains('wrapped_household_key'),
    );
  });

  testWidgets('a user without a name joins with the name dialog', (
    tester,
  ) async {
    late HouseholdInvite invite;
    await seed(() async {
      await sharedHousehold();
      await backend.addMember(
        'own-me',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser(
        'me',
        householdId: 'own-me',
        ownHouseholdId: 'own-me',
      );
      invite = HouseholdInvite(
        code: 'AbCdEfGhIjKlMnOpQrSt',
        secret: RecoveryKey.generate(),
      );
      await backend.firestore.doc('household_invites/AbCdEfGhIjKlMnOpQrSt').set(
        <String, dynamic>{
          'householdId': 'shared',
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 1)),
          ),
          'wrapped_household_key': await invite.secret.wrapDataKey(
            backend.householdKeys['shared']!,
            uid: 'household_invites/AbCdEfGhIjKlMnOpQrSt',
          ),
        },
      );
    }, tester);

    await pumpCard(tester, 'me', displayName: null);
    await tester.enterText(
      find.byKey(HouseholdJoinSection.linkFieldKey),
      invite.link,
    );
    await tester.pump();
    await tester.tap(find.byKey(HouseholdJoinSection.joinKey));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Sam');
    await tester.tap(find.text('Save & Join'));
    await settle(tester);

    expect(find.text('Household joined.'), findsOneWidget);
    expect(
      (await tester.runAsync(() => backend.read('users/me')))!['householdId'],
      'shared',
    );
    expect(
      (await tester.runAsync(
        () => backend.read('households/shared/members/me'),
      ))!['role'],
      'member',
    );
  });

  testWidgets('join stays disabled for text that is no invite link', (
    tester,
  ) async {
    await seed(() async {
      await backend.addMember(
        'own',
        'me',
        joinedAt: DateTime(2026),
        admin: true,
      );
      await backend.addUser('me', householdId: 'own', ownHouseholdId: 'own');
    }, tester);

    await pumpCard(tester, 'me');
    await tester.enterText(
      find.byKey(HouseholdJoinSection.linkFieldKey),
      'AbCdEfGhIjKlMnOpQrSt',
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(HouseholdJoinSection.joinKey),
    );
    expect(button.onPressed, isNull);
  });
}
