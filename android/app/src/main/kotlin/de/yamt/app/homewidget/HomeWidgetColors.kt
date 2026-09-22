package de.yamt.app.homewidget

import androidx.glance.unit.ColorProvider
import de.yamt.app.R

/**
 * Resource-backed colors, so light/dark follows values/colors.xml and
 * values-night/colors.xml. Names match the Flutter ColorScheme and
 * MetricAccentColors roles the Diary card uses.
 */
internal object HomeWidgetColors {
  val surface = ColorProvider(R.color.home_widget_surface)
  val surfaceContainerLow = ColorProvider(R.color.home_widget_surface_container_low)
  val outlineVariant = ColorProvider(R.color.home_widget_outline_variant)
  val onSurface = ColorProvider(R.color.home_widget_on_surface)
  val onSurfaceVariant = ColorProvider(R.color.home_widget_on_surface_variant)
  val primary = ColorProvider(R.color.home_widget_primary)
  val error = ColorProvider(R.color.home_widget_error)
  val protein = ColorProvider(R.color.home_widget_protein)
  val carbs = ColorProvider(R.color.home_widget_carbs)
  val fat = ColorProvider(R.color.home_widget_fat)
}
