import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_nav_action.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

import '../../helpers/app_font_test_utils.dart';

const _tabs = ['Tagebuch', 'Vorrat', 'Kochbuch', 'Fortschritt'];

HomeBottomNavBar _bar([String actionLabel = 'Hinzufügen']) => HomeBottomNavBar(
  entries: [
    for (final (index, label) in _tabs.indexed)
      HomeNavEntry(
        item: HomeNavItem(icon: Icons.circle, label: label),
        isSelected: index == 0,
        onTap: () {},
      ),
  ],
  action: HomeNavAction(label: actionLabel, onPressed: () {}),
);

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  Widget Function(Widget bar)? around,
  bool appFont = false,
  String actionLabel = 'Hinzufügen',
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: appFont ? ThemeData(fontFamily: AppFonts.sans) : null,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        extendBody: true,
        body: around == null
            ? Align(alignment: Alignment.bottomCenter, child: _bar(actionLabel))
            : around(_bar(actionLabel)),
      ),
    ),
  );
  await tester.pump();
}

double _barHeight(WidgetTester tester) =>
    tester.getSize(find.byKey(HomeBottomNavBar.actionKey)).height;

void main() {
  group('HomeBottomNavBar', () {
    testWidgets('is navBarHeight tall at normal text', (tester) async {
      await _pump(tester, width: 400, textScale: 1);

      expect(tester.takeException(), isNull);
      expect(_barHeight(tester), AppGraphit.navBarHeight);
    });

    for (final width in [700.0, 360.0]) {
      testWidgets('grows without overflow at text scale 2.0 and ${width}px', (
        tester,
      ) async {
        await _pump(tester, width: width, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(_barHeight(tester), greaterThan(AppGraphit.navBarHeight));
      });
    }

    testWidgets('the last content row clears a grown bar at text scale 2.0', (
      tester,
    ) async {
      const lastRow = Key('last-row');
      await _pump(
        tester,
        width: 360,
        textScale: 2,
        around: (bar) => Stack(
          children: [
            Builder(
              builder: (context) => ListView(
                padding: EdgeInsets.only(
                  bottom: homeShellPageBottomPadding(context),
                ),
                children: [
                  for (var i = 0; i < 30; i += 1) const SizedBox(height: 48),
                  const SizedBox(key: lastRow, height: 48),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: bar),
          ],
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pump();

      final rowBottom = tester.getBottomLeft(find.byKey(lastRow)).dy;
      final barTop = tester
          .getTopLeft(find.byKey(HomeBottomNavBar.actionKey))
          .dy;
      expect(_barHeight(tester), greaterThan(AppGraphit.navBarHeight));
      expect(
        rowBottom,
        lessThanOrEqualTo(barTop - AppSpacing.xs),
        reason: 'the last row ends at $rowBottom, the bar starts at $barTop',
      );
    });
    group('tab words at large text', () {
      setUpAll(loadAppFonts);

      for (final width in [308.0, 412.0]) {
        for (final scale in [1.0, 2.0]) {
          final where = '${width}px, text scale $scale';

          testWidgets('all four tab words paint equally tall: $where', (
            tester,
          ) async {
            await _pump(tester, width: width, textScale: scale, appFont: true);

            final heights = [
              for (final tab in _tabs) tester.getRect(find.text(tab)).height,
            ];
            expect(tester.takeException(), isNull);
            for (final height in heights.skip(1)) {
              expect(
                height,
                closeTo(heights.first, 0.5),
                reason: 'tab word heights are $heights',
              );
            }
          });

          testWidgets('neighbouring tab words keep a 4 dp gap: $where', (
            tester,
          ) async {
            await _pump(tester, width: width, textScale: scale, appFont: true);

            final rects = [
              for (final tab in _tabs) tester.getRect(find.text(tab)),
            ];
            expect(tester.takeException(), isNull);
            for (var i = 0; i < rects.length - 1; i += 1) {
              expect(
                rects[i + 1].left - rects[i].right,
                greaterThanOrEqualTo(4),
                reason:
                    '${_tabs[i]} ends at ${rects[i].right}, '
                    '${_tabs[i + 1]} starts at ${rects[i + 1].left}',
              );
            }
          });

          testWidgets('the action word keeps a 4 dp gap to the button edges: '
              '$where', (tester) async {
            await _pump(tester, width: width, textScale: scale, appFont: true);

            final word = tester.getRect(find.text('Hinzufügen'));
            final button = tester.getRect(
              find.byKey(HomeBottomNavBar.actionKey),
            );
            expect(tester.takeException(), isNull);
            expect(
              word.left - button.left,
              greaterThanOrEqualTo(4),
              reason: 'word $word, button $button',
            );
            expect(
              button.right - word.right,
              greaterThanOrEqualTo(4),
              reason: 'word $word, button $button',
            );
          });
        }
      }
    });

    group('words are not cut and keep 4 dp on each side', () {
      setUpAll(loadAppFonts);

      /// The laid-out width of the text of [word], not the width of its box.
      /// The paragraph's own text, style and scaler are measured.
      ({RenderParagraph paragraph, double width, double centre}) measure(
        WidgetTester tester,
        String word,
      ) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(word));
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        return (
          paragraph: paragraph,
          width: width,
          centre: tester.getRect(find.text(word)).center.dx,
        );
      }

      for (final width in [308.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3, 2.0, 3.0]) {
          testWidgets('tab words: ${width}px, text scale $scale', (
            tester,
          ) async {
            await _pump(tester, width: width, textScale: scale, appFont: true);

            expect(tester.takeException(), isNull);
            for (final tab in _tabs) {
              final word = measure(tester, tab);
              final area = tester.getRect(
                find
                    .ancestor(
                      of: find.text(tab),
                      matching: find.byType(AppInkWell),
                    )
                    .first,
              );
              final left = word.centre - word.width / 2;
              final right = word.centre + word.width / 2;
              expect(
                word.paragraph.didExceedMaxLines,
                isFalse,
                reason: '$tab is cut',
              );
              expect(
                left - area.left,
                greaterThanOrEqualTo(4),
                reason: '$tab text starts at $left, its tab at ${area.left}',
              );
              expect(
                area.right - right,
                greaterThanOrEqualTo(4),
                reason: '$tab text ends at $right, its tab at ${area.right}',
              );
            }
          });
        }
      }

      for (final label in ['Hinzufügen', 'Essen']) {
        for (final scale in [1.0, 1.3, 2.0, 3.0]) {
          testWidgets('action word "$label": 412px, text scale $scale', (
            tester,
          ) async {
            await _pump(
              tester,
              width: 412,
              textScale: scale,
              appFont: true,
              actionLabel: label,
            );

            expect(tester.takeException(), isNull);
            final word = measure(tester, label);
            final button = tester.getRect(
              find.byKey(HomeBottomNavBar.actionKey),
            );
            final left = word.centre - word.width / 2;
            final right = word.centre + word.width / 2;
            expect(
              word.paragraph.didExceedMaxLines,
              isFalse,
              reason: '$label is cut',
            );
            expect(
              left - button.left,
              greaterThanOrEqualTo(4),
              reason: '$label text starts at $left, button at ${button.left}',
            );
            expect(
              button.right - right,
              greaterThanOrEqualTo(4),
              reason: '$label text ends at $right, button at ${button.right}',
            );
          });
        }
      }
    });
  });
}
