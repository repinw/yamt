package de.yamt.app.homewidget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * Registers [HomeDiaryGlanceWidget] as an app widget provider.
 *
 * Its qualified name (`de.yamt.app.homewidget.HomeDiaryWidgetReceiver`) is
 * what Flutter's `HomeWidget.updateWidget(qualifiedAndroidName: ...)` call
 * targets — see `homeWidgetAndroidProviderName` in
 * `lib/features/home_widget/data/home_widget_plugin_bridge.dart`.
 * Registered in `AndroidManifest.xml`.
 */
class HomeDiaryWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HomeDiaryGlanceWidget>() {
  override val glanceAppWidget = HomeDiaryGlanceWidget()
}
