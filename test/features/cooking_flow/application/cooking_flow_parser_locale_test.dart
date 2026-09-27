import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

void main() {
  test('resolves German parser data', () {
    final parserLocale = CookingFlowParserLocale.forLocaleCode('de');
    final unitPattern = RegExp('^(?:${parserLocale.amountUnitPattern})\$');

    expect(unitPattern.hasMatch('stück'), isTrue);
    expect(parserLocale.isPieceUnit('stueck'), isTrue);
    expect(parserLocale.fuzzyInstructionStopWords, contains('die'));
    // "oder" (or) must never be treated as a fuzzy ingredient candidate;
    // otherwise short conjunctions get highlighted with an invented amount,
    // e.g. "oder (1 Stück)" inside "halbieren oder vierteln".
    expect(parserLocale.fuzzyInstructionStopWords, contains('oder'));
  });

  test('resolves English parser data', () {
    final parserLocale = CookingFlowParserLocale.forLocaleCode('en');
    final unitPattern = RegExp('^(?:${parserLocale.amountUnitPattern})\$');

    expect(unitPattern.hasMatch('pieces'), isTrue);
    expect(parserLocale.isPieceUnit('piece'), isTrue);
    expect(parserLocale.fuzzyInstructionStopWords, contains('the'));
    expect(parserLocale.fuzzyInstructionStopWords, contains('or'));
  });
}
