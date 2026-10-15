import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/exclusive_runner.dart';

void main() {
  test('a call while an action runs does not run', () async {
    final runner = ExclusiveRunner();
    final gate = Completer<void>();
    var runs = 0;

    final first = runner.run(() async {
      runs++;
      await gate.future;
    });
    final second = runner.run(() async => runs++);
    gate.complete();

    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(runs, 1);
  });

  test('the runner is free again after the action completed', () async {
    final runner = ExclusiveRunner();
    var runs = 0;

    await runner.run(() async => runs++);
    final ran = await runner.run(() async => runs++);

    expect(ran, isTrue);
    expect(runs, 2);
  });

  test('the runner is free again after the action failed', () async {
    final runner = ExclusiveRunner();

    await expectLater(
      runner.run(() async => throw StateError('failed')),
      throwsStateError,
    );

    expect(await runner.run(() async {}), isTrue);
  });

  test('two runners do not block each other', () async {
    final first = ExclusiveRunner();
    final gate = Completer<void>();

    final running = first.run(() => gate.future);
    final ran = await ExclusiveRunner().run(() async {});
    gate.complete();

    expect(ran, isTrue);
    expect(await running, isTrue);
  });
}
