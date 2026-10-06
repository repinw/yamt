import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show PlatformException;

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Android gets the update from Google Play. iOS gets it from TestFlight, so
/// the TestFlight app opens; switch to the App Store page once yamt is there.
final Uri _storeUri = Platform.isIOS
    ? Uri.parse('itms-beta://')
    : Uri.parse('market://details?id=de.yamt.app');

/// Opens in the browser when the store app is missing.
final Uri _webStoreUri = Platform.isIOS
    ? Uri.parse('https://testflight.apple.com')
    : Uri.parse('https://play.google.com/store/apps/details?id=de.yamt.app');

/// Opens the place where this device gets app updates, or its web page when
/// the store app is missing. Shows a snackbar when nothing opens.
Future<void> openAppUpdateStore(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context)!.appUpdateStoreOpenFailed;
  final opened = await _launch(_storeUri) || await _launch(_webStoreUri);
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool> _launch(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException catch (error, stackTrace) {
    log(
      'Opening $uri failed.',
      name: 'AppUpdate',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
