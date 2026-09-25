import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_success_card/diary_weekly_checkin_success_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('formats rounded goal', (tester) async {
    await tester.pumpWidget(
      _App(
        child: DiaryWeeklyCheckInSuccessCard(
          goalKcal: 2224.6,
          onDismiss: () async {},
        ),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsOneWidget);
    expect(find.textContaining('2,225'), findsOneWidget);
  });

  testWidgets('close button dismisses the message', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      _App(
        child: DiaryWeeklyCheckInSuccessCard(
          goalKcal: 2000,
          onDismiss: () async => dismissed++,
        ),
      ),
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.successCardClose));

    expect(dismissed, 1);
  });
}

class _App extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
