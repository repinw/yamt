import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';

final _permissionDenied = FirebaseException(
  plugin: 'cloud_firestore',
  code: 'permission-denied',
);

/// Hands out a [Ref] that the recovery helpers use outside of a build.
final Provider<Ref> _refProvider = Provider<Ref>((ref) => ref);

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWithValue('shared'),
        ownHouseholdIdProvider.overrideWithValue('own'),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(_refProvider, (_, _) {});
    addTearDown(subscription.close);
    return container;
  }

  test('a denied read in a shared household switches home', () {
    final ref = createContainer().read(_refProvider);

    bool shouldRecover(Object error, String householdId) {
      return shouldRecoverControllerHouseholdAccess(
        ref: ref,
        error: error,
        isRecoveringHouseholdAccess: false,
        currentHouseholdDataOwnerUserId: householdId,
      );
    }

    expect(shouldRecover(_permissionDenied, 'shared'), isTrue);
    expect(shouldRecover(_permissionDenied, 'own'), isFalse);
    expect(shouldRecover(StateError('x'), 'shared'), isFalse);
  });

  test('the recovery reads the own household instead', () async {
    final container = createContainer();
    final subscription = container.listen(activeHouseholdIdProvider, (_, _) {});
    addTearDown(subscription.close);

    final items = await performControllerHouseholdAccessRecovery<String>(
      ref: container.read(_refProvider),
      restartHouseholdScopedSubscription: () async => const <String>['again'],
      currentHouseholdDataOwnerUserId: 'shared',
      householdAccessRecoveryLogName: 'test',
      householdAccessRecoveryMessage: 'test',
    );

    expect(items, <String>['again']);
    expect(container.read(activeHouseholdIdProvider), 'own');
  });
}
