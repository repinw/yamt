import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_catalog_service.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

import '../../product_search_hub/support/fake_product_search_sources.dart';

void main() {
  final now = DateTime(2026, 10, 19);
  final product = GlobalFoodItem.create(
    id: 'off-4006381333931-muesli',
    name: 'Muesli',
    barcode: '4006381333931',
    now: now,
  );

  late _FakeCatalog catalog;
  late _RecordingBarcodeCandidates barcodes;

  ManualProductCatalogService service() => ManualProductCatalogService(
    globalFoods: catalog,
    barcodeCandidates: barcodes,
  );

  setUp(() {
    catalog = _FakeCatalog();
    barcodes = _RecordingBarcodeCandidates();
  });

  Future<void> share({required bool append}) => service().share(
    product: product,
    append: append,
    barcode: '4006381333931',
    selectedAt: now,
  );

  test('records the barcode once the catalog has the product', () async {
    await share(append: true);

    expect(catalog.appendedItems, [product]);
    expect(barcodes.recorded, ['4006381333931']);
  });

  test(
    'throws and records no barcode when the catalog write fails (#806)',
    () async {
      catalog.succeeds = false;

      await expectLater(share(append: true), throwsStateError);
      expect(barcodes.recorded, isEmpty);
    },
  );

  test('throws when the barcode fails', () async {
    barcodes.fails = true;

    await expectLater(share(append: true), throwsStateError);
    expect(catalog.appendedItems, [product]);
  });

  test(
    'records the barcode of a picked catalog product without a write',
    () async {
      await share(append: false);

      expect(catalog.appendedItems, isEmpty);
      expect(barcodes.recorded, ['4006381333931']);
    },
  );
}

class _FakeCatalog extends FakeGlobalFoodItemRepository {
  bool succeeds = true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async =>
      succeeds && await super.appendAll(items);
}

class _RecordingBarcodeCandidates implements GlobalBarcodeCandidateRepository {
  final recorded = <String>[];
  bool fails = false;

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async => const <GlobalBarcodeCandidate>[];

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    if (fails) {
      throw StateError('offline');
    }
    recorded.add(barcode);
  }
}
