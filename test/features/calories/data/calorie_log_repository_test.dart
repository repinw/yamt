import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

class _FakeCalorieLogUserSession implements CalorieLogUserSession {
  _FakeCalorieLogUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

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
  test('watchEntriesForDay only returns entries from selected day', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      session: _FakeCalorieLogUserSession(currentUserId: 'user-1'),
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
      session: _FakeCalorieLogUserSession(currentUserId: 'user-1'),
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

  test('saveEntry keeps imageUrl when loading entry back', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      session: _FakeCalorieLogUserSession(currentUserId: 'user-1'),
      firestore: firestore,
    );

    final entry = _entry(
      'entry-image',
      loggedAt: DateTime(2026, 2, 25, 9),
      imageUrl: 'https://images.example.com/yogurt.jpg',
    );

    await repository.saveEntry(entry);
    final loaded = await repository.getById(entry.id);

    expect(loaded?.imageUrl, entry.imageUrl);
  });

  test('returns safe defaults when no user is signed in', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      session: _FakeCalorieLogUserSession(currentUserId: null),
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
      session: _FakeCalorieLogUserSession(currentUserId: 'user-1'),
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

  test('watchEntriesForDay streams realtime updates', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieLogRepository(
      session: _FakeCalorieLogUserSession(currentUserId: 'user-1'),
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
}
