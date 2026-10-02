import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/cooked_pot.dart';

CookedPot _pot(String grossInput, {int tareWeight = 1240}) => CookedPot(
  grossInput: grossInput,
  tareWeight: tareWeight,
  portions: 4,
  totalKcal: 1640,
);

void main() {
  test('food weight is the pot on the scale minus the empty pot', () {
    final pot = _pot('2420');

    expect(pot.netWeight, 1180);
    expect(pot.gramsPerPortion, 295);
    expect(pot.kcalPerPortion, 410);
    expect(pot.isTooLight, isFalse);
    expect(_pot('500', tareWeight: 0).netWeight, 500);
  });

  test('without weighing only the kcal per portion are known', () {
    final pot = _pot('');

    expect(pot.netWeight, isNull);
    expect(pot.gramsPerPortion, isNull);
    expect(pot.kcalPerPortion, 410);
    expect(pot.isTooLight, isFalse);
  });

  test('a pot not heavier than the empty pot is too light', () {
    expect(_pot('1240').isTooLight, isTrue);
    expect(_pot('900').isTooLight, isTrue);
    expect(_pot('0', tareWeight: 0).isTooLight, isTrue);
    expect(_pot('900').netWeight, isNull);
  });
}
