import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';

void main() {
  test('reservations survive the document', () {
    final reservations = [
      (stockId: 'pack', amount: 250.0, at: DateTime(2026, 10, 21, 12, 30)),
      (stockId: 'chili', amount: 1.5, at: DateTime(2026, 10, 22, 18)),
    ];

    expect(
      planReservationsFromJson(planReservationsToJson(reservations)),
      reservations,
    );
  });

  test('a malformed document throws', () {
    expect(
      () => planReservationsFromJson({
        'reservations': [
          {'stock_id': 'pack', 'amount': '250'},
        ],
      }),
      throwsFormatException,
    );
  });
}
