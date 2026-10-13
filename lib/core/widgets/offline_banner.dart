import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/provider/network_connectivity.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows a strip under the status bar while the device is offline, and a
/// short "Back online" snack bar when the connection returns after that.
/// Wraps the app below its `ScaffoldMessenger`.
class OfflineBanner extends ConsumerWidget {
  /// Creates the banner around [child].
  const new({required this.child, super.key});

  /// Key of the strip shown while the device is offline.
  static const stripKey = Key('offline_banner_strip');

  /// Key of the snack bar shown when the connection returns.
  static const backOnlineKey = Key('offline_banner_back_online');

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(deviceOfflineProvider, (previous, next) {
      if (previous?.value == true && next.value == false) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          AppLocalizations.of(context)!.connectivityBackOnline,
          key: backOnlineKey,
        );
      }
    });
    // An unknown state counts as online: the strip shows only a known loss.
    final offline = ref.watch(deviceOfflineProvider).value ?? false;
    final mediaQuery = MediaQuery.of(context);

    // Both states keep the app in the same place of the tree, so it keeps
    // its state when the strip comes and goes. The strip stands on top but
    // is painted after the app: the modal barrier of a route hides from
    // screen readers everything painted before it.
    return Column(
      verticalDirection: VerticalDirection.up,
      children: [
        Expanded(
          child: MediaQuery(
            // The strip covers the status bar, so the app starts below it.
            data: offline
                ? mediaQuery
                      .removePadding(removeTop: true)
                      .removeViewPadding(removeTop: true)
                : mediaQuery,
            child: child,
          ),
        ),
        if (offline) const _OfflineStrip() else const SizedBox.shrink(),
      ],
    );
  }
}

class _OfflineStrip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerHighest;
    final foreground = theme.colorScheme.onSurface;
    final backgroundBrightness = ThemeData.estimateBrightnessForColor(
      background,
    );

    // The strip lies under the status bar, so the status bar icons follow
    // its color.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: backgroundBrightness,
        statusBarIconBrightness: backgroundBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Material(
        key: OfflineBanner.stripKey,
        color: background,
        child: SafeArea(
          bottom: false,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: AppSizes.offlineBannerIcon,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.connectivityOfflineBanner,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
