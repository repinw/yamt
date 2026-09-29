import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/home/domain/home_action_ranking.dart';

void main() {
  test('picks the most tapped action among the ids', () {
    expect(
      mostUsedAction(
        {'barcode': 2, 'search': 5, 'other-tab': 9},
        ['barcode', 'search'],
      ),
      'search',
    );
  });

  test('a tie goes to the action that comes first', () {
    expect(mostUsedAction({'a': 3, 'b': 3}, ['b', 'a']), 'b');
  });

  test('returns null before any action was tapped', () {
    expect(mostUsedAction(const {}, ['a', 'b']), isNull);
  });
}
