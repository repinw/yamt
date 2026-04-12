import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';

/// Persists store-specific OCR aliases that point to shared global items.
abstract interface class GlobalFoodReceiptAliasRepository {
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  });

  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases);
}
