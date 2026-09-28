import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_leave_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

HouseholdMember _member(String uid, int month, {bool admin = false}) {
  return HouseholdMember(
    uid: uid,
    role: admin ? HouseholdRole.admin : HouseholdRole.member,
    joinedAt: DateTime(2026, month),
    displayName: uid,
  );
}

void main() {
  Future<HouseholdLeaveChoice?> openDialog(
    WidgetTester tester, {
    required List<HouseholdMember> members,
    required bool isOwnHousehold,
    required Future<void> Function() interact,
  }) async {
    HouseholdLeaveChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              choice = await showHouseholdLeaveDialog(
                context,
                members: members,
                currentUserId: 'me',
                isOwnHousehold: isOwnHousehold,
              );
            },
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await interact();
    return choice;
  }

  testWidgets('a member leaves without choosing anybody', (tester) async {
    final choice = await openDialog(
      tester,
      members: [_member('admin', 1, admin: true), _member('me', 2)],
      isOwnHousehold: false,
      interact: () async {
        expect(find.byType(RadioListTile<String>), findsNothing);
        await tester.tap(find.byKey(HouseholdLeaveDialog.confirmKey));
        await tester.pumpAndSettle();
      },
    );

    expect(choice, (successorUid: null));
  });

  testWidgets('the admin of the own household picks who leads next', (
    tester,
  ) async {
    final choice = await openDialog(
      tester,
      members: [
        _member('me', 1, admin: true),
        _member('late', 3),
        _member('early', 2),
      ],
      isOwnHousehold: true,
      interact: () async {
        expect(
          find.text(
            'You get a new, empty household. The others keep everything here.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(HouseholdLeaveDialog.successorKey('late')));
        await tester.pump();
        await tester.tap(find.byKey(HouseholdLeaveDialog.confirmKey));
        await tester.pumpAndSettle();
      },
    );

    expect(choice, (successorUid: 'late'));
  });

  testWidgets('the last member is warned that the household goes', (
    tester,
  ) async {
    final choice = await openDialog(
      tester,
      members: [_member('me', 1, admin: true)],
      isOwnHousehold: false,
      interact: () async {
        expect(find.text('Delete household?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    expect(choice, isNull);
  });
}
