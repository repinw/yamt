import 'dart:async';

import 'package:file_share_intent/file_share_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/pending_shared_text.dart';
import 'package:yamt/core/device/pending_unreadable_share.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_service.dart';

class _FakeShareIntent extends FileShareIntent {
  new({this.initial = const [], this.initialError});

  final List<SharedMediaFile> initial;
  final Error? initialError;
  final _stream = StreamController<List<SharedMediaFile>>.broadcast();
  int resets = 0;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    if (initialError case final error?) throw error;
    return initial;
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() => _stream.stream;

  @override
  Future<dynamic> reset() async => resets++;

  void share(List<SharedMediaFile> files) => _stream.add(files);

  void failShare(Object error) => _stream.addError(error);

  bool get isListenedTo => _stream.hasListener;
}

const _inviteLink =
    'yamt://household/join?code=abcdefghij0123456789&secret=AAAA-BBBB';

SharedMediaFile _file(String path, SharedMediaType type) =>
    SharedMediaFile(path: path, type: type);

/// A container whose service listens to [intent], as on a phone.
Future<ProviderContainer> _start(_FakeShareIntent intent) async {
  final container = ProviderContainer(
    overrides: [fileShareIntentProvider.overrideWithValue(intent)],
  );
  addTearDown(container.dispose);
  container.listen(sharedReceiptServiceProvider, (_, _) {});
  await container.read(sharedReceiptServiceProvider.future);
  return container;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('shared text goes to the pending text, not to the receipts', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('200 g Mehl\nSalz', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), '200 g Mehl\nSalz');
    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    expect(intent.resets, greaterThan(0));
  });

  test('a shared link goes to the pending text', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('https://example.com/rezept', SharedMediaType.url)]);
    await _settle();

    expect(
      container.read(pendingSharedTextProvider),
      'https://example.com/rezept',
    );
    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
  });

  test('a title and a link shared together join into one text', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([
      _file('Bauerntopf', SharedMediaType.text),
      _file('https://example.com/topf', SharedMediaType.url),
    ]);
    await _settle();

    expect(
      container.read(pendingSharedTextProvider),
      'Bauerntopf\nhttps://example.com/topf',
    );
  });

  test('a receipt file still goes to the receipts, not to the text', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('/cache/receipt.pdf', SharedMediaType.pdf)]);
    await _settle();

    expect(container.read(pendingSharedReceiptPathsProvider), [
      '/cache/receipt.pdf',
    ]);
    expect(container.read(pendingSharedTextProvider), isNull);
  });

  test('text and a receipt shared together each go their way', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([
      _file('Einkauf', SharedMediaType.text),
      _file('/cache/receipt.jpg', SharedMediaType.image),
    ]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), 'Einkauf');
    expect(container.read(pendingSharedReceiptPathsProvider), [
      '/cache/receipt.jpg',
    ]);
  });

  test('text that names a receipt file is no receipt', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('see receipt.pdf', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    expect(container.read(pendingSharedTextProvider), 'see receipt.pdf');
  });

  test('text shared before the app started is taken from the initial '
      'media', () async {
    final intent = _FakeShareIntent(
      initial: [_file('https://example.com/rezept', SharedMediaType.url)],
    );
    final container = await _start(intent);

    expect(
      container.read(pendingSharedTextProvider),
      'https://example.com/rezept',
    );
    expect(intent.resets, 1);
  });

  test('blank shared text is left out', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('  ', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), isNull);
    expect(container.read(pendingUnreadableShareProvider), isTrue);
  });

  test(
    'a household invite that opened the app stays with the router',
    () async {
      final intent = _FakeShareIntent();
      final container = await _start(intent);

      intent.share([_file(_inviteLink, SharedMediaType.url)]);
      await _settle();

      expect(container.read(pendingSharedTextProvider), isNull);
      expect(container.read(pendingSharedReceiptPathsProvider), isNull);
      expect(container.read(pendingUnreadableShareProvider), isFalse);
    },
  );

  test('a household invite shared as text is no recipe text', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file(_inviteLink, SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), isNull);
    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
  });

  group('a household invite with words around it', () {
    for (final text in ['Hier: $_inviteLink', 'Haushalt\n$_inviteLink']) {
      test('is no recipe text and raises the signal: $text', () async {
        final intent = _FakeShareIntent();
        final container = await _start(intent);

        intent.share([_file(text, SharedMediaType.text)]);
        await _settle();

        expect(container.read(pendingSharedTextProvider), isNull);
        expect(container.read(pendingSharedReceiptPathsProvider), isNull);
        expect(container.read(pendingUnreadableShareProvider), isTrue);
      });
    }

    test('leaves the other text of the share', () async {
      final intent = _FakeShareIntent();
      final container = await _start(intent);

      intent.share([
        _file('200 g Mehl', SharedMediaType.text),
        _file('Hier: $_inviteLink', SharedMediaType.text),
      ]);
      await _settle();

      expect(container.read(pendingSharedTextProvider), '200 g Mehl');
    });
  });

  test('a receipt shared with a text arrives typed as text and still goes to '
      'the receipts', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('/cache/bon.pdf', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedReceiptPathsProvider), [
      '/cache/bon.pdf',
    ]);
    expect(container.read(pendingSharedTextProvider), isNull);
  });

  test('several receipts shared with a text all go to the receipts', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([
      _file('/cache/bon.pdf', SharedMediaType.text),
      _file('/cache/bon.JPG', SharedMediaType.text),
    ]);
    await _settle();

    expect(container.read(pendingSharedReceiptPathsProvider), [
      '/cache/bon.pdf',
      '/cache/bon.JPG',
    ]);
    expect(container.read(pendingSharedTextProvider), isNull);
  });

  test('a file of another kind shared with a text raises the signal', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('/cache/Mein Rezept.txt', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), isNull);
    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    expect(container.read(pendingUnreadableShareProvider), isTrue);
  });

  test(
    'of several files shared with a text, only the readable ones go on',
    () async {
      final intent = _FakeShareIntent();
      final container = await _start(intent);

      intent.share([
        _file('/cache/bon.jpg', SharedMediaType.text),
        _file('/cache/bon.heic', SharedMediaType.text),
      ]);
      await _settle();

      expect(container.read(pendingSharedReceiptPathsProvider), [
        '/cache/bon.jpg',
      ]);
      expect(container.read(pendingSharedTextProvider), isNull);
    },
  );

  test('a text that starts with a slash and a space stays text', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('/ 200 g Mehl', SharedMediaType.text)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), '/ 200 g Mehl');
  });

  test('a file we cannot read raises the signal', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.share([_file('/cache/rezept.txt', SharedMediaType.file)]);
    await _settle();

    expect(container.read(pendingSharedTextProvider), isNull);
    expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    expect(container.read(pendingUnreadableShareProvider), isTrue);
  });

  test('a readable share raises no signal', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent
      ..share([_file('200 g Mehl', SharedMediaType.text)])
      ..share([_file('/cache/receipt.pdf', SharedMediaType.pdf)]);
    await _settle();

    expect(container.read(pendingUnreadableShareProvider), isFalse);
  });

  test('an error on the share stream raises the signal', () async {
    final intent = _FakeShareIntent();
    final container = await _start(intent);

    intent.failShare(TypeError());
    await _settle();

    expect(container.read(pendingUnreadableShareProvider), isTrue);
  });

  test('a share that started the app and cannot be parsed raises the signal '
      'and is reset', () async {
    final intent = _FakeShareIntent(initialError: TypeError());
    final container = await _start(intent);

    expect(container.read(pendingUnreadableShareProvider), isTrue);
    expect(intent.resets, 1);
  });

  test('another setup failure raises no signal', () async {
    final intent = _FakeShareIntent(initialError: StateError('no channel'));
    final container = await _start(intent);

    expect(container.read(pendingUnreadableShareProvider), isFalse);
  });

  test('a start without a share raises no signal', () async {
    final container = await _start(_FakeShareIntent());

    expect(container.read(pendingUnreadableShareProvider), isFalse);
  });

  group('the share Android holds until the stream listens', () {
    const channel = MethodChannel('de.yamt.app/share_ready');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('arrives once the service says it listens', () async {
      final intent = _FakeShareIntent();
      final calls = <String>[];
      bool? listened;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        listened = intent.isListenedTo;
        intent.share([_file('200 g Mehl', SharedMediaType.text)]);
        return null;
      });

      final container = await _start(intent);
      await _settle();

      expect(calls, ['ready']);
      expect(listened, isTrue);
      expect(container.read(pendingSharedTextProvider), '200 g Mehl');
    });

    test('is asked for when the initial share fails as well', () async {
      final intent = _FakeShareIntent(initialError: StateError('no channel'));
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });

      await _start(intent);
      await _settle();

      expect(calls, ['ready']);
    });

    test('a failing channel leaves the initial share to be read', () async {
      final intent = _FakeShareIntent(
        initial: [_file('200 g Mehl', SharedMediaType.text)],
      );
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'failed'),
      );

      final container = await _start(intent);
      await _settle();

      expect(container.read(pendingSharedTextProvider), '200 g Mehl');
    });
  });
}
