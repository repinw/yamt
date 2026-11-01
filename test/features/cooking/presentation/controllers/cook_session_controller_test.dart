import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_session_controller.dart';

void main() {
  late ProviderContainer container;
  late CookSessionController controller;

  CookSession state() => container.read(cookSessionControllerProvider('r1'));

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    // Keeps the session alive between reads, as the open page does.
    container.listen(cookSessionControllerProvider('r1'), (_, _) {});
    controller = container.read(cookSessionControllerProvider('r1').notifier);
  });

  test('starts on the recipe with the recipe portions and no choices', () {
    expect(state().step, CookStep.recipe);
    expect(state().portions, isNull);
    expect(state().lines, isEmpty);
    expect(state().pot, isNull);
  });

  test('every recipe has its own session', () {
    controller.setPortions(5);

    expect(
      container.read(cookSessionControllerProvider('r2')).portions,
      isNull,
    );
  });

  test('setPortions opens every line again', () {
    controller
      ..assign('l1', const [(itemId: 'a', amount: 10)])
      ..omit('l2')
      ..setPortions(3);

    expect(state().portions, 3);
    expect(state().lines, isEmpty);
  });

  test('setPortions ignores less than one portion', () {
    controller
      ..setPortions(3)
      ..setPortions(0);

    expect(state().portions, 3);
  });

  test('assign settles a line with its takes', () {
    controller.assign('l1', const [(itemId: 'a', amount: 10)]);

    final line = state().lineOf('l1');
    expect(line, isA<LineAssigned>());
    expect((line as LineAssigned).takes, [(itemId: 'a', amount: 10)]);
    expect(state().isOnSecondPage('l1'), isFalse);
  });

  test('assign on the second page keeps the line there', () {
    controller.assign('l1', const [
      (itemId: 'a', amount: 10),
    ], onSecondPage: true);

    expect(state().isOnSecondPage('l1'), isTrue);
  });

  test('assigned takes cannot be changed afterwards', () {
    final takes = [(itemId: 'a', amount: 10)];
    controller.assign('l1', takes);

    expect(
      () => (state().lineOf('l1') as LineAssigned).takes.add((
        itemId: 'b',
        amount: 1,
      )),
      throwsUnsupportedError,
    );
  });

  test('reject turns a suggestion down, reopen undoes any choice', () {
    controller.reject('l1');
    expect(state().lineOf('l1'), isA<LineRejected>());

    controller.reopen('l1');
    expect(state().lineOf('l1'), isA<LineOpen>());
  });

  test('omit leaves a line out and puts it on the second page', () {
    controller.omit('l1');

    expect(state().lineOf('l1'), isA<LineOmitted>());
    expect(state().isOnSecondPage('l1'), isTrue);
  });

  test('goTo moves between steps and choosePot sets the pot', () {
    controller
      ..goTo(CookStep.pot)
      ..choosePot(const CookPotUtensil(utensilId: 'pot', emptyWeight: 900));

    expect(state().step, CookStep.pot);
    expect((state().pot! as CookPotUtensil).emptyWeight, 900);
  });
}
