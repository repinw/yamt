import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/receipt_input_repository.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/provider/receipt_input_capabilities.dart';
import 'package:yamt/features/inventory/provider/receipt_input_controller.dart';

class _FakeReceiptInputRepository implements ReceiptInputRepository {
  _FakeReceiptInputRepository({this.pickCamera, this.pickFile});

  final Future<ReceiptInputResult> Function()? pickCamera;
  final Future<ReceiptInputResult> Function()? pickFile;

  @override
  Future<ReceiptInputResult> pickFromCamera() {
    if (pickCamera != null) {
      return pickCamera!();
    }

    return Future<ReceiptInputResult>.value(
      const ReceiptInputResult.canceled(),
    );
  }

  @override
  Future<ReceiptInputResult> pickFromFile() {
    if (pickFile != null) {
      return pickFile!();
    }

    return Future<ReceiptInputResult>.value(
      const ReceiptInputResult.canceled(),
    );
  }
}

ReceiptInputResult _selectedResult(ReceiptInputSource source) {
  return ReceiptInputResult.selected(
    selection: ReceiptInputSelection(
      source: source,
      name: 'receipt.jpg',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    ),
  );
}

void main() {
  test('camera success returns selected result and updates state', () async {
    final repository = _FakeReceiptInputRepository(
      pickCamera: () async => _selectedResult(ReceiptInputSource.camera),
    );
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(repository),
        receiptCameraSupportedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptInputControllerProvider.notifier)
        .pickFromCamera();

    expect(result.status, ReceiptInputStatus.selected);
    expect(result.selection?.source, ReceiptInputSource.camera);
    expect(container.read(receiptInputControllerProvider).value, result);
  });

  test('file success returns selected result and updates state', () async {
    final repository = _FakeReceiptInputRepository(
      pickFile: () async => _selectedResult(ReceiptInputSource.file),
    );
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(repository),
        receiptCameraSupportedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptInputControllerProvider.notifier)
        .pickFromFile();

    expect(result.status, ReceiptInputStatus.selected);
    expect(result.selection?.source, ReceiptInputSource.file);
    expect(container.read(receiptInputControllerProvider).value, result);
  });

  test('camera canceled returns canceled result', () async {
    final repository = _FakeReceiptInputRepository(
      pickCamera: () async => const ReceiptInputResult.canceled(),
    );
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(repository),
        receiptCameraSupportedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptInputControllerProvider.notifier)
        .pickFromCamera();

    expect(result.status, ReceiptInputStatus.canceled);
    expect(container.read(receiptInputControllerProvider).value, result);
  });

  test('camera unsupported result is returned by capability policy', () async {
    final repository = _FakeReceiptInputRepository();
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(repository),
        receiptCameraSupportedProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(receiptInputControllerProvider.notifier);
    final result = await notifier.pickFromCamera();

    expect(notifier.isCameraSupported, isFalse);
    expect(result.status, ReceiptInputStatus.unsupported);
    expect(result.errorCode, ReceiptInputErrorCodes.cameraNotSupported);
  });

  test('camera exception is mapped to failed result', () async {
    final repository = _FakeReceiptInputRepository(
      pickCamera: () => throw Exception('boom'),
    );
    final container = ProviderContainer(
      overrides: [
        receiptInputRepositoryProvider.overrideWithValue(repository),
        receiptCameraSupportedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptInputControllerProvider.notifier)
        .pickFromCamera();

    expect(result.status, ReceiptInputStatus.failed);
    expect(result.errorCode, ReceiptInputErrorCodes.cameraPickUnexpected);
    expect(container.read(receiptInputControllerProvider).value, result);
  });
}
