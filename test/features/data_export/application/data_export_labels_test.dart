import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  late DataExportLabels labels;

  setUpAll(() async {
    labels = await englishLabels();
  });

  test('names a food with its brand', () {
    expect(labels.foodName(oatEntry()), 'Oats (Farm & <Co>)');
    expect(labels.foodName(oatEntry(), withBrand: false), 'Oats');
    expect(labels.foodName(oatEntry(brand: '  ')), 'Oats');
  });

  test('keeps a name with line breaks on one line', () {
    final entry = oatEntry(brand: 'Farm\n\tCo')
        .copyWith(name: '  # Oats\n\nfine  ');

    expect(labels.foodName(entry), '# Oats fine (Farm Co)');
  });

  test('marks a food whose nutrition is still open', () {
    final entry = oatEntry(brand: null).copyWith(nutritionPending: true);

    expect(labels.foodName(entry), labels.l10n.dataExportFoodPending('Oats'));
  });
}
