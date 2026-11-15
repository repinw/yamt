import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/domain/cook_duration.dart';

Duration _m(num minutes) => Duration(seconds: (minutes * 60).round());

void main() {
  group('cookDurationsIn', () {
    final cases = <String, List<CookDuration>>{
      'Nudeln 10 Minuten kochen': [(shortest: _m(10), longest: _m(10))],
      'Cook for 10 min.': [(shortest: _m(10), longest: _m(10))],
      'Simmer for 2 hours': [(shortest: _m(120), longest: _m(120))],
      'Bei 180 Grad 1 Stunde backen': [(shortest: _m(60), longest: _m(60))],
      '30 Sekunden braten': [
        (
          shortest: const Duration(seconds: 30),
          longest: const Duration(seconds: 30),
        ),
      ],
      '1 Stunde 20 Minuten garen': [(shortest: _m(80), longest: _m(80))],
      '1 hour 20 minutes': [(shortest: _m(80), longest: _m(80))],
      '1 hour and 20 minutes': [(shortest: _m(80), longest: _m(80))],
      '10–15 Minuten köcheln': [(shortest: _m(10), longest: _m(15))],
      '10 bis 15 Min. ziehen': [(shortest: _m(10), longest: _m(15))],
      '10-15 minutes': [(shortest: _m(10), longest: _m(15))],
      '5 to 7 minutes': [(shortest: _m(5), longest: _m(7))],
      'eine halbe Stunde': [(shortest: _m(30), longest: _m(30))],
      'anderthalb Stunden': [(shortest: _m(90), longest: _m(90))],
      '2,5 Stunden': [(shortest: _m(150), longest: _m(150))],
      'half an hour': [(shortest: _m(30), longest: _m(30))],
      '1/2 Stunde köcheln': [(shortest: _m(30), longest: _m(30))],
      '3/4 Stunde backen': [(shortest: _m(45), longest: _m(45))],
      '1 1/2 Stunden schmoren': [(shortest: _m(90), longest: _m(90))],
      'fünf Minuten ruhen': [(shortest: _m(5), longest: _m(5))],
      'zwölf Minuten backen': [(shortest: _m(12), longest: _m(12))],
      'zwei bis drei Minuten': [(shortest: _m(2), longest: _m(3))],
      'ten minutes': [(shortest: _m(10), longest: _m(10))],
      'Erst 5 Minuten braten, dann 20 Minuten backen': [
        (shortest: _m(5), longest: _m(5)),
        (shortest: _m(20), longest: _m(20)),
      ],
    };
    for (final MapEntry(key: sentence, value: expected) in cases.entries) {
      test('"$sentence"', () => expect(cookDurationsIn(sentence), expected));
    }

    for (final sentence in [
      'über Nacht ruhen lassen',
      'kurz anbraten',
      'Um 18 Uhr servieren',
      'um 6 Uhr',
      'at 6 serve',
      'Salz und Pfeffer',
      'mindestens 10 mindestens',
      'achtzig Minuten',
      'zweimal umrühren',
      '',
    ]) {
      test('"$sentence" names no duration', () {
        expect(cookDurationsIn(sentence), isEmpty);
      });
    }

    test('a clock time does not hide a later duration', () {
      expect(cookDurationsIn('Um 18 Uhr 10 Minuten warten'), [
        (shortest: _m(10), longest: _m(10)),
      ]);
      expect(cookDurationsIn('Um 18 Uhr servieren, 10 Minuten ruhen'), [
        (shortest: _m(10), longest: _m(10)),
      ]);
    });

    test('a range that runs backwards is no duration', () {
      expect(cookDurationsIn('15–10 Minuten'), isEmpty);
    });
  });

  group('cookTimerSteps', () {
    test('a single duration offers itself', () {
      expect(cookTimerSteps((shortest: _m(10), longest: _m(10))), [_m(10)]);
    });

    test('a range offers both bounds', () {
      expect(cookTimerSteps((shortest: _m(10), longest: _m(15))), [
        _m(10),
        _m(15),
      ]);
    });
  });
}
