import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yamt/features/inventory/data/off_selection_feedback_repository.dart';

void main() {
  test('feedback uri replaces the search path', () {
    expect(
      offSelectionFeedbackUri(Uri.parse('https://api.yamt.de/search')),
      Uri.parse('https://api.yamt.de/feedback'),
    );
    expect(
      offSelectionFeedbackUri(Uri.parse('https://example.com/off/search?x=1')),
      Uri.parse('https://example.com/off/feedback'),
    );
  });

  test('report posts each entry as json', () async {
    final requests = <http.Request>[];
    final repository = HttpOffSelectionFeedbackRepository(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{"ok": true}', 200);
      }),
      feedbackUri: Uri.parse('https://example.com/feedback'),
    );

    await repository.report(const <OffSelectionFeedback>[
      OffSelectionFeedback(
        receiptLine: 'Bitb.Pils Stubbi',
        code: '4102430015008',
        store: 'Kaufland',
        rank: 0,
      ),
      OffSelectionFeedback(receiptLine: 'Milch', code: '1', brand: ''),
    ]);

    expect(requests, hasLength(2));
    expect(requests.first.method, 'POST');
    expect(requests.first.url, Uri.parse('https://example.com/feedback'));
    expect(jsonDecode(requests.first.body), <String, Object>{
      'raw': 'Bitb.Pils Stubbi',
      'code': '4102430015008',
      'store': 'Kaufland',
      'rank': 0,
    });
    expect(jsonDecode(requests.last.body), <String, Object>{
      'raw': 'Milch',
      'code': '1',
    });
  });

  test('report stops quietly when the server has no endpoint', () async {
    var calls = 0;
    final repository = HttpOffSelectionFeedbackRepository(
      client: MockClient((request) async {
        calls++;
        return http.Response('{"ok": false}', 404);
      }),
      feedbackUri: Uri.parse('https://example.com/feedback'),
    );

    await repository.report(const <OffSelectionFeedback>[
      OffSelectionFeedback(receiptLine: 'a', code: '1'),
      OffSelectionFeedback(receiptLine: 'b', code: '2'),
    ]);

    expect(calls, 1);
  });
}
