import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_button/ai_chef_button.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([AiChefController, InventoryItemsController])
void main() {
  testWidgets('button opens recipe setup dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(actions: const [AiChefButton()]),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AiChefButton));
    await tester.pumpAndSettle();

    expect(find.text('Was soll die KI kochen?'), findsOneWidget);
    expect(find.text('Vorrat beachten'), findsOneWidget);
    expect(find.text('Rezept generieren'), findsOneWidget);
  });
}
