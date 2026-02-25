import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

class CalorieEntryCreateArgs {
  const CalorieEntryCreateArgs({
    required this.prefilledProfile,
    this.scannedSourceRef,
  });

  final CalorieProductProfile? prefilledProfile;
  final CalorieScannedSourceRef? scannedSourceRef;
}
