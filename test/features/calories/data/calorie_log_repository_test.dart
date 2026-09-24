import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

late UserDataCipher signedIn;

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  String name = 'Yogurt',
  String? imageUrl,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: name,
    imageUrl: imageUrl,
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

  test('stored entries are encrypted', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.saveEntry(_entry('a', loggedAt: DateTime(2026, 2, 25, 8)));
    await pumpEventQueue();

    final stored = (await firestore.doc('users/user-1/calorie_entries/a').get())
        .data()!;
    expect(stored.keys, unorderedEquals(<String>['payload', 'logged_at']));
    expect(stored['payload'], isNot(contains('Yogurt')));
  });

  test('watchEntriesForDay only returns entries from selected day', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.saveEntry(_entry('a', loggedAt: DateTime(2026, 2, 25, 8)));
    await repository.saveEntry(_entry('b', loggedAt: DateTime(2026, 2, 26, 8)));

    final entries = await repository
        .watchEntriesForDay(DateTime(2026, 2, 25))
        .first;

    expect(entries, hasLength(1));
    expect(entries.single.id, 'a');
  });

  test('save getById and delete operate on one document per entry', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    final entry = _entry('entry-1', loggedAt: DateTime(2026, 2, 25, 9));
    final saved = await repository.saveEntry(entry);
    final loaded = await repository.getById(entry.id);
    final deleted = await repository.deleteEntry(entry.id);
    final afterDelete = await repository.getById(entry.id);

    expect(saved, isTrue);
    expect(loaded?.id, entry.id);
    expect(deleted, isTrue);
    expect(afterDelete, isNull);
  });

  test('saveEntry normalizes imageUrl when loading entry back', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    final entry = _entry(
      'entry-image',
      loggedAt: DateTime(2026, 2, 25, 9),
      imageUrl: '/images/products/400/638/133/3931/front_de.3.400.jpg',
    );

    await repository.saveEntry(entry);
    final loaded = await repository.getById(entry.id);

    expect(
      loaded?.imageUrl,
      'https://world.openfoodfacts.org'
      '/images/products/400/638/133/3931/front_de.3.400.jpg',
    );
  });

  test('returns safe defaults when no user is signed in', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: null,
      firestore: firestore,
    );

    final watched = await repository
        .watchEntriesForDay(DateTime(2026, 2, 25))
        .first;
    final read = await repository.readEntriesForDay(DateTime(2026, 2, 25));
    final saved = await repository.saveEntry(
      _entry('entry-1', loggedAt: DateTime(2026, 2, 25, 9)),
    );

    expect(watched, isEmpty);
    expect(read, isEmpty);
    expect(saved, isFalse);
  });

  test('readEntriesForDay keeps ordering by logged_at', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.saveEntry(
      _entry('later', loggedAt: DateTime(2026, 2, 25, 12)),
    );
    await repository.saveEntry(
      _entry('earlier', loggedAt: DateTime(2026, 2, 25, 7)),
    );

    final entries = await repository.readEntriesForDay(DateTime(2026, 2, 25));

    expect(entries.map((entry) => entry.id), <String>['earlier', 'later']);
  });

  test('readEntriesInRange returns ordered entries within bounds', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.saveEntry(
      _entry('outside-before', loggedAt: DateTime(2026, 2, 24, 23, 59)),
    );
    await repository.saveEntry(
      _entry('in-range-late', loggedAt: DateTime(2026, 2, 25, 18)),
    );
    await repository.saveEntry(
      _entry('in-range-early', loggedAt: DateTime(2026, 2, 25, 7)),
    );
    await repository.saveEntry(
      _entry('outside-after', loggedAt: DateTime(2026, 2, 27)),
    );

    final entries = await repository.readEntriesInRange(
      startInclusive: DateTime(2026, 2, 25),
      endExclusive: DateTime(2026, 2, 27),
    );

    expect(entries.map((entry) => entry.id), <String>[
      'in-range-early',
      'in-range-late',
    ]);
  });

  test('readFirstEntryDate returns earliest logged_at value', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    await repository.saveEntry(
      _entry('later', loggedAt: DateTime(2026, 2, 26, 12)),
    );
    await repository.saveEntry(
      _entry('earliest', loggedAt: DateTime(2026, 2, 25, 6)),
    );

    final firstEntryDate = await repository.readFirstEntryDate();

    expect(firstEntryDate, DateTime(2026, 2, 25, 6));
  });

  test('watchEntriesForDay streams realtime updates', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );

    final emitted = <List<CalorieEntry>>[];
    final subscription = repository
        .watchEntriesForDay(DateTime(2026, 2, 25))
        .listen(emitted.add);
    addTearDown(() {
      unawaited(subscription.cancel());
    });

    await repository.saveEntry(
      _entry('entry-1', loggedAt: DateTime(2026, 2, 25, 10)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(emitted, isNotEmpty);
    expect(emitted.last.map((entry) => entry.id), contains('entry-1'));
  });

  test('readEntriesInRange and readFirstEntryDate return safe defaults '
      'when no user is signed in', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      dataCipher: null,
      firestore: firestore,
    );

    final entries = await repository.readEntriesInRange(
      startInclusive: DateTime(2026, 2, 25),
      endExclusive: DateTime(2026, 2, 26),
    );
    final firstEntryDate = await repository.readFirstEntryDate();

    expect(entries, isEmpty);
    expect(firstEntryDate, isNull);
  });

  test('cachedById returns entries the repository saved or watched', () async {
    final firestore = FakeFirebaseFirestore();
    final writer = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );
    final reader = FirestoreCalorieLogRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );
    final entry = _entry('entry-1', loggedAt: DateTime(2026, 2, 25, 9));

    await writer.saveEntry(entry);
    expect(writer.cachedById('entry-1')?.id, 'entry-1');
    expect(reader.cachedById('entry-1'), isNull);

    await reader.watchEntriesForDay(DateTime(2026, 2, 25)).first;
    expect(reader.cachedById('entry-1')?.name, 'Yogurt');

    await writer.deleteEntry('entry-1');
    expect(writer.cachedById('entry-1'), isNull);
  });
}
