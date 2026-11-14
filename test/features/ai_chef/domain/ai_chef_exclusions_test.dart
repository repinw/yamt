import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';

void main() {
  test('add trims the entry and keeps the order', () {
    final exclusions = AiChefExclusions.empty.add(' Koriander ').add('Rosinen');

    expect(exclusions.ingredients, ['Koriander', 'Rosinen']);
  });

  test('add ignores blank and repeated entries regardless of case', () {
    final exclusions = AiChefExclusions.empty.add('Koriander');

    expect(exclusions.add('   '), exclusions);
    expect(exclusions.add('koriander'), exclusions);
  });

  test('remove drops only the given entry', () {
    final exclusions = AiChefExclusions.empty
        .add('Koriander')
        .add('Rosinen')
        .remove('Koriander');

    expect(exclusions.ingredients, ['Rosinen']);
  });

  test('fromJson rejects a list of the wrong type', () {
    expect(
      () => AiChefExclusions.fromJson(<String, dynamic>{'ingredients': 'x'}),
      throwsA(isA<TypeError>()),
    );
  });
}
