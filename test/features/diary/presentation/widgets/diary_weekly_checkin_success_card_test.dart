import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_success_card/diary_weekly_checkin_success_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('formats rounded goal', (tester) async {
    await tester.pumpWidget(
      const _App(child: DiaryWeeklyCheckInSuccessCard(goalKcal: 2224.6)),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsOneWidget);
    expect(find.textContaining('2,225'), findsOneWidget);
  });
}

class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
