import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/domain/cook_line_food.dart';

void main() {
  test('takes the capitalized word after amount and adjectives', () {
    expect(cookLineFood('1 mittlere Zwiebel'), 'Zwiebel');
    expect(cookLineFood('200 g Spaghetti Nudeln'), 'Spaghetti');
    expect(cookLineFood('1,5 kg Kartoffeln'), 'Kartoffeln');
    expect(cookLineFood('frisch gemahlener Pfeffer'), 'Pfeffer');
  });

  test('skips a measure word', () {
    expect(cookLineFood('1 Prise Salz'), 'Salz');
    expect(cookLineFood('2 EL Olivenöl'), 'Olivenöl');
    expect(cookLineFood('½ Bund Petersilie'), 'Petersilie');
    expect(cookLineFood('etwas Pfeffer'), 'Pfeffer');
    expect(cookLineFood('1 kleine Dose Tomaten'), 'Tomaten');
  });

  test('a lone word stays, even a measure word', () {
    expect(cookLineFood('Salz'), 'Salz');
    expect(cookLineFood('Prise'), 'Prise');
  });

  test('falls back to the first word when none is capitalized', () {
    expect(cookLineFood('2 tbsp olive oil'), 'olive');
    expect(cookLineFood('salt'), 'salt');
  });

  test('keeps the text when only an amount is left', () {
    expect(cookLineFood(' 1 '), '1');
    expect(cookLineFood(''), '');
  });
}
