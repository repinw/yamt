import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

late UserDataCipher signedIn;

CalorieEntry _plan(String id, {required DateTime loggedAt}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Porridge',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 80,
    per100Protein: 5,
    per100Carbs: 12,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  test('plans are stored encrypted apart from the calorie entries', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = PlannedEntryRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.savePlannedEntry(
      _plan('a', loggedAt: DateTime(2026, 10, 6, 8)),
    );
    await pumpEventQueue();

    final stored = (await firestore.doc('users/user-1/planned_entries/a').get())
        .data()!;
    expect(stored.keys, unorderedEquals(<String>['payload', 'logged_at']));
    expect(stored['payload'], isNot(contains('Porridge')));
    final entries = await firestore
        .collection('users/user-1/calorie_entries')
        .get();
    expect(entries.docs, isEmpty);
  });

  test('loads the plans of one day in time order', () async {
    final repository = PlannedEntryRepository(
      dataCipher: signedIn,
      firestore: FakeFirebaseFirestore(),
    );
    await repository.savePlannedEntry(
      _plan('late', loggedAt: DateTime(2026, 10, 6, 19)),
    );
    await repository.savePlannedEntry(
      _plan('early', loggedAt: DateTime(2026, 10, 6, 8)),
    );
    await repository.savePlannedEntry(
      _plan('next-day', loggedAt: DateTime(2026, 10, 7, 8)),
    );
    await pumpEventQueue();

    final plans = await repository.loadPlannedEntriesForDay(
      DateTime(2026, 10, 6),
    );

    expect(plans.map((plan) => plan.id), ['early', 'late']);
  });

  test('loads the days that hold plans within a range', () async {
    final repository = PlannedEntryRepository(
      dataCipher: signedIn,
      firestore: FakeFirebaseFirestore(),
    );
    await repository.savePlannedEntry(
      _plan('before', loggedAt: DateTime(2026, 10, 4, 23)),
    );
    await repository.savePlannedEntry(
      _plan('first', loggedAt: DateTime(2026, 10, 5, 8)),
    );
    await repository.savePlannedEntry(
      _plan('second', loggedAt: DateTime(2026, 10, 5, 19)),
    );
    await repository.savePlannedEntry(
      _plan('last', loggedAt: DateTime(2026, 10, 9, 23, 59)),
    );
    await repository.savePlannedEntry(
      _plan('after', loggedAt: DateTime(2026, 10, 10)),
    );
    await pumpEventQueue();

    final days = await repository.loadPlannedDays(
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 9),
    );

    expect(days, {DateTime(2026, 10, 5), DateTime(2026, 10, 9)});
  });

  test('deletes a plan', () async {
    final repository = PlannedEntryRepository(
      dataCipher: signedIn,
      firestore: FakeFirebaseFirestore(),
    );
    final plan = _plan('a', loggedAt: DateTime(2026, 10, 6, 8));
    await repository.savePlannedEntry(plan);
    await pumpEventQueue();

    await repository.deletePlannedEntry(plan.id);
    await pumpEventQueue();

    expect(await repository.loadPlannedEntriesForDay(plan.loggedAt), isEmpty);
  });

  test('signed out reads nothing and refuses writes', () async {
    const repository = PlannedEntryRepository(
      dataCipher: null,
      firestore: null,
    );
    final plan = _plan('a', loggedAt: DateTime(2026, 10, 6, 8));

    expect(await repository.loadPlannedEntriesForDay(plan.loggedAt), isEmpty);
    expect(
      await repository.loadPlannedDays(plan.loggedAt, plan.loggedAt),
      isEmpty,
    );
    await expectLater(
      repository.savePlannedEntry(plan),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.deletePlannedEntry('a'),
      throwsA(isA<StateError>()),
    );
  });
}
