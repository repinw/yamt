/// What one open plan keeps from the shared Vorrat, so the other household
/// members see it: `stockId` is a Vorrat item, with `amount` in its stored
/// unit, or a cooked meal, with `amount` in portions. Plans take stock in
/// the order of their times `at`.
typedef PlanReservation = ({String stockId, double amount, DateTime at});

/// A plan reservation of the household member `uid`.
typedef MemberPlanReservation = ({String uid, PlanReservation reservation});

/// The document of one member's reservations.
Map<String, dynamic> planReservationsToJson(
  List<PlanReservation> reservations,
) => {
  'reservations': [
    for (final reservation in reservations)
      {
        'stock_id': reservation.stockId,
        'amount': reservation.amount,
        'at': reservation.at.toUtc().toIso8601String(),
      },
  ],
};

/// Reads the document of one member's reservations. Throws when it is
/// malformed.
List<PlanReservation> planReservationsFromJson(Map<String, dynamic> json) => [
  for (final reservation in json['reservations'] as List<dynamic>)
    switch (reservation) {
      {
        'stock_id': final String stockId,
        'amount': final num amount,
        'at': final String at,
      } =>
        (
          stockId: stockId,
          amount: amount.toDouble(),
          at: DateTime.parse(at).toLocal(),
        ),
      _ => throw FormatException('Malformed plan reservation: $reservation'),
    },
];
