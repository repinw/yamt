import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/home_shell_top_sliver_chrome.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';

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
    test('returns preferred size for regular and compact layouts', () {
      const regular = HomeTopBar(title: 'Diary', actions: <Widget>[]);
      const compact = HomeTopBar(
        title: 'Diary',
        compact: true,
        actions: <Widget>[],
      );

      expect(regular.preferredSize.height, 76);
      expect(compact.preferredSize.height, 88);
    });

    testWidgets('wraps icon actions in circular app bar surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: 'Today',
            actions: <Widget>[
              IconButton(onPressed: null, icon: Icon(Icons.more_horiz)),
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
        colors.surfaceContainerHigh,
      );
    });

    testWidgets('renders title with provided title color', (tester) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: 'Today',
            titleColor: Colors.red,
            actions: <Widget>[],
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Today'));
      expect(title.style?.color, Colors.red);
    });

    testWidgets('keeps a long title constrained to one line', (tester) async {
      const longTitle =
          'A very long diary title that should never force the top bar wider';

      await tester.binding.setSurfaceSize(const Size(260, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _homeTopBarHarness(
          const HomeTopBar(
            title: longTitle,
            actions: <Widget>[
              IconButton(onPressed: null, icon: Icon(Icons.more_horiz)),
            ],
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text(longTitle));
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}

class _ZeroHeightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const new();

  @override
  Size get preferredSize => Size.zero;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

Widget _homeTopBarHarness(PreferredSizeWidget appBar) {
  return MaterialApp(
    home: Scaffold(appBar: appBar, body: const SizedBox.shrink()),
  );
}
