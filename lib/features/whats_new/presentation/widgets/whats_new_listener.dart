import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/whats_new/presentation/controllers/whats_new_controller.dart';
import 'package:yamt/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the "what's new" notice once per version, as soon as the app is on
/// its home pages, so never over sign-in or onboarding. Wraps the app below
/// its `ScaffoldMessenger`.
class WhatsNewListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// Key of the notice.
  static const noticeKey = Key('whats_new_notice');

  /// The app.
  final Widget child;

  @override
  ConsumerState<WhatsNewListener> createState() => _WhatsNewListenerState();
}

class _WhatsNewListenerState extends ConsumerState<WhatsNewListener> {
  late final GoRouter _router = ref.read(appRouterProvider);
  WhatsNewNotice? _pending;

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_showWhenHome);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_showWhenHome);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(whatsNewControllerProvider, (_, next) {
      if (next case AsyncError(:final error, :final stackTrace)) {
        log(
          'Reading the release notes failed.',
          name: 'WhatsNew',
          error: error,
          stackTrace: stackTrace,
        );
      }
      _pending = next.isLoading ? null : next.value;
      _showWhenHome();
    });
    return widget.child;
  }

  void _showWhenHome() {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (_pending == null || !path.startsWith(AppRoutes.home)) {
      return;
    }
    // After the frame, so a navigation that is still building is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notice = _pending;
      _pending = null;
      if (notice != null && mounted) {
        _show(notice);
      }
    });
  }

  void _show(WhatsNewNotice notice) {
    final l10n = AppLocalizations.of(context)!;
    final notes = notice.release.notesFor(
      Localizations.localeOf(context).languageCode,
    );
    final version = notice.version.toString();
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.whatsNewNotice(version, notes.headline!),
      key: WhatsNewListener.noticeKey,
      tone: AppSnackBarTone.info,
      staysUntilClosed: true,
      action: (
        label: l10n.whatsNewShowAll,
        onPressed: () {
          // The listener sits above the navigator, so the sheet opens on it.
          final navigator = ref.read(navigatorKeyProvider).currentContext;
          if (navigator != null) {
            unawaited(
              showWhatsNewSheet(navigator, version: version, notes: notes),
            );
          }
        },
      ),
    );
    unawaited(
      ref.read(whatsNewControllerProvider.notifier).markShown(notice.version),
    );
  }
}
