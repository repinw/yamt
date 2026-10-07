import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations_de.dart';

void main() {
  final l10n = AppLocalizationsDe();
  final today = DateTime(2026, 10, 8, 9);

  setUpAll(() => initializeDateFormatting('de'));

  test('names today, tomorrow, or the date', () {
    String message(DateTime day) =>
        planSavedMessage(l10n, day: day, today: today);

    expect(message(DateTime(2026, 10, 8, 19)), 'Für heute geplant');
    expect(message(DateTime(2026, 10, 9, 8)), 'Für morgen geplant');
    expect(message(DateTime(2026, 10, 12, 8)), 'Für Mo., 12. Okt. geplant');
  });
}
