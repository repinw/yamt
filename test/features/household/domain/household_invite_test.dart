import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

void main() {
  test('the link parses back into the same invite', () {
    final invite = HouseholdInvite(
      code: '012345',
      secret: RecoveryKey.generate(),
    );

    expect(invite.link, startsWith('yamt://household/join?code=012345&'));
    expect(HouseholdInvite.parse('  ${invite.link} '), invite);
  });

  test('anything but an invite link is rejected', () {
    final secret = RecoveryKey.generate().formatted;
    for (final text in <String>[
      '123456',
      'https://household/join?code=123456&secret=$secret',
      'yamt://household/leave?code=123456&secret=$secret',
      'yamt://household/join?code=12345&secret=$secret',
      'yamt://household/join?code=123456',
      'yamt://household/join?code=123456&secret=nope',
    ]) {
      expect(HouseholdInvite.tryParse(text), isNull, reason: text);
      expect(() => HouseholdInvite.parse(text), throwsFormatException);
    }
  });

  test('a deep link is read with or without scheme and host', () {
    final invite = HouseholdInvite(
      code: '123456',
      secret: RecoveryKey.generate(),
    );
    final link = Uri.parse(invite.link);

    expect(HouseholdInvite.fromDeepLink(link), invite);
    expect(
      HouseholdInvite.fromDeepLink(Uri(path: link.path, query: link.query)),
      invite,
    );
    expect(
      HouseholdInvite.fromDeepLink(Uri.parse('/join?code=123456')),
      isNull,
    );
    expect(
      HouseholdInvite.fromDeepLink(
        Uri.parse('/home/diary?code=123456&secret=x'),
      ),
      isNull,
    );
  });
}
