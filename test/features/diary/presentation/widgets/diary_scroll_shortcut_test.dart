import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_scroll_shortcut.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('shows jump-to-meals action and calls callback', (tester) async {
    var jumpCount = 0;
    await _pumpShortcut(
      tester,
      showJumpToMeals: true,
      onJumpToMeals: () => jumpCount += 1,
    );

    expect(find.text('To diary').hitTestable(), findsOneWidget);

    await tester.tap(find.text('To diary').hitTestable());
    await tester.pump();

    expect(jumpCount, 1);
  });

  testWidgets('shows scroll-to-top action and calls callback', (tester) async {
    var topCount = 0;
    await _pumpShortcut(
      tester,
      showScrollToTop: true,
      onScrollToTop: () => topCount += 1,
    );

    expect(find.text('To top').hitTestable(), findsOneWidget);

    await tester.tap(find.text('To top').hitTestable());
    await tester.pump();

    expect(topCount, 1);
  });

  testWidgets('hides shortcut when no action is visible', (tester) async {
    await _pumpShortcut(tester);

    expect(find.text('To diary'), findsOneWidget);
    expect(find.text('To diary').hitTestable(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('settles jump pulse after short attention animation', (
    tester,
  ) async {
    await _pumpShortcut(tester, showJumpToMeals: true);

    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();

    expect(find.text('To diary').hitTestable(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('updates visible action when shortcut mode changes', (
    tester,
  ) async {
    await _pumpShortcut(tester, showJumpToMeals: true);

    expect(find.text('To diary').hitTestable(), findsOneWidget);

    await _pumpShortcut(tester, showScrollToTop: true);

    expect(find.text('To top').hitTestable(), findsOneWidget);
    expect(find.text('To diary'), findsNothing);
  });
}

Future<void> _pumpShortcut(
  WidgetTester tester, {
  bool showJumpToMeals = false,
  bool showScrollToTop = false,
  VoidCallback? onJumpToMeals,
  VoidCallback? onScrollToTop,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: DiaryScrollShortcut(
            showJumpToMeals: showJumpToMeals,
            showScrollToTop: showScrollToTop,
            onJumpToMeals: onJumpToMeals ?? () {},
            onScrollToTop: onScrollToTop ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
