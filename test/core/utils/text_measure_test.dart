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

/// Runs [body] with the [BuildContext] of a widget at [scale] text size.
Future<T> _inContext<T>(
  WidgetTester tester,
  double scale,
  T Function(BuildContext context) body,
) async {
  late T result;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
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

double _reference(String text, double scale) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
  )..layout();
  return painter.width;
}

void main() {
  setUpAll(loadAppFonts);

  group('measureLineWidth', () {
    testWidgets('is the width of the text on one line', (tester) async {
      final width = await _inContext(
        tester,
        1,
        (context) => measureLineWidth(
          context,
          const TextSpan(text: 'Kohlenhydrate', style: _style),
        ),
      );

      expect(width, closeTo(_reference('Kohlenhydrate', 1), 0.01));
      expect(width, greaterThan(40));
    });

    testWidgets('grows with the text scale of the context', (tester) async {
      final width = await _inContext(
        tester,
        2,
        (context) => measureLineWidth(
          context,
          const TextSpan(text: 'Kohlenhydrate', style: _style),
        ),
      );

      expect(width, closeTo(_reference('Kohlenhydrate', 2), 0.01));
      expect(width, closeTo(2 * _reference('Kohlenhydrate', 1), 1));
    });

    testWidgets('does not wrap a text with spaces', (tester) async {
      final width = await _inContext(
        tester,
        1,
        (context) => measureLineWidth(
          context,
          const TextSpan(text: 'Zucker und Salz und mehr', style: _style),
        ),
      );

      expect(width, closeTo(_reference('Zucker und Salz und mehr', 1), 0.01));
    });

    testWidgets('a longer text is wider', (tester) async {
      final (short, long) = await _inContext(
        tester,
        1,
        (context) => (
          measureLineWidth(
            context,
            const TextSpan(text: 'Fett', style: _style),
          ),
          measureLineWidth(
            context,
            const TextSpan(text: 'Kohlenhydrate', style: _style),
          ),
        ),
      );

      expect(long, greaterThan(short));
    });

    testWidgets('takes the default text style of the context', (tester) async {
      late double plain;
      late double big;
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              DefaultTextStyle(
                style: _style,
                child: Builder(
                  builder: (context) {
                    plain = measureLineWidth(
                      context,
                      const TextSpan(text: 'Protein'),
                    );
                    return const SizedBox();
                  },
                ),
              ),
              DefaultTextStyle(
                style: _style.copyWith(fontSize: 32),
                child: Builder(
                  builder: (context) {
                    big = measureLineWidth(
                      context,
                      const TextSpan(text: 'Protein'),
                    );
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(plain, closeTo(_reference('Protein', 1), 0.01));
      expect(big, closeTo(2 * plain, 1));
    });
  });

  group('textFitsWholeWords', () {
    bool fits(
      BuildContext context,
      String text, {
      required double maxWidth,
      double maxHeight = double.infinity,
      int maxLines = 1,
    }) => textFitsWholeWords(
      context,
      text,
      _style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxLines: maxLines,
    );

    testWidgets('a text that fits one line fits', (tester) async {
      final result = await _inContext(
        tester,
        1,
        (context) =>
            fits(context, 'Training', maxWidth: _reference('Training', 1) + 2),
      );

      expect(result, isTrue);
    });

    testWidgets('a text one pixel too wide does not fit on one line', (
      tester,
    ) async {
      final result = await _inContext(
        tester,
        1,
        (context) =>
            fits(context, 'Training', maxWidth: _reference('Training', 1) - 1),
      );

      expect(result, isFalse);
    });

    testWidgets('a word wider than the room fails although lines are left', (
      tester,
    ) async {
      final result = await _inContext(
        tester,
        1,
        (context) => fits(
          context,
          'Kohlenhydrate',
          maxWidth: _reference('Kohlenhydrate', 1) - 5,
          maxLines: 3,
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('two words fit on two lines when each word fits', (
      tester,
    ) async {
      final room = _reference('Pausentag', 1) + 2;
      final (oneLine, twoLines) = await _inContext(
        tester,
        1,
        (context) => (
          fits(context, 'Pausentag Heute', maxWidth: room),
          fits(context, 'Pausentag Heute', maxWidth: room, maxLines: 2),
        ),
      );

      expect(oneLine, isFalse);
      expect(twoLines, isTrue);
    });

    testWidgets('three lines of text do not fit two lines', (tester) async {
      final room = _reference('Pausentag', 1) + 2;
      final result = await _inContext(
        tester,
        1,
        (context) => fits(
          context,
          'Pausentag Pausentag Pausentag',
          maxWidth: room,
          maxLines: 2,
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('fails when the lines are taller than the room', (
      tester,
    ) async {
      final room = _reference('Pausentag', 1) + 2;
      final (tall, short) = await _inContext(
        tester,
        1,
        (context) => (
          fits(
            context,
            'Pausentag Heute',
            maxWidth: room,
            maxLines: 2,
            maxHeight: 100,
          ),
          fits(
            context,
            'Pausentag Heute',
            maxWidth: room,
            maxLines: 2,
            maxHeight: 20,
          ),
        ),
      );

      expect(tall, isTrue);
      expect(short, isFalse);
    });

    testWidgets('large text takes the room away', (tester) async {
      final room = _reference('Training', 1) + 2;
      final normal = await _inContext(
        tester,
        1,
        (context) => fits(context, 'Training', maxWidth: room),
      );
      final large = await _inContext(
        tester,
        2,
        (context) => fits(context, 'Training', maxWidth: room),
      );

      expect(normal, isTrue);
      expect(large, isFalse);
    });
  });
}
