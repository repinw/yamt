import 'dart:async';
import 'dart:io';

import 'package:file_share_intent/file_share_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/application/shared_receipt_service.dart';
import 'package:yamt/features/scanner/provider/'
    'pending_shared_receipt_intent.dart';

class _FakeFileShareIntent extends FileShareIntent {
  _FakeFileShareIntent({
    List<SharedMediaFile>? initialMedia,
    Stream<List<SharedMediaFile>>? mediaStream,
    this.throwMissingPluginOnInitialMedia = false,
  }) : _initialMedia = initialMedia ?? const <SharedMediaFile>[],
       _mediaStream =
           mediaStream ?? const Stream<List<SharedMediaFile>>.empty();

  final List<SharedMediaFile> _initialMedia;
  final Stream<List<SharedMediaFile>> _mediaStream;
  final bool throwMissingPluginOnInitialMedia;

  int resetCallCount = 0;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    if (throwMissingPluginOnInitialMedia) {
      throw MissingPluginException('plugin missing');
    }
    return List<SharedMediaFile>.from(_initialMedia);
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    return _mediaStream;
  }

  @override
  Future<dynamic> reset() async {
    resetCallCount += 1;
  }
}

SharedMediaFile _sharedImage(String path) {
  return SharedMediaFile(
    path: path,
    type: SharedMediaType.image,
    mimeType: 'image/jpeg',
  );
}

Future<void> _drainAsyncQueue() async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitForPendingIntent(ProviderContainer container) async {
  for (var index = 0; index < 50; index++) {
    if (container.read(pendingSharedReceiptIntentProvider) != null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for pending shared receipt intent.');
}

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('loads initial shared media into the pending provider', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'shared-receipt-service-test',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final sharedImageFile = File('${tempDir.path}/shared_receipt.jpg');
    await sharedImageFile.writeAsBytes(<int>[0x01, 0x02, 0x03]);

    final fakePlugin = _FakeFileShareIntent(
      initialMedia: <SharedMediaFile>[_sharedImage(sharedImageFile.path)],
    );
    final container = ProviderContainer(
      overrides: [
        fileShareIntentProvider.overrideWithValue(fakePlugin),
      ],
    );
    addTearDown(container.dispose);

    final pendingSubscription = container.listen(
      pendingSharedReceiptIntentProvider,
      (_, _) {},
    );
    addTearDown(pendingSubscription.close);

    await container.read(sharedReceiptServiceProvider.future);

    final pendingIntent = container.read(pendingSharedReceiptIntentProvider);
    expect(pendingIntent, isNotNull);
    expect(pendingIntent!.selections, hasLength(1));
    expect(pendingIntent.selections.single.name, 'shared_receipt.jpg');
    expect(fakePlugin.resetCallCount, 1);
  });

  test('keeps valid shared files when one stream file fails to load', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'shared-receipt-service-test',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final sharedImageFile = File('${tempDir.path}/shared_receipt.jpg');
    await sharedImageFile.writeAsBytes(<int>[0x01, 0x02, 0x03]);

    final mediaController = StreamController<List<SharedMediaFile>>.broadcast();
    addTearDown(mediaController.close);

    final fakePlugin = _FakeFileShareIntent(
      mediaStream: mediaController.stream,
    );
    final container = ProviderContainer(
      overrides: [
        fileShareIntentProvider.overrideWithValue(fakePlugin),
      ],
    );
    addTearDown(container.dispose);

    final pendingSubscription = container.listen(
      pendingSharedReceiptIntentProvider,
      (_, _) {},
    );
    addTearDown(pendingSubscription.close);

    await container.read(sharedReceiptServiceProvider.future);

    mediaController.add(<SharedMediaFile>[
      _sharedImage('${tempDir.path}/missing.jpg'),
      _sharedImage(sharedImageFile.path),
    ]);
    await _drainAsyncQueue();
    await _waitForPendingIntent(container);

    final pendingIntent = container.read(pendingSharedReceiptIntentProvider);
    expect(pendingIntent, isNotNull);
    expect(pendingIntent!.selections, hasLength(1));
    expect(pendingIntent.selections.single.name, 'shared_receipt.jpg');
    expect(fakePlugin.resetCallCount, 2);
  });

  test('handles MissingPluginException during service setup', () async {
    final fakePlugin = _FakeFileShareIntent(
      throwMissingPluginOnInitialMedia: true,
    );
    final container = ProviderContainer(
      overrides: [
        fileShareIntentProvider.overrideWithValue(fakePlugin),
      ],
    );
    addTearDown(container.dispose);

    final pendingSubscription = container.listen(
      pendingSharedReceiptIntentProvider,
      (_, _) {},
    );
    addTearDown(pendingSubscription.close);

    await container.read(sharedReceiptServiceProvider.future);

    expect(container.read(pendingSharedReceiptIntentProvider), isNull);
  });
}
