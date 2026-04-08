import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

void main() {
  test('effectiveHouseholdDataOwnerUserIdProvider falls back to '
      'the personal uid during recovery', () {
    var actualDataOwnerUserId = 'host-1';
    final container = ProviderContainer(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWith(
          (ref) => actualDataOwnerUserId,
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(effectiveHouseholdDataOwnerUserIdProvider), 'host-1');

    container
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: 'host-1',
          personalUserId: 'member-1',
        );

    expect(
      container.read(effectiveHouseholdDataOwnerUserIdProvider),
      'member-1',
    );

    actualDataOwnerUserId = 'member-1';
    container.invalidate(householdDataOwnerUserIdProvider);

    expect(
      container.read(effectiveHouseholdDataOwnerUserIdProvider),
      'member-1',
    );
  });
}
