import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();

  test('a household that changed meanwhile asks to check it again', () {
    expect(
      householdErrorMessage(en, const HouseholdChangedException()),
      'The household changed in the meantime. Check it and try again.',
    );
    expect(
      householdErrorMessage(
        AppLocalizationsDe(),
        const HouseholdChangedException(),
      ),
      'Der Haushalt hat sich inzwischen geändert. Prüfe ihn und versuche es '
      'erneut.',
    );
  });

  test('an unknown failure names no cause', () {
    expect(
      householdErrorMessage(en, StateError('x')),
      en.householdActionFailed,
    );
  });
}
