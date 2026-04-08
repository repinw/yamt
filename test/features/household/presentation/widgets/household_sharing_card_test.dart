import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/features/household/provider/household_members_provider.dart';
import 'package:yamt/features/household/provider/'
    'household_invite_code_controller.dart';
import 'package:yamt/features/household/provider/'
    'household_membership_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

class _FakeHouseholdInviteCodeController extends HouseholdInviteCodeController {
  @override
  AsyncValue<String?> build() {
    return const AsyncData<String?>(null);
  }
}

class _FakeHouseholdMembershipController extends HouseholdMembershipController {
  _FakeHouseholdMembershipController({this.onRemoveMember});

  final Future<void> Function(String userId)? onRemoveMember;

  @override
  FutureOr<void> build() {}

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
  }) {
    return ProviderScope(
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
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HouseholdSharingCard(user: user)),
      ),
    );
  }

  testWidgets('verified leader sees join and invite sections', (tester) async {
    final user = buildUser(uid: 'host-1', isAnonymous: false);
    final profile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      isAnonymous: false,
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
    final profile = UserProfile(
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
    final host = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      isAnonymous: false,
    );
    final guest = UserProfile(
      uid: 'guest-1',
      householdId: 'host-1',
      email: 'guest@example.com',
      displayName: 'Guest',
      isAnonymous: false,
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
    final host = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      isAnonymous: false,
    );
    final guest = UserProfile(
      uid: 'guest-1',
      householdId: 'host-1',
      email: 'guest@example.com',
      displayName: 'Guest',
      isAnonymous: false,
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
    final profile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      isAnonymous: false,
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
            () => _FakeHouseholdInviteCodeController(),
          ),
          householdMembershipControllerProvider.overrideWith(
            () => _FakeHouseholdMembershipController(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
}
