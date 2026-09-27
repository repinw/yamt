import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
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
      const regular = HomeTopBar(title: 'Diary', tools: <Widget>[]);
      const compact = HomeTopBar(
        title: 'Diary',
        compact: true,
        tools: <Widget>[],
      );

      expect(regular.preferredSize.height, 76);
      expect(compact.preferredSize.height, 88);
    });

    testWidgets('shows the title in ink next to labeled tools', (tester) async {
      await tester.pumpWidget(
        _homeTopBarHarness(
          HomeTopBar(
            title: 'Today',
            tools: [
              HomeHeaderTool(
                symbol: const Icon(Icons.more_horiz),
                label: 'More',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final context = tester.element(find.byType(HomeTopBar));
      final title = tester.widget<Text>(find.text('Today'));
      expect(title.style?.color, Theme.of(context).colorScheme.onSurface);
      expect(find.text('MORE'), findsOneWidget);
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
            tools: <Widget>[
              HomeHeaderTool(
                symbol: Icon(Icons.more_horiz),
                label: 'More',
                onPressed: null,
              ),
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
