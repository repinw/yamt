import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/domain/cook_voice_command.dart';

void main() {
  group('navigation and undo', () {
    final cases = <String, CookVoiceCommand>{
      'weiter': const CookVoiceNext(),
      'Weiter.': const CookVoiceNext(),
      '  next  ': const CookVoiceNext(),
      'next step': const CookVoiceNext(),
      'Nächster Schritt': const CookVoiceNext(),
      'nächsten Schritt': const CookVoiceNext(),
      'zurückgehen': const CookVoiceBack(),
      'vorherigen Schritt': const CookVoiceBack(),
      'zurück': const CookVoiceBack(),
      'Zurück!': const CookVoiceBack(),
      'back': const CookVoiceBack(),
      'previous step': const CookVoiceBack(),
      'nein': const CookVoiceUndo(),
      'Nein.': const CookVoiceUndo(),
      'weg': const CookVoiceUndo(),
      'no': const CookVoiceUndo(),
      'undo': const CookVoiceUndo(),
    };
    for (final MapEntry(key: heard, value: expected) in cases.entries) {
      test('"$heard"', () => expect(parseCookVoiceCommand(heard), expected));
    }
  });

  group('timer', () {
    final cases = <String, Duration>{
      'Timer 10 Minuten': const Duration(minutes: 10),
      'Stell einen Timer auf 5 Minuten': const Duration(minutes: 5),
      'set a timer for 5 minutes': const Duration(minutes: 5),
      'Wecker 30 Sekunden': const Duration(seconds: 30),
      'Timer 1 Stunde': const Duration(hours: 1),
      'Timer 10 bis 15 Minuten': const Duration(minutes: 10),
      'Timer fünf Minuten': const Duration(minutes: 5),
      'Timer eine halbe Stunde': const Duration(minutes: 30),
    };
    for (final MapEntry(key: heard, value: expected) in cases.entries) {
      test('"$heard"', () {
        expect(parseCookVoiceCommand(heard), CookVoiceTimer(expected));
      });
    }

    test('"Timer" without a duration says nothing', () {
      expect(parseCookVoiceCommand('Timer'), isNull);
      expect(parseCookVoiceCommand('Timer bitte'), isNull);
    });
  });

  group('new lines', () {
    final cases = <String, List<String>>{
      '200 g Sahne': ['200 g Sahne'],
      '200 g Sahne und Salz': ['200 g Sahne', 'Salz'],
      'rice and beans': ['rice', 'beans'],
      'Reis, Bohnen, Mais': ['Reis', 'Bohnen', 'Mais'],
      '1,5 kg Mehl': ['1,5 kg Mehl'],
      '1,5 kg Mehl und 2,5 l Milch': ['1,5 kg Mehl', '2,5 l Milch'],
      'Zwiebeln,Knoblauch': ['Zwiebeln', 'Knoblauch'],
      'Sahne UND Salz': ['Sahne', 'Salz'],
      'Salz.': ['Salz'],
      'Sahne und': ['Sahne'],
      'Mandeln': ['Mandeln'],
    };
    for (final MapEntry(key: heard, value: expected) in cases.entries) {
      test('"$heard"', () {
        expect(parseCookVoiceCommand(heard), CookVoiceAddLines(expected));
      });
    }

    group('a part that is only an amount joins the part before it', () {
      final joins = {
        'Öl, 30 g': ['Öl 30 g'],
        'Öl,30 g': ['Öl 30 g'],
        'Öl, 30': ['Öl 30 g'],
        'Öl, 30 Gramm': ['Öl 30 Gramm'],
        'Mehl, 1,5 kg': ['Mehl 1,5 kg'],
        'Mehl, ein Kilo': ['Mehl 1 kg'],
        'Milch, 500 Milliliter': ['Milch 500 ml'],
        'Hack, 1 Pfund': ['Hack 500 g'],
        'Reis, 200 g, Salz': ['Reis 200 g', 'Salz'],
        'Salz, Reis, 200 g': ['Salz', 'Reis 200 g'],
        'Öl, 2 EL': ['2 EL Öl'],
        '2 Dosen Tomaten, je 400 g': ['2 Dosen Tomaten je 400 g'],
      };
      for (final MapEntry(key: heard, value: expected) in joins.entries) {
        test('"$heard"', () {
          expect(parseCookVoiceCommand(heard), CookVoiceAddLines(expected));
        });
      }
    });

    group('other parts stay their own lines', () {
      final parts = {
        'Zwiebeln, Knoblauch': ['Zwiebeln', 'Knoblauch'],
        '2 Zwiebeln, 3 Möhren': ['2 Zwiebeln', '3 Möhren'],
        '30 g Öl, 200 g Reis': ['30 g Öl', '200 g Reis'],
        // The part before already has its amount.
        'Reis 200 g, 30': ['Reis 200 g', '30'],
        // Only a comma joins.
        'Öl und 30 g': ['Öl', '30 g'],
      };
      for (final MapEntry(key: heard, value: expected) in parts.entries) {
        test('"$heard"', () {
          expect(parseCookVoiceCommand(heard), CookVoiceAddLines(expected));
        });
      }
    });

    test('keeps the case as said', () {
      final command = parseCookVoiceCommand('Rote Bete')! as CookVoiceAddLines;
      expect(command.lines, ['Rote Bete']);
    });

    test('the lines cannot be changed afterwards', () {
      final command = parseCookVoiceCommand('a und b')! as CookVoiceAddLines;
      expect(() => command.lines.add('c'), throwsUnsupportedError);
    });

    test('words that only contain a command word are lines', () {
      expect(
        parseCookVoiceCommand('Nein danke'),
        CookVoiceAddLines(const ['Nein danke']),
      );
      expect(
        parseCookVoiceCommand('Weiter so'),
        CookVoiceAddLines(const ['Weiter so']),
      );
    });
  });

  group('nothing', () {
    for (final heard in ['', '   ', '.', '!?', 'und', ' , ']) {
      test('"$heard"', () => expect(parseCookVoiceCommand(heard), isNull));
    }
  });
}
