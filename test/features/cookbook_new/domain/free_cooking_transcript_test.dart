import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_transcript.dart';

void main() {
  test('starts a new row before each amount', () {
    expect(
      splitFreeCookingTranscript('500 g Hähnchen 40 g Butter 200 g Reis'),
      ['500 g Hähnchen', '40 g Butter', '200 g Reis'],
    );
  });

  test('keeps a mixed fraction and a decimal amount together', () {
    expect(splitFreeCookingTranscript('1 1/2 kg Kartoffeln 1,5 l Brühe'), [
      '1 1/2 kg Kartoffeln',
      '1,5 l Brühe',
    ]);
  });

  test('splits at commas, line breaks, and "und"', () {
    expect(
      splitFreeCookingTranscript('Salz, Pfeffer\n2 Zwiebeln und 1 EL Öl'),
      ['Salz', 'Pfeffer', '2 Zwiebeln', '1 EL Öl'],
    );
  });

  test('keeps an amount at the end of a row with its food', () {
    expect(splitFreeCookingTranscript('Hähnchen 500 g, Reis 200g'), [
      'Hähnchen 500 g',
      'Reis 200g',
    ]);
  });

  test('returns no rows for blank text', () {
    expect(splitFreeCookingTranscript('  '), isEmpty);
  });
}
