import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';

void main() {
  test('a line not in the session is open', () {
    expect(const CookSession().lineOf('l1'), isA<LineOpen>());
  });

  test('withLine settles one line and keeps the others', () {
    final session = const CookSession()
        .withLine('l1', const LineAssigned([(itemId: 'a', amount: 5)]))
        .withLine('l2', const LineOmitted());

    expect(session.lineOf('l1'), isA<LineAssigned>());
    expect(session.lineOf('l2'), isA<LineOmitted>());
    expect(session.lineOf('l3'), isA<LineOpen>());
  });

  test('withLine moves a line to the second page and keeps it there', () {
    final session = const CookSession()
        .withLine('l1', const LineOmitted(), onSecondPage: true)
        .withLine('l1', const LineOpen());

    expect(session.isOnSecondPage('l1'), isTrue);
    expect(session.isOnSecondPage('l2'), isFalse);
  });

  test('a line settled on the first page stays on it', () {
    final session = const CookSession().withLine(
      'l1',
      const LineAssigned([(itemId: 'a', amount: 5)]),
    );
    expect(session.isOnSecondPage('l1'), isFalse);
  });

  test('withPortions opens every line but keeps step and pot', () {
    const pot = CookPotUtensil(utensilId: 'pot', emptyWeight: 900);
    final session = const CookSession(step: CookStep.pot, pot: pot)
        .withLine(
          'l1',
          const LineAssigned([(itemId: 'a', amount: 5)]),
          onSecondPage: true,
        )
        .withPortions(4);

    expect(session.portions, 4);
    expect(session.lines, isEmpty);
    expect(session.secondPage, isEmpty);
    expect(session.step, CookStep.pot);
    expect(session.pot, pot);
  });

  test('at and withPot change only their field', () {
    final session = const CookSession(portions: 3)
        .withLine('l1', const LineOmitted())
        .at(CookStep.found)
        .withPot(const CookPotNone());

    expect(session.step, CookStep.found);
    expect(session.pot, isA<CookPotNone>());
    expect(session.portions, 3);
    expect(session.lineOf('l1'), isA<LineOmitted>());
  });

  group('takenFrom', () {
    final session = const CookSession()
        .withLine(
          'l1',
          const LineAssigned([
            (itemId: 'a', amount: 100),
            (itemId: 'b', amount: 30),
          ]),
        )
        .withLine('l2', const LineAssigned([(itemId: 'a', amount: 50)]))
        .withLine('l3', const LineOmitted())
        .withLine('l4', const LineRejected());

    test('sums the takes of all assigned lines', () {
      expect(session.takenFrom('a'), 150);
      expect(session.takenFrom('b'), 30);
      expect(session.takenFrom('c'), 0);
    });

    test('leaves out the line asked about', () {
      expect(session.takenFrom('a', exceptLineId: 'l1'), 50);
      expect(session.takenFrom('a', exceptLineId: 'l2'), 100);
    });
  });
}
