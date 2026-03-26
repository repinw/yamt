import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/widgets/app_background.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/core/router/app_router.dart';

class YAMT extends ConsumerWidget {
  const YAMT({super.key}); // coverage:ignore-line

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final seedColor = ref.watch(seedColorControllerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: themeMode,
      builder: (context, child) => AppBackground(child: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
