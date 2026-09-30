import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';

class _MockUser extends Mock implements User;

void main() {
  test('the profile names the active and the own household', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('member-1');
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            const UserProfile(
              uid: 'member-1',
              householdId: 'shared',
              ownHouseholdId: 'own',
              isAnonymous: false,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(activeHouseholdIdProvider, (_, _) {});
    addTearDown(subscription.close);
    final ownSubscription = container.listen(ownHouseholdIdProvider, (_, _) {});
    addTearDown(ownSubscription.close);

    expect(container.read(activeHouseholdIdProvider), isNull);
    await pumpEventQueue();

    expect(container.read(activeHouseholdIdProvider), 'shared');
    expect(container.read(ownHouseholdIdProvider), 'own');
  });

  test('activeHouseholdIdProvider falls back to the own household during '
      'recovery', () {
    var profileHouseholdId = 'shared';
    final container = ProviderContainer(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWith(
          (ref) => profileHouseholdId,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(activeHouseholdIdProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(container.read(activeHouseholdIdProvider), 'shared');

    container
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: 'shared',
          personalUserId: 'own',
        );

    expect(container.read(activeHouseholdIdProvider), 'own');

    profileHouseholdId = 'own';
    container.invalidate(householdDataOwnerUserIdProvider);

    expect(container.read(activeHouseholdIdProvider), 'own');
  });
}
