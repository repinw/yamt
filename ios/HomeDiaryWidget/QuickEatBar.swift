import SwiftUI

/// Compact DiaryQuickEatBar: glyph-only buttons, height 44, radius md (14),
/// surfaceContainerLow, gap xs (8). Search, AI and barcode open the product
/// search hub (HomeWidgetClickAction parses the uri). Same buttons as the
/// Android widget's QuickEatBar.kt.
struct QuickEatBar: View {
  private struct QuickEatButton {
    let symbol: String
    let descriptionKey: String
    let path: String
  }

  private let buttons = [
    QuickEatButton(symbol: "magnifyingglass", descriptionKey: "home_widget_action_search", path: "quick-add?intent=search"),
    QuickEatButton(symbol: "sparkles", descriptionKey: "home_widget_action_ai", path: "quick-add?intent=ai"),
    QuickEatButton(symbol: "barcode.viewfinder", descriptionKey: "home_widget_action_barcode", path: "quick-add?intent=barcode"),
  ]

  var body: some View {
    HStack(spacing: 8) {
      ForEach(buttons, id: \.path) { button in
        Link(destination: homeWidgetUrl(button.path)) {
          Image(systemName: button.symbol)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(HomeWidgetColors.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(HomeWidgetColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel(localized(button.descriptionKey))
        }
      }
    }
  }
}

/// `homewidget://<path>` plus the `homeWidget` query item the home_widget
/// plugin needs to hand the URL to Flutter. HomeWidgetClickAction ignores
/// any uri that isn't a quick-add action, so those just open the app.
func homeWidgetUrl(_ path: String) -> URL {
  let separator = path.contains("?") ? "&" : "?"
  return URL(string: "homewidget://\(path)\(separator)homeWidget")!
}
