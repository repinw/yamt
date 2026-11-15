import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/shared_recipe_link.dart';

void main() {
  group('sharedRecipeLink', () {
    test('a link alone is the link, also with white space around it', () {
      expect(
        sharedRecipeLink('https://example.com/rezept'),
        'https://example.com/rezept',
      );
      expect(
        sharedRecipeLink('  http://example.com/rezept?id=4 \n'),
        'http://example.com/rezept?id=4',
      );
    });

    test('a title line with one link counts as a link', () {
      expect(
        sharedRecipeLink('Bauerntopf – Kochseite\nhttps://example.com/topf'),
        'https://example.com/topf',
      );
      expect(
        sharedRecipeLink('https://example.com/topf\nBauerntopf – Kochseite'),
        'https://example.com/topf',
      );
    });

    test('a title and a link on one line count as a link', () {
      expect(
        sharedRecipeLink('Bauerntopf https://example.com/topf'),
        'https://example.com/topf',
      );
    });

    test('a recipe app share with a teaser, a title, and the link counts as '
        'a link', () {
      expect(
        sharedRecipeLink(
          'Hunger? Rezept auf example.de:\nBauerntopf\n'
          'https://www.example.de/rezepte/1/Bauerntopf.html?utm_medium=sharing',
        ),
        'https://www.example.de/rezepte/1/Bauerntopf.html?utm_medium=sharing',
      );
    });

    test('text with a link and more than a title is a recipe to paste', () {
      expect(
        sharedRecipeLink(
          '200 g Mehl\nSalz\nhttps://example.com/topf\nBacken\nEssen',
        ),
        isNull,
      );
      expect(
        sharedRecipeLink('Titel\n\nhttps://example.com/topf\n200 g Mehl'),
        isNull,
      );
    });

    group('punctuation around the link', () {
      const link = 'https://example.de/rezept';

      test('goes, in any shape', () {
        for (final text in [
          'Schau mal: $link.',
          '$link, super lecker',
          '($link)',
          '<$link>',
          '"$link"',
          "'$link'",
          '[$link]',
          '($link).',
          'Titel\nTeaser\n$link.',
        ]) {
          expect(sharedRecipeLink(text), link, reason: text);
        }
      });

      test('a bracket of the link itself stays', () {
        const wiki = 'https://example.de/wiki/Foo_(Bar)';

        expect(sharedRecipeLink(wiki), wiki);
        expect(sharedRecipeLink('$wiki.'), wiki);
        expect(sharedRecipeLink('($wiki)'), wiki);
      });

      test('the query of the link stays', () {
        expect(sharedRecipeLink('($link?id=4).'), '$link?id=4');
      });

      test('two wrapped links are no link', () {
        expect(sharedRecipeLink('($link) <https://example.de/b>'), isNull);
      });
    });

    group('a title that starts with a digit', () {
      const link = 'https://example.de/rezept';

      test('counts as a title, on its own line and beside the link', () {
        for (final text in [
          '5-Minuten-Pasta\n$link',
          '15 Minuten Pasta\n$link',
          '30 Minuten Lasagne | Kochseite\n$link',
          '3-Zutaten-Brot - Kochseite\n$link',
          '5-Zutaten-Brot $link',
          '15 Minuten Pasta $link',
        ]) {
          expect(sharedRecipeLink(text), link, reason: text);
        }
      });

      test('counts as a title after a teaser line', () {
        expect(
          sharedRecipeLink(
            'Hunger? Rezept auf example.de:\n5-Minuten-Terrine\n$link',
          ),
          link,
        );
      });
    });

    test('a line with an amount and a unit beside a link is a recipe', () {
      const link = 'https://example.de/rezept';

      for (final line in [
        '200 g Mehl',
        '200g Mehl',
        '1,5 l Wasser',
        '1/2 TL Salz',
        '2 Stück Butter',
        '1 Päckchen Hefe',
      ]) {
        expect(sharedRecipeLink('$line\n$link'), isNull, reason: line);
      }
    });

    test('a unit word that goes on is no amount', () {
      expect(
        sharedRecipeLink('2 Stückchen Kuchen\nhttps://example.de/rezept'),
        'https://example.de/rezept',
      );
    });

    group('a long line beside the link', () {
      const link = 'https://example.de/rezept';
      final atLimit = 'a' * 120;

      test('at the limit is still a title', () {
        expect(sharedRecipeLink('$atLimit\n$link'), link);
      });

      test('over the limit is a recipe', () {
        expect(sharedRecipeLink('${atLimit}a\n$link'), isNull);
        expect(sharedRecipeLink('${atLimit}a $link'), isNull);
      });

      test('a recipe in a caption with a link is a recipe', () {
        expect(
          sharedRecipeLink(
            'Cremige Suppe: Du brauchst Tomaten, Sahne, Zwiebeln und Brühe. '
            'Alles anbraten, aufgießen und zwanzig Minuten leise kochen lassen.'
            '\nMehr auf $link',
          ),
          isNull,
        );
      });
    });

    test('two links are no link', () {
      expect(
        sharedRecipeLink('https://example.com/a https://example.com/b'),
        isNull,
      );
      expect(
        sharedRecipeLink('https://example.com/a\nhttps://example.com/b'),
        isNull,
      );
    });

    test('text without a web link is no link', () {
      expect(sharedRecipeLink('200 g Mehl\nSalz'), isNull);
      expect(sharedRecipeLink(''), isNull);
      expect(sharedRecipeLink('ftp://example.com/rezept'), isNull);
      expect(sharedRecipeLink('https://'), isNull);
      expect(sharedRecipeLink('example.com/rezept'), isNull);
    });
  });
}
