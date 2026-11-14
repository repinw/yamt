import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_exclusions_controller.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';

class _FailingSaveRepository extends AiChefExclusionsRepository {
  new({required super.firestore, required super.dataCipher});

  @override
  Future<void> saveExclusions(AiChefExclusions exclusions) async {
    throw StateError('offline');
  }
}

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  ProviderContainer containerWith(AiChefExclusionsRepository repository) {
    final container = ProviderContainer(
      overrides: [
        aiChefExclusionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<AiChefExclusions> nextValue(
    ProviderContainer container,
    bool Function(AiChefExclusions value) isDone,
  ) async {
    final subscription = container.listen(
      aiChefExclusionsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    for (var i = 0; i < 50; i++) {
      final value = subscription.read().value;
      if (value != null && isDone(value)) {
        return value;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail('The list never reached the expected value.');
  }

  test('starts loading, then shows the stored list', () async {
    final container = containerWith(
      AiChefExclusionsRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: signedIn,
      ),
    );

    expect(
      container.read(aiChefExclusionsControllerProvider),
      isA<AsyncLoading<AiChefExclusions>>(),
    );
    expect(await nextValue(container, (value) => true), AiChefExclusions.empty);
  });

  test('adds and removes entries through the repository', () async {
    final container = containerWith(
      AiChefExclusionsRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: signedIn,
      ),
    );
    await nextValue(container, (value) => true);
    final controller = container.read(
      aiChefExclusionsControllerProvider.notifier,
    );

    expect(await controller.addIngredient(' Koriander '), isTrue);
    await nextValue(container, (value) => value.ingredients.isNotEmpty);
    expect(await controller.addIngredient('Rosinen'), isTrue);
    await nextValue(container, (value) => value.ingredients.length == 2);
    expect(await controller.removeIngredient('Koriander'), isTrue);

    final value = await nextValue(
      container,
      (value) => value.ingredients.length == 1,
    );
    expect(value.ingredients, ['Rosinen']);
  });

  test('returns false before the list is loaded', () async {
    final container = containerWith(
      AiChefExclusionsRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: signedIn,
      ),
    );

    final added = await container
        .read(aiChefExclusionsControllerProvider.notifier)
        .addIngredient('Koriander');

    expect(added, isFalse);
  });

  test('returns false when saving fails', () async {
    final container = containerWith(
      _FailingSaveRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: signedIn,
      ),
    );
    await nextValue(container, (value) => true);

    final added = await container
        .read(aiChefExclusionsControllerProvider.notifier)
        .addIngredient('Koriander');

    expect(added, isFalse);
  });

  test('shows an added entry before the stream catches up', () async {
    final container = containerWith(
      AiChefExclusionsRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: signedIn,
      ),
    );
    await nextValue(container, (value) => true);

    await container
        .read(aiChefExclusionsControllerProvider.notifier)
        .addIngredient('Koriander');

    expect(
      container.read(aiChefExclusionsControllerProvider).value?.ingredients,
      ['Koriander'],
    );
  });

  test('stays loading while there is no data key', () async {
    final container = containerWith(
      AiChefExclusionsRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: null,
      ),
    );
    final subscription = container.listen(
      aiChefExclusionsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await pumpEventQueue();

    expect(subscription.read(), isA<AsyncLoading<AiChefExclusions>>());
  });

  test('two quick changes both stay', () async {
    final repository = AiChefExclusionsRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );
    final container = containerWith(repository);
    await nextValue(container, (value) => true);
    final controller = container.read(
      aiChefExclusionsControllerProvider.notifier,
    );

    final saved = await Future.wait([
      controller.addIngredient('Koriander'),
      controller.addIngredient('Rosinen'),
    ]);

    expect(saved, [true, true]);
    expect(
      (await nextValue(
        container,
        (value) => value.ingredients.length == 2,
      )).ingredients,
      ['Koriander', 'Rosinen'],
    );
  });
}
