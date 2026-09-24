import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User;

class _FakeHouseholdInviteCodeController extends HouseholdInviteCodeController {
  @override
  AsyncValue<HouseholdInvite?> build() {
    return const AsyncData<HouseholdInvite?>(null);
  }
}

class _FakeHouseholdKeySession extends HouseholdKeySession {
  new(this._state);

  final HouseholdKeyState _state;

  @override
  Future<HouseholdKeyState> build() async => _state;
}

String _inviteLink(String code) {
  return HouseholdInvite(code: code, secret: RecoveryKey.generate()).link;
}

class _FakeHouseholdMembershipController extends HouseholdMembershipController {
  new({this.onRemoveMember, this.onJoinHousehold});

  final Future<void> Function(String userId)? onRemoveMember;
  final Future<void> Function(HouseholdInvite invite, String? displayName)?
  onJoinHousehold;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> joinHousehold(
    HouseholdInvite invite, {
    String? displayName,
  }) async {
    await onJoinHousehold?.call(invite, displayName);
    state = const AsyncData<void>(null);
  }

  @override
  Future<void> removeMember(String userId) async {
    await onRemoveMember?.call(userId);
    state = const AsyncData<void>(null);
  }

  @override
  Future<void> leaveHousehold() async {
    state = const AsyncData<void>(null);
  }
}

void main() {
  User buildUser({required String uid, required bool isAnonymous}) {
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.isAnonymous).thenReturn(isAnonymous);
    return user;
  }

  Widget buildApp({
    required User user,
    required UserProfile profile,
    required List<UserProfile> members,
    HouseholdInviteCodeController? inviteController,
    HouseholdMembershipController? membershipController,
    HouseholdKeyState keyState = const HouseholdKeyUnavailable(),
  }) {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        householdMembersProvider.overrideWith((ref) => Stream.value(members)),
        householdInviteCodeControllerProvider.overrideWith(
          () => inviteController ?? _FakeHouseholdInviteCodeController(),
        ),
        householdMembershipControllerProvider.overrideWith(
          () => membershipController ?? _FakeHouseholdMembershipController(),
        ),
        householdKeySessionProvider.overrideWith(
          () => _FakeHouseholdKeySession(keyState),
        ),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HouseholdSharingCard(user: user)),
      ),
    );
  }

  testWidgets('verified leader sees join and invite sections', (tester) async {
    final user = buildUser(uid: 'host-1', isAnonymous: false);
    const profile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
    );

    await tester.pumpWidget(
      buildApp(user: user, profile: profile, members: [profile]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Household'), findsOneWidget);
    expect(find.text('Join household'), findsOneWidget);
    expect(find.text('Invite members'), findsOneWidget);
    expect(find.text('Leave household'), findsNothing);
  });

  testWidgets('anonymous users see the verification hint', (tester) async {
    final user = buildUser(uid: 'guest-1', isAnonymous: true);
    const profile = UserProfile(
      uid: 'guest-1',
      displayName: 'Guest',
      isAnonymous: true,
    );

    await tester.pumpWidget(
      buildApp(user: user, profile: profile, members: [profile]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join household'), findsOneWidget);
    expect(find.textContaining('link your guest account'), findsOneWidget);
    expect(find.text('Invite members'), findsNothing);
  });

  testWidgets('guest members see members and the leave action', (tester) async {
    final user = buildUser(uid: 'guest-1', isAnonymous: false);
    const host = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
    );
    const guest = UserProfile(
      uid: 'guest-1',
      householdId: 'host-1',
      email: 'guest@example.com',
      displayName: 'Guest',
    );

    await tester.pumpWidget(
      buildApp(user: user, profile: guest, members: [host, guest]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Leader'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Leave household'), findsOneWidget);
    expect(find.text('Invite members'), findsNothing);
  });

  testWidgets('leaders can remove members from the list', (tester) async {
    final user = buildUser(uid: 'host-1', isAnonymous: false);
    const host = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
    );
    const guest = UserProfile(
      uid: 'guest-1',
      householdId: 'host-1',
      email: 'guest@example.com',
      displayName: 'Guest',
    );
    String? removedUserId;

    await tester.pumpWidget(
      buildApp(
        user: user,
        profile: host,
        members: [host, guest],
        membershipController: _FakeHouseholdMembershipController(
          onRemoveMember: (userId) async {
            removedUserId = userId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(removedUserId, 'guest-1');
    expect(find.text('Member removed.'), findsOneWidget);
  });

  testWidgets('debug details are shown when household members fail to load', (
    tester,
  ) async {
    final user = buildUser(uid: 'host-1', isAnonymous: false);
    const profile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          householdMembersProvider.overrideWith(
            (ref) => Stream<List<UserProfile>>.error(
              StateError('member query failed'),
            ),
          ),
          householdInviteCodeControllerProvider.overrideWith(
            _FakeHouseholdInviteCodeController.new,
          ),
          householdMembershipControllerProvider.overrideWith(
            _FakeHouseholdMembershipController.new,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HouseholdSharingCard(user: user)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Household action failed. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('member query failed'), findsOneWidget);
  });

  testWidgets(
    'user without name entering link and clicking join sees name prompt '
    'dialog and joins with entered name',
    (tester) async {
      final user = buildUser(uid: 'guest-1', isAnonymous: true);
      const profile = UserProfile(uid: 'guest-1', isAnonymous: true);
      String? joinedCode;
      String? joinedDisplayName;

      await tester.pumpWidget(
        buildApp(
          user: user,
          profile: profile,
          members: [profile],
          membershipController: _FakeHouseholdMembershipController(
            onJoinHousehold: (invite, displayName) async {
              joinedCode = invite.code;
              joinedDisplayName = displayName;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), _inviteLink('123456'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Sam');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Join'));
      await tester.pumpAndSettle();

      expect(joinedCode, '123456');
      expect(joinedDisplayName, 'Sam');
      expect(find.text('Household joined.'), findsOneWidget);
    },
  );

  testWidgets(
    'user with existing name joining household does not see name prompt',
    (tester) async {
      final user = buildUser(uid: 'user-1', isAnonymous: false);
      const profile = UserProfile(uid: 'user-1', displayName: 'Existing User');
      String? joinedCode;
      String? joinedDisplayName;

      await tester.pumpWidget(
        buildApp(
          user: user,
          profile: profile,
          members: [profile],
          membershipController: _FakeHouseholdMembershipController(
            onJoinHousehold: (invite, displayName) async {
              joinedCode = invite.code;
              joinedDisplayName = displayName;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), _inviteLink('654321'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsNothing);
      expect(joinedCode, '654321');
      expect(joinedDisplayName, isNull);
      expect(find.text('Household joined.'), findsOneWidget);
    },
  );

  testWidgets('user canceling name prompt does not join household', (
    tester,
  ) async {
    final user = buildUser(uid: 'guest-1', isAnonymous: true);
    const profile = UserProfile(uid: 'guest-1', isAnonymous: true);
    var joinCalled = false;

    await tester.pumpWidget(
      buildApp(
        user: user,
        profile: profile,
        members: [profile],
        membershipController: _FakeHouseholdMembershipController(
          onJoinHousehold: (invite, displayName) async {
            joinCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), _inviteLink('123456'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsNothing);
    expect(joinCalled, isFalse);
  });

  testWidgets('member without household key sees rejoin hint and join', (
    tester,
  ) async {
    final user = buildUser(uid: 'member-1', isAnonymous: false);
    const host = UserProfile(uid: 'host-1', displayName: 'Host');
    const profile = UserProfile(
      uid: 'member-1',
      displayName: 'Member',
      householdId: 'host-1',
    );

    await tester.pumpWidget(
      buildApp(
        user: user,
        profile: profile,
        members: [host, profile],
        keyState: const HouseholdKeyInviteRequired(ownerUid: 'host-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Please join the household again with a QR code to read the shared '
        'data.',
      ),
      findsOneWidget,
    );
    expect(find.text('Join household'), findsOneWidget);
  });

  testWidgets('join stays disabled for text that is no invite link', (
    tester,
  ) async {
    final user = buildUser(uid: 'user-1', isAnonymous: false);
    const profile = UserProfile(uid: 'user-1', displayName: 'User');

    await tester.pumpWidget(
      buildApp(user: user, profile: profile, members: [profile]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Join'),
    );
    expect(button.onPressed, isNull);
  });
}
