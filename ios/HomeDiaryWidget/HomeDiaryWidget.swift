import SwiftUI
import WidgetKit

/// Widget kind. Must match `homeWidgetIOSName` in
/// `lib/features/home_widget/data/home_widget_plugin_bridge.dart`, which
/// `HomeWidget.updateWidget(iOSName: ...)` reloads.
private let widgetKind = "HomeDiaryWidget"

/// Home-screen widget mirroring the Diary daily balance card
/// (`DiaryDailyBalanceCard`, quiet mode). The large size adds the compact
/// quick-eat bar below it, like the Android widget.
@main
struct HomeDiaryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: widgetKind, provider: HomeDiaryTimelineProvider()) { entry in
      HomeDiaryWidgetView(entry: entry)
    }
    .configurationDisplayName("YAMT")
    .description(localized("home_widget_description"))
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct HomeDiaryEntry: TimelineEntry {
  let date: Date
  let snapshot: HomeDiarySnapshot?
}

/// Reads the snapshot Flutter saved. The app reloads the timeline on every
/// sync, so a single entry that never expires is enough.
struct HomeDiaryTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> HomeDiaryEntry {
    HomeDiaryEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (HomeDiaryEntry) -> Void) {
    let snapshot = HomeDiarySnapshot.load() ?? (context.isPreview ? .preview : nil)
    completion(HomeDiaryEntry(date: Date(), snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HomeDiaryEntry>) -> Void) {
    let entry = HomeDiaryEntry(date: Date(), snapshot: HomeDiarySnapshot.load())
    completion(Timeline(entries: [entry], policy: .never))
  }
}

struct HomeDiaryWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: HomeDiaryEntry

  var body: some View {
    if family == .systemLarge {
      // Diary page look: card shell on the page surface, quick-eat bar below.
      VStack(spacing: 12) {
        BalanceShell { card }
        QuickEatBar()
      }
      .frame(maxHeight: .infinity)
      .widgetBackground(HomeWidgetColors.surface)
    } else {
      // The widget itself is the card.
      card
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetBackground(HomeWidgetColors.surfaceContainerLow)
        .widgetURL(homeWidgetUrl("open"))
    }
  }

  @ViewBuilder private var card: some View {
    if let snapshot = entry.snapshot {
      BalanceCardContent(snapshot: snapshot)
    } else {
      Text(localized("home_widget_no_data"))
        .font(.system(size: 14))
        .foregroundColor(HomeWidgetColors.onSurfaceVariant)
    }
  }
}

/// DiaryBalanceShell: surfaceContainerLow, outlineVariant border, radius lg,
/// padding xl. Tapping the card opens the app.
private struct BalanceShell<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    Link(destination: homeWidgetUrl("open")) {
      content()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(HomeWidgetColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(HomeWidgetColors.outlineVariant, lineWidth: 1))
    }
  }
}

extension View {
  /// iOS 17 needs `containerBackground`; older versions draw the background
  /// and the default widget margins themselves.
  @ViewBuilder func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
    }
  }
}
