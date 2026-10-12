import 'package:http/http.dart' as http;
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Both sources answer after this delay, like a network round trip.
const barcodeSourceAnswerDelay = Duration(milliseconds: 20);

/// What the HTTP client throws in flight mode.
final offlineHttpError = http.ClientException(
  'Failed host lookup: api.yamt.de',
  Uri.parse('https://api.yamt.de/barcode'),
);

/// Open Food Facts barcode lookup that answers with [results] or throws
/// [error].
class FakeOffBarcodeRepository implements OffProductSearchRepository {
  /// Creates the fake.
  new({this.results = const <OffProductSearchResult>[], this.error});

  /// Products found for any barcode.
  final List<OffProductSearchResult> results;

  /// Thrown instead of answering.
  final Exception? error;

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    await Future<void>.delayed(barcodeSourceAnswerDelay);
    if (error case final error?) {
      throw error;
    }
    return results;
  }

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
    bool isReceiptLine = false,
  }) {
    throw UnimplementedError('The barcode lookup does not search by name.');
  }
}

/// Barcode candidates learned from earlier picks that answers with
/// [candidates] or throws [error].
class FakeGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  /// Creates the fake.
  new({this.candidates = const <GlobalBarcodeCandidate>[], this.error});

  /// Candidates found for any barcode.
  final List<GlobalBarcodeCandidate> candidates;

  /// Thrown instead of answering.
  final Exception? error;

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    await Future<void>.delayed(barcodeSourceAnswerDelay);
    if (error case final error?) {
      throw error;
    }
    return candidates;
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {}
}
