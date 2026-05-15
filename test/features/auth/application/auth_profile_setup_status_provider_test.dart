import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

import '../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User {}

void main() {
  User buildUser(String uid) {
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    return user;
  }

  ProviderContainer buildContainer({
    required User? user,
    required AppPreferences preferences,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        authStateChangesProvider.overrideWith((ref) => _authStateStream(user)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('returns false when there is no authenticated user', () async {
    final container = buildContainer(
      user: null,
      preferences: MemoryAppPreferences(
        completedProfileSetupUserIds: {'user-1'},
      ),
    );
    await seedAuthState(container);

    expect(container.read(authProfileSetupCompletedProvider), isFalse);
  });

  test('returns true when current user completed profile setup', () async {
    final container = buildContainer(
      user: buildUser('user-1'),
      preferences: MemoryAppPreferences(
        completedProfileSetupUserIds: {'user-1'},
      ),
    );
    await seedAuthState(container);

    expect(container.read(authProfileSetupCompletedProvider), isTrue);
  });

  test(
    'returns false when stored completion belongs to another user',
    () async {
      final container = buildContainer(
        user: buildUser('user-2'),
        preferences: MemoryAppPreferences(
          completedProfileSetupUserIds: {'user-1'},
        ),
      );
      await seedAuthState(container);

      expect(container.read(authProfileSetupCompletedProvider), isFalse);
    },
  );
}

Future<void> seedAuthState(ProviderContainer container) async {
  final subscription = container.listen(
    authStateChangesProvider,
    (previous, next) {},
  );
  addTearDown(subscription.close);
  await Future<void>.delayed(Duration.zero);
}

Stream<User?> _authStateStream(User? user) {
  late final StreamController<User?> controller;
  controller = StreamController<User?>(
    sync: true,
    onListen: () {
      controller.add(user);
      unawaited(controller.close());
    },
  );
  return controller.stream;
}
