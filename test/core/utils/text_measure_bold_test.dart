import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/utils/text_measure.dart';

import '../../helpers/app_font_test_utils.dart';

const _style = TextStyle(
  fontFamily: AppFonts.geist,
  fontSize: 16,
  fontWeight: FontWeight.w400,
  decoration: TextDecoration.none,
);

const _word = 'Mittagessen';

/// Runs [body] with the [BuildContext] of a widget at [scale] text size,
/// with the Bold Text setting on or off.
Future<T> _inContext<T>(
  WidgetTester tester, {
  required T Function(BuildContext context) body,
  double scale = 1,
  bool bold = false,
}) async {
  late T result;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          boldText: bold,
        ),
        child: DefaultTextStyle(
          style: _style,
          child: Builder(
            builder: (context) {
              result = body(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );
  return result;
}

/// Width that a real `Text(_word, style: _style)` takes in a one-line frame
/// at [scale] with the Bold Text setting [bold].
Future<double> _drawnWidth(
  WidgetTester tester, {
  required double scale,
  required bool bold,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          boldText: bold,
        ),
        child: const Align(
          alignment: Alignment.topLeft,
          child: Text(_word, maxLines: 1, style: _style),
        ),
      ),
    ),
  );
  return tester.getSize(find.text(_word)).width;
}

void main() {
  setUpAll(loadAppFonts);

  group('isLargeText', () {
    for (final (scale, expected) in [
      (0.85, false),
      (1.0, false),
      (1.01, true),
      (1.5, true),
      (2.0, true),
    ]) {
      testWidgets('is $expected at text scale $scale', (tester) async {
        final large = await _inContext(tester, scale: scale, body: isLargeText);

        expect(large, expected);
      });
    }

    testWidgets('does not follow the Bold Text setting', (tester) async {
      final large = await _inContext(tester, bold: true, body: isLargeText);

      expect(large, isFalse);
    });
  });

  group('measureTextWidth with Bold Text', () {
    for (final scale in [1.0, 1.5]) {
      testWidgets('is wider than without it at text scale $scale', (
        tester,
      ) async {
        final regular = await _inContext(
          tester,
          scale: scale,
          body: (context) => measureTextWidth(context, _word, _style),
        );
        final bold = await _inContext(
          tester,
          scale: scale,
          bold: true,
          body: (context) => measureTextWidth(context, _word, _style),
        );

        expect(bold, greaterThan(regular + 1));
      });

      testWidgets('matches the width a real Text takes at text scale $scale', (
        tester,
      ) async {
        for (final bold in [false, true]) {
          final measured = await _inContext(
            tester,
            scale: scale,
            bold: bold,
            body: (context) => measureTextWidth(context, _word, _style),
          );
          final drawn = await _drawnWidth(tester, scale: scale, bold: bold);

          expect(measured, closeTo(drawn, 0.01), reason: 'bold: $bold');
        }
      });
    }

    testWidgets('the setting wins over a style with its own weight', (
      tester,
    ) async {
      final light = _style.copyWith(fontWeight: FontWeight.w300);
      final (lightBold, regularBold) = await _inContext(
        tester,
        bold: true,
        body: (context) => (
          measureTextWidth(context, _word, light),
          measureTextWidth(context, _word, _style),
        ),
      );

      expect(lightBold, closeTo(regularBold, 0.01));
    });
  });

  group('measureLineWidth with Bold Text', () {
    testWidgets('keeps the weight that a span sets itself', (tester) async {
      const span = TextSpan(text: _word, style: _style);
      final regular = await _inContext(
        tester,
        body: (context) => measureLineWidth(context, span),
      );
      final bold = await _inContext(
        tester,
        bold: true,
        body: (context) => measureLineWidth(context, span),
      );

      expect(bold, closeTo(regular, 0.01));
    });

    testWidgets('a span without a weight takes the bold of the setting', (
      tester,
    ) async {
      const span = TextSpan(text: _word);
      final regular = await _inContext(
        tester,
        body: (context) => measureLineWidth(context, span),
      );
      final bold = await _inContext(
        tester,
        bold: true,
        body: (context) => measureLineWidth(context, span),
      );

      expect(bold, greaterThan(regular + 1));
    });
  });

  group('textFitsWholeWords with Bold Text', () {
    for (final scale in [1.0, 1.5]) {
      testWidgets('a word that fits regular but not bold at text scale '
          '$scale', (tester) async {
        final regularWidth = await _inContext(
          tester,
          scale: scale,
          body: (context) => measureTextWidth(context, _word, _style),
        );
        // Room for the regular word and no more than half a pixel to spare.
        final room = regularWidth + 0.5;

        final fitsRegular = await _inContext(
          tester,
          scale: scale,
          body: (context) =>
              textFitsWholeWords(context, _word, _style, maxWidth: room),
        );
        final fitsBold = await _inContext(
          tester,
          scale: scale,
          bold: true,
          body: (context) =>
              textFitsWholeWords(context, _word, _style, maxWidth: room),
        );

        expect(fitsRegular, isTrue);
        expect(fitsBold, isFalse);
      });
    }

    testWidgets('a bold word that fits its room fits', (tester) async {
      final boldWidth = await _inContext(
        tester,
        bold: true,
        body: (context) => measureTextWidth(context, _word, _style),
      );

      final fits = await _inContext(
        tester,
        bold: true,
        body: (context) => textFitsWholeWords(
          context,
          _word,
          _style,
          maxWidth: boldWidth + 0.5,
        ),
      );

      expect(fits, isTrue);
    });
  });
}
