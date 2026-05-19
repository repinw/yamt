import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';

void main() {
  group('HomeShellTopSliverChrome', () {
    testWidgets('handles zero height chrome without layout exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(),
            child: CustomScrollView(
              slivers: [
                HomeShellTopSliverChrome(child: _ZeroHeightAppBar()),
                SliverFillRemaining(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeTopBar', () {
    test('returns subtitle preferred size for regular and compact layouts', () {
      const regular = HomeTopBar(
        title: 'Diary',
        subtitle: 'Mon, Apr 27',
        actions: <Widget>[],
      );
      const compact = HomeTopBar(
        title: 'Diary',
        subtitle: 'Mon, Apr 27',
        compact: true,
        actions: <Widget>[],
      );

      expect(regular.preferredSize.height, 86);
      expect(compact.preferredSize.height, 96);
    });

    testWidgets('renders the supplied subtitle', (tester) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: 'Today',
            subtitle: 'Mon, Apr 27',
            actions: <Widget>[],
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Mon, Apr 27'), findsOneWidget);
    });

    testWidgets('uses app background color for its chrome surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: 'Today',
            subtitle: 'Mon, Apr 27',
            actions: <Widget>[],
          ),
        ),
      );

      final context = tester.element(find.byType(HomeTopBar));
      final colors = Theme.of(context).colorScheme;
      final chrome = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = chrome.decoration as BoxDecoration;

      expect(decoration.color, AppEditorialSurfaces.appBackground(colors));
      expect(decoration.border, isNull);
    });

    testWidgets('wraps icon actions in circular app bar surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: 'Today',
            actions: <Widget>[
              IconButton(
                onPressed: null,
                icon: Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      );

      final context = tester.element(find.byType(HomeTopBar));
      final colors = Theme.of(context).colorScheme;
      final actionTheme = tester.widget<IconButtonTheme>(
        find.ancestor(
          of: find.byIcon(Icons.more_horiz),
          matching: find.byType(IconButtonTheme),
        ),
      );
      final style = actionTheme.data.style!;

      expect(
        style.fixedSize?.resolve(<WidgetState>{}),
        const Size.square(AppSizes.homeTopBarIconButton),
      );
      expect(style.shape?.resolve(<WidgetState>{}), isA<CircleBorder>());
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        AppEditorialSurfaces.section(colors),
      );
    });

    testWidgets('keeps long title and subtitle constrained to one line', (
      tester,
    ) async {
      const longTitle =
          'A very long diary title that should never force the top bar wider';
      const longSubtitle =
          'A very long subtitle date with extra context that should ellipsize';

      await tester.binding.setSurfaceSize(const Size(260, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: longTitle,
            subtitle: longSubtitle,
            actions: <Widget>[
              IconButton(
                onPressed: null,
                icon: Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text(longTitle));
      final subtitleText = tester.widget<Text>(find.text(longSubtitle));
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
      expect(subtitleText.maxLines, 1);
      expect(subtitleText.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}

class _ZeroHeightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ZeroHeightAppBar();

  @override
  Size get preferredSize => Size.zero;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

Widget _homeTopBarHarness(PreferredSizeWidget appBar) {
  return MaterialApp(
    home: Scaffold(
      appBar: appBar,
      body: const SizedBox.shrink(),
    ),
  );
}
