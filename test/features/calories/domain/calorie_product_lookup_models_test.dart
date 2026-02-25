import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

CalorieProductProfile _profile({
  required String barcode,
  required String name,
  String? brand,
  double kcal = 0,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
}) {
  final now = DateTime(2026, 2, 25, 10);
  return CalorieProductProfile(
    barcode: barcode,
    name: name,
    brand: brand,
    per100Kcal: kcal,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    source: CalorieProductSource.offSearch,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('rankCalorieCandidates sorts by completeness then name', () {
    final profiles = <CalorieProductProfile>[
      _profile(barcode: '1', name: 'B', kcal: 90, protein: 4, carbs: 5, fat: 2),
      _profile(barcode: '2', name: 'A', kcal: 90, protein: 4, carbs: 5, fat: 2),
      _profile(barcode: '3', name: 'C', kcal: 0, protein: 0, carbs: 0, fat: 0),
    ];

    final ranked = rankCalorieCandidates(profiles);

    expect(ranked, hasLength(3));
    expect(ranked.first.profile.name, 'A');
    expect(ranked[1].profile.name, 'B');
    expect(ranked.last.profile.name, 'C');
  });

  test('lookup outcome factories set status and payload', () {
    final profile = _profile(barcode: '1', name: 'Milk', kcal: 64);
    final single = CalorieLookupOutcome.foundSingle(profile);
    final multi = CalorieLookupOutcome.foundMultiple(<CalorieProductCandidate>[
      CalorieProductCandidate(profile: profile, completenessScore: 7),
    ]);
    const missing = CalorieLookupOutcome.notFound();
    const failed = CalorieLookupOutcome.failed(errorCode: 'x');

    expect(single.status, CalorieLookupStatus.foundSingle);
    expect(single.product?.name, 'Milk');
    expect(multi.status, CalorieLookupStatus.foundMultiple);
    expect(multi.candidates, hasLength(1));
    expect(missing.status, CalorieLookupStatus.notFound);
    expect(failed.status, CalorieLookupStatus.failed);
    expect(failed.errorCode, 'x');
  });
}
