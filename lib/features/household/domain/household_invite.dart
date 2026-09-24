import 'package:meta/meta.dart';
import 'package:yamt/core/data/recovery_key.dart';

const _linkScheme = 'yamt';
const _linkHost = 'household';
const _linkPath = '/join';
const _codeParameter = 'code';
const _secretParameter = 'secret';
final _codePattern = RegExp(r'^\d{6}$');

/// An invitation into a household.
///
/// The [code] names the invite document on the server. The [secret] opens the
/// household key stored there; it travels only in the QR code or link, never
/// to the server.
@immutable
class HouseholdInvite {
  /// Creates an invite.
  const new({required this.code, required this.secret});

  /// Parses a shared invite link, for example
  /// `yamt://household/join?code=123456&secret=XXXX-…`.
  ///
  /// Throws [FormatException] for anything else.
  factory parse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null ||
        uri.scheme != _linkScheme ||
        uri.host != _linkHost ||
        uri.path != _linkPath) {
      throw const FormatException('Not a household invite link.');
    }
    final code = uri.queryParameters[_codeParameter] ?? '';
    final secret = uri.queryParameters[_secretParameter] ?? '';
    if (!_codePattern.hasMatch(code)) {
      throw const FormatException('Invite code must have six digits.');
    }
    return HouseholdInvite(code: code, secret: RecoveryKey.parse(secret));
  }

  /// Parses [text] like [HouseholdInvite.parse], but returns `null` instead of
  /// throwing.
  static HouseholdInvite? tryParse(String text) {
    try {
      return HouseholdInvite.parse(text);
    } on FormatException {
      return null;
    }
  }

  /// Reads an invite from a deep link that opened the app.
  ///
  /// The platform may hand over the full link or only its path and query, so
  /// this accepts `/join?code=…&secret=…` with or without scheme and host.
  static HouseholdInvite? fromDeepLink(Uri uri) {
    if (uri.path != _linkPath ||
        (uri.hasScheme && uri.scheme != _linkScheme) ||
        (uri.host.isNotEmpty && uri.host != _linkHost)) {
      return null;
    }
    return tryParse(
      uri.replace(scheme: _linkScheme, host: _linkHost).toString(),
    );
  }

  /// The six-digit code of the invite document.
  final String code;

  /// The secret that opens the household key.
  final RecoveryKey secret;

  /// The link that the QR code shows and that the user can share.
  String get link => Uri(
    scheme: _linkScheme,
    host: _linkHost,
    path: _linkPath,
    queryParameters: <String, String>{
      _codeParameter: code,
      _secretParameter: secret.formatted,
    },
  ).toString();

  @override
  bool operator ==(Object other) =>
      other is HouseholdInvite && other.code == code && other.link == link;

  @override
  int get hashCode => link.hashCode;
}
