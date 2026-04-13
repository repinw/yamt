import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

abstract interface class GlobalBarcodeCandidateRepository {
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  });

  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  });
}
