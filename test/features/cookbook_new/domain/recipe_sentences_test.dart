import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_sentences.dart';

void main() {
  test('splits steps into sentences with their step number', () {
    expect(
      recipeSentences([
        'Tomaten halbieren. Schnittlauch schneiden!',
        ' Eier verquirlen. ',
      ]),
      [
        (step: 1, text: 'Tomaten halbieren.'),
        (step: 1, text: 'Schnittlauch schneiden!'),
        (step: 2, text: 'Eier verquirlen.'),
      ],
    );
  });

  test('keeps abbreviations and lower-case words in the sentence', () {
    const step =
        'Mit Salz z. B. Meersalz würzen. Ca. 5 Min. Danach ruhen lassen. '
        'Bei 180 °C backen, dann 2.5 cm schneiden.';

    expect(recipeSentences([step]).map((sentence) => sentence.text), [
      'Mit Salz z. B. Meersalz würzen.',
      'Ca. 5 Min.',
      'Danach ruhen lassen.',
      'Bei 180 °C backen, dann 2.5 cm schneiden.',
    ]);
  });

  test('drops empty steps and keeps ordinals in the sentence', () {
    expect(
      recipeSentences(['Anbraten.', ' ', 'Im 2. Schritt 1 Pck. Zucker dazu.']),
      [
        (step: 1, text: 'Anbraten.'),
        (step: 3, text: 'Im 2. Schritt 1 Pck. Zucker dazu.'),
      ],
    );
    expect(
      recipeSentences(['Gewürze i. d. R. Meersalz.'])
          .map((sentence) => sentence.text),
      ['Gewürze i. d. R. Meersalz.'],
    );
  });

  test('a temperature at the end of a sentence ends it', () {
    expect(
      recipeSentences([
        'Preheat the oven to 200°C. Line a tray. Bake at 175 F. Serve.',
      ]).map((sentence) => sentence.text),
      [
        'Preheat the oven to 200°C.',
        'Line a tray.',
        'Bake at 175 F.',
        'Serve.',
      ],
    );
  });

  test('short forms, numbers, and numbered lists', () {
    List<String> texts(String step) =>
        recipeSentences([step]).map((sentence) => sentence.text).toList();

    expect(texts('Mit Salz z.B. Meersalz würzen. Dann servieren.'), [
      'Mit Salz z.B. Meersalz würzen.',
      'Dann servieren.',
    ]);
    expect(texts('Mit 1 geh. TL Zucker und ggfs. Salz bestreuen.'), [
      'Mit 1 geh. TL Zucker und ggfs. Salz bestreuen.',
    ]);
    expect(texts('Zwiebeln würfeln. 2 EL Öl erhitzen.'), [
      'Zwiebeln würfeln.',
      '2 EL Öl erhitzen.',
    ]);
    expect(texts('1. Zwiebeln schälen. 2. Karotten schneiden.'), [
      '1. Zwiebeln schälen.',
      '2. Karotten schneiden.',
    ]);
    expect(texts('Preheat oven to 350. Grease a pan.'), [
      'Preheat oven to 350.',
      'Grease a pan.',
    ]);
  });
}
