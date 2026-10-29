import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_balance_details_controller.g.dart';

/// Whether the budget card shows its details: the eaten grams, the ledger
/// and the week strip. Starts closed whenever the diary opens.
@riverpod
class DiaryBalanceDetailsController extends _$DiaryBalanceDetailsController {
  @override
  bool build() => false;

  /// Opens or closes the details.
  void toggle() => state = !state;
}
