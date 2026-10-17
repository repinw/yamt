import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/core/device/document_scanner.dart';

class _FakePicker extends Fake implements ImagePicker {
  int calls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    return XFile('/tmp/fallback.jpg');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cunning_document_scanner');

  void answerScanner(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => answerScanner((_) async => null));

  test('returns the scanned pages', () async {
    late MethodCall request;
    answerScanner((call) async {
      request = call;
      return ['/tmp/a.jpg', '/tmp/b.jpg'];
    });
    final picker = _FakePicker();

    final pages = await scanDocumentPages(maxPages: 3, fallbackPicker: picker);

    expect(pages, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect((request.arguments as Map)['noOfPages'], 3);
    expect(picker.calls, 0);
  });

  test('a canceled scan returns null without the camera', () async {
    answerScanner((_) async => null);
    final picker = _FakePicker();

    expect(
      await scanDocumentPages(maxPages: 1, fallbackPicker: picker),
      isNull,
    );
    expect(picker.calls, 0);
  });

  test('a failing scanner falls back to a camera photo', () async {
    answerScanner((_) async => throw PlatformException(code: 'unavailable'));
    final picker = _FakePicker();

    final pages = await scanDocumentPages(maxPages: 1, fallbackPicker: picker);

    expect(pages, ['/tmp/fallback.jpg']);
    expect(picker.calls, 1);
  });

  test('a scan already running returns null without the camera', () async {
    answerScanner((_) async => throw PlatformException(code: 'ALREADY_ACTIVE'));
    final picker = _FakePicker();

    expect(
      await scanDocumentPages(maxPages: 1, fallbackPicker: picker),
      isNull,
    );
    expect(picker.calls, 0);
  });

  test('a denied camera throws without the camera', () async {
    answerScanner(
      (_) async => throw PlatformException(code: 'permission_denied'),
    );
    final picker = _FakePicker();

    await expectLater(
      scanDocumentPages(maxPages: 1, fallbackPicker: picker),
      throwsA(isA<CunningDocumentScannerException>()),
    );
    expect(picker.calls, 0);
  });
}
