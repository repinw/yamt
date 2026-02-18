import 'package:flutter/widgets.dart';

abstract final class AppColors {
  static const Color seed = Color(0xFF29F006);
}

abstract final class AppSeedColors {
  static const Color lime = Color(0xFF29F006);
  static const Color blue = Color(0xFF0D47A1);
  static const Color teal = Color(0xFF00695C);
  static const Color pink = Color.fromARGB(255, 255, 0, 111);
  static const Color orange = Color(0xFFE65100);

  static const List<Color> values = <Color>[lime, blue, teal, pink, orange];
}

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double xxxxl = 32;
}

abstract final class AppInsets {
  static const EdgeInsets zero = EdgeInsets.zero;

  static const EdgeInsets page = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets pageLarge = EdgeInsets.all(AppSpacing.xxxl);
  static const EdgeInsets authPage = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxxxl,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets listVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.xl,
  );

  static const EdgeInsets snackBarMargin = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  static const EdgeInsets dialogInset = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.md,
  );
  static const EdgeInsets actionTilePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
}

abstract final class AppRadius {
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppSizes {
  static const double dialogIconContainer = 44;
  static const double actionChevron = 14;
  static const double welcomeIcon = 80;
  static const double inlineProgressIndicator = 20;
  static const double progressStrokeWidth = 2;
}
