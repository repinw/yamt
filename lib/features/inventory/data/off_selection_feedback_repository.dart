import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/off_product_search_config.dart';

part 'off_selection_feedback_repository.g.dart';

const _offSelectionFeedbackLogName = 'OffSelectionFeedbackRepository';

/// One product a user picked for a receipt line.
class OffSelectionFeedback {
  /// Creates a selection feedback entry.
  const new({
    required this.receiptLine,
    required this.code,
    this.store,
    this.brand,
    this.weight,
    this.rank,
  });

  /// The receipt line as printed, as sent to search (`raw`).
  final String receiptLine;

  /// Barcode of the chosen product.
  final String code;

  /// Store as sent to search.
  final String? store;

  /// Receipt brand as sent to search.
  final String? brand;

  /// Receipt weight as sent to search.
  final String? weight;

  /// 0-based position of the product among the suggestions, if it was one.
  final int? rank;

  /// Request body for `POST /feedback`.
  Map<String, Object> toJson() => <String, Object>{
    'raw': receiptLine,
    'code': code,
    if (store case final store? when store.isNotEmpty) 'store': store,
    if (brand case final brand? when brand.isNotEmpty) 'brand': brand,
    if (weight case final weight? when weight.isNotEmpty) 'weight': weight,
    'rank': ?rank,
  };
}

/// Reports picked products to the OFF search server, which uses them to
/// grow its search eval set.
abstract interface class OffSelectionFeedbackRepository {
  /// Sends [entries]. Never throws; failures are only logged.
  Future<void> report(List<OffSelectionFeedback> entries);
}

/// Off selection feedback repository.
@Riverpod(keepAlive: true)
OffSelectionFeedbackRepository offSelectionFeedbackRepository(Ref ref) {
  final searchUri = resolveOffProductSearchUri();
  if (searchUri == null) {
    return const _UnavailableOffSelectionFeedbackRepository();
  }

  final client = http.Client();
  ref.onDispose(client.close);
  return HttpOffSelectionFeedbackRepository(
    client: client,
    feedbackUri: offSelectionFeedbackUri(searchUri),
  );
}

/// The feedback endpoint next to the configured search endpoint.
Uri offSelectionFeedbackUri(Uri searchUri) {
  final pathSegments = searchUri.pathSegments.toList(growable: true);
  if (pathSegments.isNotEmpty && pathSegments.last == 'search') {
    pathSegments.removeLast();
  }
  pathSegments.add('feedback');
  return Uri(
    scheme: searchUri.scheme,
    userInfo: searchUri.userInfo,
    host: searchUri.host,
    port: searchUri.hasPort ? searchUri.port : null,
    pathSegments: pathSegments,
  );
}

/// Defines http off selection feedback repository.
class HttpOffSelectionFeedbackRepository
    implements OffSelectionFeedbackRepository {
  /// The http off selection feedback repository.
  const new({required this._client, required this._feedbackUri});

  final http.Client _client;
  final Uri _feedbackUri;

  @override
  Future<void> report(List<OffSelectionFeedback> entries) async {
    for (final entry in entries) {
      try {
        final response = await _client
            .post(
              _feedbackUri,
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(entry.toJson()),
            )
            .timeout(offProductSearchTimeout());
        if (response.statusCode != 200) {
          // An older server without the endpoint answers 404; that is fine.
          log(
            'OFF selection feedback failed with status '
            '${response.statusCode}.',
            name: _offSelectionFeedbackLogName,
          );
          return;
        }
      } on Object catch (error, stackTrace) {
        log(
          'OFF selection feedback request failed.',
          name: _offSelectionFeedbackLogName,
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
    }
  }
}

class _UnavailableOffSelectionFeedbackRepository
    implements OffSelectionFeedbackRepository {
  const new();

  @override
  Future<void> report(List<OffSelectionFeedback> entries) async {}
}
