import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/wrapped_punctuation.dart';

void main() {
  group('stripWrappedPunctuation', () {
    const link = 'https://example.de/rezept';

    test('takes off quotes, brackets, and sentence marks around the value', () {
      for (final text in [
        link,
        '$link.',
        '$link,',
        '$link!?',
        '($link)',
        '<$link>',
        '[$link]',
        '{$link}',
        '"$link"',
        "'$link'",
        '(<$link>,)',
      ]) {
        expect(stripWrappedPunctuation(text), link, reason: text);
      }
    });

    test('keeps a closing bracket whose opener stays', () {
      const wiki = 'https://example.de/wiki/Foo_(Bar)';

      expect(stripWrappedPunctuation(wiki), wiki);
      expect(stripWrappedPunctuation('$wiki.'), wiki);
      expect(stripWrappedPunctuation('($wiki)'), wiki);
      expect(stripWrappedPunctuation('($wiki).'), wiki);
      expect(
        stripWrappedPunctuation('https://example.de/a[1]'),
        'https://example.de/a[1]',
      );
    });

    test('takes a closing bracket whose opener is not in the value', () {
      expect(stripWrappedPunctuation('$link)'), link);
      expect(stripWrappedPunctuation('$link]}'), link);
    });

    test('leaves nothing of a value that is only marks', () {
      expect(stripWrappedPunctuation('(.)'), isEmpty);
      expect(stripWrappedPunctuation(''), isEmpty);
    });
  });
}
