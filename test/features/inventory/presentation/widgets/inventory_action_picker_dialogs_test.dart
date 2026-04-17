import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_remove_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('remove dialog uses foreground icon color in light theme', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    );

    await tester.pumpWidget(
      _DialogHarness(
        theme: theme,
        openDialog: (context) {
          return showInventoryItemRemoveDialog(
            context,
            itemName: 'Milk',
            canReduceAmount: true,
          );
        },
        triggerLabel: 'Open remove',
      ),
    );

    await tester.tap(find.text('Open remove'));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.delete_outline_rounded));
    expect(icon.color, theme.colorScheme.error);
  });

  testWidgets('remove dialog uses background icon color in dark theme', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.dark,
      ),
    );

    await tester.pumpWidget(
      _DialogHarness(
        theme: theme,
        openDialog: (context) {
          return showInventoryItemRemoveDialog(
            context,
            itemName: 'Milk',
            canReduceAmount: true,
          );
        },
        triggerLabel: 'Open remove',
      ),
    );

    await tester.tap(find.text('Open remove'));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.delete_outline_rounded));
    expect(icon.color, theme.colorScheme.errorContainer.withValues(alpha: 0.5));
  });

  testWidgets(
    'discard reason dialog uses foreground icon color in light theme',
    (
      tester,
    ) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      );

      await tester.pumpWidget(
        _DialogHarness(
          theme: theme,
          openDialog: (context) {
            return showInventoryDiscardReasonDialog(
              context,
              itemName: 'Milk',
            );
          },
          triggerLabel: 'Open discard reason',
        ),
      );

      await tester.tap(find.text('Open discard reason'));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.event_busy_outlined));
      expect(icon.color, theme.colorScheme.error);
    },
  );

  testWidgets(
    'discard reason dialog uses background icon color in dark theme',
    (
      tester,
    ) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      );

      await tester.pumpWidget(
        _DialogHarness(
          theme: theme,
          openDialog: (context) {
            return showInventoryDiscardReasonDialog(
              context,
              itemName: 'Milk',
            );
          },
          triggerLabel: 'Open discard reason',
        ),
      );

      await tester.tap(find.text('Open discard reason'));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.event_busy_outlined));
      expect(
        icon.color,
        theme.colorScheme.errorContainer.withValues(alpha: 0.34),
      );
    },
  );
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({
    required this.theme,
    required this.openDialog,
    required this.triggerLabel,
  });

  final ThemeData theme;
  final Future<void> Function(BuildContext context) openDialog;
  final String triggerLabel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  openDialog(context);
                },
                child: Text(triggerLabel),
              ),
            ),
          );
        },
      ),
    );
  }
}
