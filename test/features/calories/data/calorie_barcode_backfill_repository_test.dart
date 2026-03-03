import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository.dart';

class _FakeSession implements CalorieBarcodeBackfillUserSession {
  _FakeSession(this.currentUserId);

  @override
  final String? currentUserId;
}

void main() {
  test('enqueueFingerprintLookup requires signed-in user', () async {
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession(null),
      resolveInventoryItemCallable: (_) async => <String, dynamic>{
        'success': true,
      },
    );

    final queued = await repository.enqueueFingerprintLookup(
      itemId: 'item-1',
      fingerprint: 'milk__acme',
      itemName: 'Milk',
      brand: 'Acme',
      trigger: 'manual_search',
    );

    expect(queued, isFalse);
  });

  test('enqueueFingerprintLookup requires itemId', () async {
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      resolveInventoryItemCallable: (_) async => <String, dynamic>{
        'success': true,
      },
    );

    final queued = await repository.enqueueFingerprintLookup(
      fingerprint: 'milk__acme',
      itemName: 'Milk',
      brand: 'Acme',
      trigger: 'manual_search',
    );

    expect(queued, isFalse);
  });

  test('enqueueFingerprintLookup calls direct resolver callable', () async {
    Map<String, dynamic>? payload;
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      resolveInventoryItemCallable: (data) async {
        payload = Map<String, dynamic>.from(data);
        return <String, dynamic>{'success': true, 'found': true};
      },
    );

    final queued = await repository.enqueueFingerprintLookup(
      itemId: 'item-1',
      fingerprint: 'milk__acme',
      itemName: 'Milk',
      brand: 'Acme',
      trigger: 'manual_search',
    );

    expect(queued, isTrue);
    expect(payload, isNotNull);
    expect(payload?['itemId'], 'item-1');
    expect(payload?['fingerprint'], 'milk__acme');
    expect(payload?['itemName'], 'Milk');
    expect(payload?['brand'], 'Acme');
    expect(payload?['trigger'], 'manual_search');
  });

  test('fallback APIs are no-op in direct mode', () async {
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      resolveInventoryItemCallable: (_) async => <String, dynamic>{
        'success': true,
      },
    );

    final resolved = await repository.getResolvedProfileByFingerprint(
      'milk__acme',
    );
    final submitted = await repository.submitUserProvidedBarcode(
      fingerprint: 'milk__acme',
      barcode: '4006381333931',
      itemName: 'Milk',
      brand: 'Acme',
    );

    expect(resolved, isNull);
    expect(submitted, isTrue);
  });
}
