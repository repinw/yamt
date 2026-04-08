import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
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
  @override
  FutureOr<void> build() {}
}

Widget _buildApp({
  required Stream<User?> authStream,
  Stream<UserProfile>? profileStream,
  Stream<List<UserProfile>>? membersStream,
}) {
  final overrides = [
    authStateChangesProvider.overrideWith((ref) => authStream),
  ];

  if (profileStream != null) {
    overrides.add(userProfileProvider.overrideWith((ref) => profileStream));
  }
  if (membersStream != null) {
    overrides.add(
      householdMembersProvider.overrideWith((ref) => membersStream),
    );
    overrides.add(
      householdInviteCodeControllerProvider.overrideWith(
        () => _FakeHouseholdInviteCodeController(),
      ),
    );
    overrides.add(
      householdMembershipControllerProvider.overrideWith(
        () => _FakeHouseholdMembershipController(),
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HouseholdPage(),
    ),
  );
}

void main() {
  testWidgets(
    'HouseholdPage renders app bar and sharing card for signed-in user',
    (tester) async {
      final user = _MockUser();
      when(() => user.uid).thenReturn('host-1');
      when(() => user.isAnonymous).thenReturn(false);

      final profile = UserProfile(
        uid: 'host-1',
        email: 'host@example.com',
        displayName: 'Host',
        isAnonymous: false,
      );

      await tester.pumpWidget(
        _buildApp(
          authStream: Stream<User?>.value(user),
          profileStream: Stream<UserProfile>.value(profile),
          membersStream: Stream<List<UserProfile>>.value([profile]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Household'), findsWidgets);
      expect(find.byType(HouseholdSharingCard), findsOneWidget);
      expect(find.text('No active account session.'), findsNothing);
    },
  );

  testWidgets(
    'HouseholdPage shows signed-out fallback when no session exists',
    (tester) async {
      await tester.pumpWidget(_buildApp(authStream: Stream<User?>.value(null)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('No active account session.'), findsOneWidget);
      expect(find.byType(HouseholdSharingCard), findsNothing);
    },
  );
}
