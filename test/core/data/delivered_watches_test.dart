import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/delivered_watches.dart';

void main() {
  test('counts a watch from its first value until it is canceled', () async {
    final watches = DeliveredWatches();
    final source = StreamController<int>();
    final subscription = watches.track(source.stream).listen((_) {});

    expect(watches.any, isFalse);
    source.add(1);
    await pumpEventQueue();
    expect(watches.any, isTrue);

    await subscription.cancel();
    expect(watches.any, isFalse);
  });

  test('stops counting a watch when its source ends', () async {
    final watches = DeliveredWatches();
    final source = StreamController<int>();
    watches.track(source.stream).listen((_) {});

    source.add(1);
    await pumpEventQueue();
    await source.close();
    await pumpEventQueue();

    expect(watches.any, isFalse);
  });
}
