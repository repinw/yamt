import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/root_navigator_test_utils.dart';

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('recipe template sheet opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();
    late AppLocalizations l10n;

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return TextButton(
                onPressed: () {
                  unawaited(showPreparedMealRecipeTemplateSheet(context));
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(
      find.text(l10n.preparedMealTemplateRecipeSheetTitle),
      findsOneWidget,
    );
  });

  testWidgets('recipe template sheet renders new premium elements', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  unawaited(showPreparedMealRecipeTemplateSheet(context));
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context)!;

    // Verify Greeting Subtitle is rendered
    expect(
      find.text(l10n.preparedMealTemplateRecipeGreetingSubtitle),
      findsOneWidget,
    );

    // Verify Expandable Tile for Advanced Options is present
    expect(
      find.text(l10n.preparedMealTemplateAdvancedOptionsTitle),
      findsOneWidget,
    );

    // Recipe name input field should not be visible when collapsed
    expect(find.text(l10n.preparedMealTemplateNameLabel), findsNothing);

    // Expand the tile
    await tester.tap(find.text(l10n.preparedMealTemplateAdvancedOptionsTitle));
    await tester.pumpAndSettle();

    // Recipe name input field should be visible after expansion
    expect(find.text(l10n.preparedMealTemplateNameLabel), findsOneWidget);
  });

  testWidgets('recipe template sheet clipboard auto-detect and fill works', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    _mockClipboardText('https://chefkoch.de/recipe123');

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  unawaited(showPreparedMealRecipeTemplateSheet(context));
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Clipboard paste card is shown with new localized strings
    expect(find.text('Aus Zwischenablage einfügen ✨'), findsOneWidget);
    expect(
      find.text(
        'Hier tippen, um die Zwischenablage nach einem Rezept-Link '
        'zu durchsuchen.',
      ),
      findsOneWidget,
    );

    // Tap on clipboard paste card
    await tester.tap(find.text('Aus Zwischenablage einfügen ✨'));
    await tester.pumpAndSettle();

    // The clipboard paste card should disappear (since URL is now filled)
    expect(find.text('Aus Zwischenablage einfügen ✨'), findsNothing);

    // The textfield should have the recipe URL
    final urlFinder = find.byType(TextField).first;
    final textField = tester.widget<TextField>(urlFinder);
    expect(textField.controller?.text, 'https://chefkoch.de/recipe123');
  });

  testWidgets(
    'recipe template sheet shows error for clipboard text without URL',
    (tester) async {
      _mockClipboardText('Hallo Welt');
      final l10n = await _openRecipeTemplateSheet(tester);

      await tester.tap(find.text(l10n.preparedMealTemplateClipboardTitle));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.preparedMealTemplateClipboardNoLinkFound),
        findsOneWidget,
      );

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, isEmpty);
    },
  );

  testWidgets('recipe template sheet shows error when clipboard read fails', (
    tester,
  ) async {
    _mockClipboardFailure();
    final l10n = await _openRecipeTemplateSheet(tester);

    await tester.tap(find.text(l10n.preparedMealTemplateClipboardTitle));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.preparedMealTemplateClipboardNoLinkFound),
      findsOneWidget,
    );

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('recipe template sheet validation and submit works', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();
    PreparedMealRecipeTemplateDraft? submittedDraft;

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  submittedDraft = await showPreparedMealRecipeTemplateSheet(
                    context,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context)!;

    // Submit directly with empty URL. Should trigger validation error.
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();

    // Verify invalid url error is shown
    expect(
      find.text(l10n.preparedMealTemplateRecipeUrlInvalid),
      findsOneWidget,
    );

    // Enter an invalid URL format
    final urlFinder = find.ancestor(
      of: find.text(l10n.preparedMealTemplateRecipeUrlLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(urlFinder, 'invalid_url');
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.preparedMealTemplateRecipeUrlInvalid),
      findsOneWidget,
    );

    // Enter a valid URL
    await tester.enterText(urlFinder, 'https://example.com/valid');
    await tester.pumpAndSettle();

    // Expand advanced options to enter invalid portions
    await tester.tap(find.text(l10n.preparedMealTemplateAdvancedOptionsTitle));
    await tester.pumpAndSettle();

    final nameFinder = find.ancestor(
      of: find.text(l10n.preparedMealTemplateNameLabel),
      matching: find.byType(TextField),
    );
    final portionsFinder = find.ancestor(
      of: find.text(l10n.preparedMealTemplatePortionsLabel),
      matching: find.byType(TextField),
    );

    // Enter invalid portion 0
    await tester.enterText(portionsFinder, '0');
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.preparedMealInvalidPortionsRange),
      findsOneWidget,
    );

    // Enter portion -5
    await tester.enterText(portionsFinder, '-5');
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.preparedMealInvalidPortionsRange),
      findsOneWidget,
    );

    // Enter non-numeric portion
    await tester.enterText(portionsFinder, 'abc');
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.preparedMealInvalidPortionsRange),
      findsOneWidget,
    );

    // Fill valid name and portions and submit
    await tester.enterText(nameFinder, 'My Recipe');
    await tester.enterText(portionsFinder, '4');
    await tester.tap(
      find.text(l10n.preparedMealTemplateCreateFromRecipeAction),
    );
    await tester.pumpAndSettle();

    // Sheet should be popped and returned draft has correct inputs
    expect(submittedDraft, isNotNull);
    expect(submittedDraft?.recipeUrl, 'https://example.com/valid');
    expect(submittedDraft?.name, 'My Recipe');
    expect(submittedDraft?.totalPortions, 4);
  });

  testWidgets('recipe template sheet cancel button works', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();
    var dismissed = false;

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final res = await showPreparedMealRecipeTemplateSheet(
                    context,
                  );
                  if (res == null) {
                    dismissed = true;
                  }
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context)!;

    // Tap cancel button
    await tester.tap(find.text(l10n.inventoryReceiptReviewCancelAction));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}

void _mockClipboardText(String text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': text};
        }
        return null;
      });
}

void _mockClipboardFailure() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          throw PlatformException(
            code: 'clipboard-unavailable',
            message: 'Clipboard unavailable.',
          );
        }
        return null;
      });
}

Future<AppLocalizations> _openRecipeTemplateSheet(WidgetTester tester) async {
  final rootObserver = RecordingNavigatorObserver();
  final nestedObserver = RecordingNavigatorObserver();
  late AppLocalizations l10n;

  await tester.pumpWidget(
    nestedNavigatorHarness(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(
        body: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return TextButton(
              onPressed: () {
                unawaited(showPreparedMealRecipeTemplateSheet(context));
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return l10n;
}
