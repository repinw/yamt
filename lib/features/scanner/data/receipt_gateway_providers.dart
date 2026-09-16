import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_product_resolver.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/data/google_ai_receipt_parser.dart';
import 'package:yamt/features/scanner/data/ml_kit_receipt_text_extractor.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_structured_parser.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_text_extractor.dart';

part 'receipt_gateway_providers.g.dart';

/// Provider for [ReceiptProductResolver].
///
/// Uses [YamtReceiptProductResolver] by default in production.
@riverpod
ReceiptProductResolver receiptProductResolver(Ref ref) {
  return YamtReceiptProductResolver(
    matcher: ref.watch(globalFoodItemMatcherProvider),
    searchRepository: ref.watch(offProductSearchRepositoryProvider),
  );
}

/// Provider for [ReceiptStorageGateway].
///
/// Uses [YamtReceiptStorageGateway] by default in production.
@riverpod
ReceiptStorageGateway receiptStorageGateway(Ref ref) {
  return YamtReceiptStorageGateway(
    inventoryItemRepository: ref.watch(inventoryItemRepositoryProvider),
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    globalFoodReceiptAliasRepository: ref.watch(
      globalFoodReceiptAliasRepositoryProvider,
    ),
  );
}

/// Provider for [ReceiptTextExtractor].
///
/// Uses [MlKitReceiptTextExtractor] for on-device OCR by default.
/// Disposes native resources on provider disposal.
@riverpod
ReceiptTextExtractor receiptTextExtractor(Ref ref) {
  final extractor = MlKitReceiptTextExtractor();
  ref.onDispose(extractor.dispose);
  return extractor;
}

/// Provider for [ReceiptStructuredParser].
///
/// Uses [GoogleAiReceiptParser] powered by the Google AI API (Gemini Flash).
@riverpod
ReceiptStructuredParser receiptStructuredParser(Ref ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError(
      'GEMINI_API_KEY is not configured. Provide it via '
      '--dart-define=GEMINI_API_KEY=... or override '
      'receiptStructuredParserProvider.',
    );
  }
  return GoogleAiReceiptParser(apiKey: apiKey);
}

/// Provider for [ReceiptManualProductPicker].
///
/// Uses [YamtReceiptManualProductPicker] by default in production.
@riverpod
ReceiptManualProductPicker receiptManualProductPicker(Ref ref) {
  return const YamtReceiptManualProductPicker();
}
