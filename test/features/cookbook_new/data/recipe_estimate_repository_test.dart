import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

const _lines = ['1 Zwiebel', '200 ml Milch', 'Salz nach Geschmack'];

Map<String, Object?> _answer({
  Object status = 'ok',
  Object? kcal = 420.5,
  List<Object?>? lines,
}) => {
  'status': status,
  'kcal': kcal,
  'protein': 18,
  'carbs': 52.25,
  'fat': 14,
  'lines':
      lines ??
      [
        {'amount': 150, 'unit': 'g'},
        {'amount': 200, 'unit': 'ml'},
        {'amount': 0, 'unit': 'g'},
      ],
};

RecipeEstimateRepository _repository(
  Future<String?> Function(Map<String, Object?> inputs) client,
) => RecipeEstimateRepository(templateClient: client);

Future<RecipeEstimateAnswer> _load(RecipeEstimateRepository repository) =>
    repository.loadEstimate(
      name: 'Zwiebelsuppe',
      portions: 4,
      lines: _lines,
      now: _now,
    );

void main() {
  group('RecipeEstimateRepository.loadEstimate', () {
    test('sends the name, portions, and lines to the template', () async {
      Map<String, Object?>? sent;
      final repository = _repository((inputs) async {
        sent = inputs;
        return jsonEncode(_answer());
      });

      await _load(repository);

      expect(sent, {'name': 'Zwiebelsuppe', 'portions': 4, 'lines': _lines});
    });

    test(
      'reads the estimate of one portion for these lines and portions',
      () async {
        final repository = _repository((_) async => jsonEncode(_answer()));

        final answer = await _load(repository);

        final estimate = answer.estimate;
        expect(estimate.kcal, 420.5);
        expect(estimate.protein, 18);
        expect(estimate.carbs, 52.25);
        expect(estimate.fat, 14);
        expect(estimate.portions, 4);
        expect(estimate.createdAt, _now);
        expect(estimate.linesKey, recipeLinesKey(_lines));
        expect(estimate.isFor(_lines, 4), isTrue);
      },
    );

    test('reads one AI weight per line and none for a line without an '
        'amount', () async {
      final repository = _repository((_) async => jsonEncode(_answer()));

      final answer = await _load(repository);

      expect(answer.weights, [
        const RecipeLineWeight(
          amount: 150,
          unit: RecipeLineWeightUnit.gram,
          source: RecipeLineWeightSource.ai,
        ),
        const RecipeLineWeight(
          amount: 200,
          unit: RecipeLineWeightUnit.milliliter,
          source: RecipeLineWeightSource.ai,
        ),
        null,
      ]);
    });

    test('throws for an empty or missing answer', () {
      expect(_load(_repository((_) async => null)), throwsFormatException);
      expect(_load(_repository((_) async => '  ')), throwsFormatException);
    });

    test('throws when the AI cannot tell', () {
      final repository = _repository(
        (_) async => jsonEncode(_answer(status: 'not_a_recipe')),
      );

      expect(_load(repository), throwsFormatException);
    });

    test('throws when the answer has another number of lines', () {
      final repository = _repository(
        (_) async => jsonEncode(
          _answer(
            lines: [
              {'amount': 150, 'unit': 'g'},
            ],
          ),
        ),
      );

      expect(_load(repository), throwsFormatException);
    });

    test('throws for an unknown unit', () {
      final repository = _repository(
        (_) async => jsonEncode(
          _answer(
            lines: [
              {'amount': 150, 'unit': 'g'},
              {'amount': 2, 'unit': 'cup'},
              {'amount': 0, 'unit': 'g'},
            ],
          ),
        ),
      );

      expect(_load(repository), throwsFormatException);
    });

    test('throws for a negative number', () {
      final repository = _repository(
        (_) async => jsonEncode(_answer(kcal: -120)),
      );

      expect(_load(repository), throwsFormatException);
    });

    group('throws for an answer of another shape', () {
      final answers = <String, Object?>{
        'nothing but the status': {'status': 'ok'},
        'no number': _answer()..remove('kcal'),
        'a null number': _answer(kcal: null),
        'a number as text': _answer(kcal: '420'),
        'no lines': _answer()..remove('lines'),
        'lines that are no list': _answer()..['lines'] = 'none',
        'a line that is no map': _answer(lines: ['150 g', 200, null]),
        'a list instead of a map': [_answer()],
      };
      for (final MapEntry(key: name, value: answer) in answers.entries) {
        test(name, () {
          final repository = _repository((_) async => jsonEncode(answer));

          expect(_load(repository), throwsFormatException);
        });
      }
    });

    test('accepts 0 kcal, which water and salt really have', () async {
      final repository = _repository((_) async => jsonEncode(_answer(kcal: 0)));

      final answer = await _load(repository);

      expect(answer.estimate.kcal, 0);
    });

    test('lets a failing request through', () {
      final repository = _repository((_) async => throw StateError('offline'));

      expect(_load(repository), throwsStateError);
    });
  });
}
