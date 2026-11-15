import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

import '../cook_run_fixtures.dart';

/// A database whose batches wait in [waiting] once [holds] is on, as a posted
/// commit that a following read overtakes.
class _HoldingFirestore extends FakeFirebaseFirestore {
  bool holds = false;

  final waiting = <WriteBatch>[];

  /// Lands the oldest waiting batch.
  Future<void> landOne() => waiting.removeAt(0).commit();

  /// Lands every waiting batch, oldest first.
  Future<void> landAll() async {
    while (waiting.isNotEmpty) {
      await landOne();
    }
  }

  @override
  WriteBatch batch() =>
      holds ? _HeldBatch(super.batch(), waiting) : super.batch();
}

/// A batch that passes its writes on to [_batch] and decides itself what a
/// commit does.
abstract class _ForwardingBatch implements WriteBatch {
  new(this._batch);

  final WriteBatch _batch;

  @override
  void delete(DocumentReference<Object?> document) => _batch.delete(document);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) =>
      _batch.set(document, data, options);

  @override
  void update<T>(DocumentReference<T> document, T data) =>
      _batch.update(document, data);
}

class _HeldBatch extends _ForwardingBatch {
  new(super._batch, this._waiting);

  final List<WriteBatch> _waiting;

  @override
  Future<void> commit() async => _waiting.add(_batch);
}

/// A database whose commits stay open until [landAll]: the batch is not
/// applied and its future does not complete, as a posted commit that has not
/// reached the server (or the local cache) yet.
class _SlowFirestore extends FakeFirebaseFirestore {
  bool slow = false;

  final open = <({WriteBatch batch, Completer<void> done})>[];

  /// Applies every open commit, oldest first, and completes it.
  Future<void> landAll() async {
    while (open.isNotEmpty) {
      final commit = open.removeAt(0);
      await commit.batch.commit();
      commit.done.complete();
    }
    await Future<void>.delayed(Duration.zero);
  }

  @override
  WriteBatch batch() => slow ? _SlowBatch(super.batch(), open) : super.batch();
}

class _SlowBatch extends _ForwardingBatch {
  new(super._batch, this._open);

  final List<({WriteBatch batch, Completer<void> done})> _open;

  @override
  Future<void> commit() {
    final done = Completer<void>();
    _open.add((batch: _batch, done: done));
    return done.future;
  }
}

void main() {
  late PayloadCipher cipher;
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
    firestore = FakeFirebaseFirestore();
  });

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection('households').doc('h1').collection('cook_runs');

  SealedCollection sealed() => SealedCollection(collection(), cipher: cipher);

  CookRunRepository repository() => CookRunRepository(
    scope: (householdId: 'h1', firestore: firestore, cipher: cipher),
  );

  Future<void> settle(CookRunRepository repo) async {
    await repo.pending;
    await Future<void>.delayed(Duration.zero);
  }

  test('create then load returns the same run, sealed in Firestore', () async {
    final repo = repository();
    final run = fullCookRun();

    await repo.create(run);
    await settle(repo);

    expect(await repo.load(run.id), run);
    final stored = (await collection().doc(run.id).get()).data()!;
    expect(stored.containsKey('name'), isFalse);
    expect(stored.toString(), isNot(contains('Eintopf')));
  });

  test('load returns null for a run that does not exist', () async {
    expect(await repository().load('nope'), isNull);
  });

  test('load throws for a broken document', () async {
    await collection()
        .doc('bad')
        .set(await sealed().seal('bad', {'unexpected': 1}));

    await expectLater(repository().load('bad'), throwsA(anything));
  });

  test('mutate changes only its own thing and returns the run', () async {
    final repo = repository();
    final run = fullCookRun();
    await repo.create(run);

    final changed = await repo.mutate(run.id, (r) => r.copyWith(portions: 6));
    await settle(repo);

    expect(changed, run.copyWith(portions: 6));
    expect(await repo.load(run.id), run.copyWith(portions: 6));
  });

  test('two overlapping mutates both survive', () async {
    final repo = repository();
    final run = buildCookRun();
    await repo.create(run);

    final first = repo.mutate(run.id, (r) => r.copyWith(portions: 8));
    final second = repo.mutate(
      run.id,
      (r) => r.settle('line-1', const LineShopping()),
    );
    await Future.wait([first, second]);
    await settle(repo);

    final loaded = (await repo.load(run.id))!;
    expect(loaded.portions, 8);
    expect(loaded.lineOf('line-1')!.settlement, const LineShopping());
  });

  test(
    'a change that throws writes nothing and the next mutate works',
    () async {
      final repo = repository();
      final run = buildCookRun();
      await repo.create(run);

      await expectLater(
        repo.mutate(run.id, (r) => r.removeLine('nope')),
        throwsStateError,
      );
      await repo.mutate(run.id, (r) => r.copyWith(portions: 2));
      await settle(repo);

      expect(await repo.load(run.id), run.copyWith(portions: 2));
    },
  );

  test('a change that renames the run is refused', () async {
    final repo = repository();
    final run = buildCookRun();
    await repo.create(run);

    await expectLater(
      repo.mutate(run.id, (r) => buildCookRun(id: 'other')),
      throwsArgumentError,
    );
    expect(await repo.load(run.id), run);
  });

  test('mutate on a removed run throws CookRunGoneException', () async {
    final repo = repository();
    final run = buildCookRun();
    await repo.create(run);
    await settle(repo);
    await collection().doc(run.id).delete();

    await expectLater(
      repo.mutate(run.id, (r) => r.copyWith(portions: 2)),
      throwsA(
        isA<CookRunGoneException>().having((e) => e.runId, 'runId', run.id),
      ),
    );
    await settle(repo);

    expect((await collection().get()).docs, isEmpty);
    expect(await repo.load(run.id), isNull);
  });

  test('watchAll emits every run and skips a broken document', () async {
    final repo = repository();
    final run = buildCookRun(id: 'good-1');
    final other = buildCookRun(id: 'good-2');
    await repo.create(run);
    await repo.create(other);
    await collection()
        .doc('bad-sealed')
        .set(await sealed().seal('bad-sealed', {'unexpected': 1}));
    await collection().doc('bad-plain').set({'junk': true});
    await settle(repo);

    final runs = await repo.watchAll().first;

    expect(runs.map((r) => r.id), unorderedEquals(['good-1', 'good-2']));
  });

  test('watchAll follows later changes', () async {
    final repo = repository();
    await repo.create(buildCookRun());
    await settle(repo);
    final runs = StreamIterator(repo.watchAll());

    expect(await runs.moveNext(), isTrue);
    expect(runs.current.single.portions, 4);
    await repo.mutate('recipe-t1', (r) => r.copyWith(portions: 5));
    expect(await runs.moveNext(), isTrue);
    expect(runs.current.single.portions, 5);
    await runs.cancel();
  });

  test('stageDelete deletes in the batch the caller commits', () async {
    final repo = repository();
    final run = buildCookRun();
    await repo.create(run);
    await settle(repo);
    final batch = firestore.batch();

    await repo.stageDelete(batch, run.id);
    expect((await collection().get()).docs, hasLength(1));
    await batch.commit();

    expect((await collection().get()).docs, isEmpty);
  });

  test('stageDelete waits for earlier writes', () async {
    final repo = repository();
    final run = buildCookRun();
    await repo.create(run);
    final mutated = repo.mutate(run.id, (r) => r.copyWith(portions: 3));
    final batch = firestore.batch();

    await repo.stageDelete(batch, run.id);

    await mutated;
    await batch.commit();
    expect((await collection().get()).docs, isEmpty);
  });

  group('a read that overtakes a posted write', () {
    late _HoldingFirestore holding;
    late CookRunRepository repo;
    final run = buildCookRun();

    setUp(() async {
      holding = _HoldingFirestore();
      firestore = holding;
      repo = repository();
      await repo.create(run);
      await settle(repo);
      holding.holds = true;
    });

    test('the next mutate builds on the write the read missed', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));
      final changed = await repo.mutate(
        run.id,
        (r) => r.settle('line-1', const LineShopping()),
      );

      expect(changed.portions, 8);
      await holding.landAll();
      final loaded = (await repo.load(run.id))!;
      expect(loaded.portions, 8);
      expect(loaded.lineOf('line-1')!.settlement, const LineShopping());
    });

    test('load returns the write the read missed', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));

      expect((await repo.load(run.id))!.portions, 8);

      await holding.landAll();
      expect((await repo.load(run.id))!.portions, 8);
    });

    test('a read that finds only the earlier of two writes goes on', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));
      await repo.mutate(
        run.id,
        (r) => r.settle('line-1', const LineShopping()),
      );
      await holding.landOne();

      final loaded = (await repo.load(run.id))!;
      final changed = await repo.mutate(
        run.id,
        (r) => r.settle('line-0', const LineIgnored()),
      );
      await holding.landAll();

      expect(loaded.lineOf('line-1')!.settlement, const LineShopping());
      expect(changed.portions, 8);
      expect(changed.lineOf('line-1')!.settlement, const LineShopping());
      expect(await repo.load(run.id), changed);
    });

    test('a document another device wrote wins', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));
      final other = run.copyWith(portions: 2);
      await collection()
          .doc(run.id)
          .set(await sealed().seal(run.id, other.toJson()));

      expect(await repo.load(run.id), other);
      final changed = await repo.mutate(
        run.id,
        (r) => r.settle('line-1', const LineShopping()),
      );
      expect(changed.portions, 2);
    });

    test('a removed run stays gone', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));
      holding.waiting.clear();
      await collection().doc(run.id).delete();

      expect(await repo.load(run.id), isNull);
      await expectLater(
        repo.mutate(run.id, (r) => r.copyWith(portions: 2)),
        throwsA(isA<CookRunGoneException>()),
      );
    });

    test('stageDelete forgets the write', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));
      holding.holds = false;

      await repo.stageDelete(firestore.batch(), run.id);

      expect(await repo.load(run.id), run);
    });

    test('create forgets the write', () async {
      await repo.mutate(run.id, (r) => r.copyWith(portions: 8));

      await repo.create(run.copyWith(portions: 3));
      await settle(repo);

      expect(await repo.load(run.id), run);
    });
  });

  group('a write right after create', () {
    late _SlowFirestore slow;
    late CookRunRepository repo;
    final run = buildCookRun();

    setUp(() {
      slow = _SlowFirestore();
      firestore = slow;
      repo = repository();
    });

    test('a mutate while the create is still posted builds on the created '
        'run', () async {
      slow.slow = true;
      await repo.create(run);

      final changed = await repo.mutate(run.id, (r) => r.copyWith(portions: 8));

      expect(changed, run.copyWith(portions: 8));
      expect((await repo.load(run.id))!.portions, 8);
      await slow.landAll();
      expect((await repo.load(run.id))!.portions, 8);
    });

    test('once the create completed, a missing document means gone', () async {
      slow.slow = true;
      await repo.create(run);
      await slow.landAll();
      await collection().doc(run.id).delete();

      await expectLater(
        repo.mutate(run.id, (r) => r.copyWith(portions: 2)),
        throwsA(isA<CookRunGoneException>()),
      );
      expect(await repo.load(run.id), isNull);
    });

    test(
      'a run another device ended is gone, not the remembered create',
      () async {
        slow.slow = true;
        await repo.create(run);
        // A read shows a document: the run landed (the create's commit stays
        // open). Then another device ends it.
        await collection()
            .doc(run.id)
            .set(await sealed().seal(run.id, run.toJson()));
        expect(await repo.load(run.id), run);
        await collection().doc(run.id).delete();

        expect(await repo.load(run.id), isNull);
        await expectLater(
          repo.mutate(run.id, (r) => r.copyWith(portions: 2)),
          throwsA(isA<CookRunGoneException>()),
        );
      },
    );

    test('a mutate that changes nothing writes nothing', () async {
      await repo.create(run);
      await settle(repo);
      slow.slow = true;

      final same = await repo.mutate(run.id, (r) => r);

      expect(same, run);
      expect(slow.open, isEmpty);
    });
  });

  group('signed out', () {
    final signedOut = CookRunRepository(scope: null);

    test('reads nothing and writes throw', () async {
      expect(await signedOut.watchAll().toList(), [isEmpty]);
      expect(await signedOut.load('x'), isNull);
      expect(() => signedOut.create(buildCookRun()), throwsStateError);
      expect(() => signedOut.mutate('x', (r) => r), throwsStateError);
      expect(
        () => signedOut.stageDelete(firestore.batch(), 'x'),
        throwsStateError,
      );
    });
  });
}
