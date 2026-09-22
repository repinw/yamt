package de.yamt.app.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.size
import androidx.glance.layout.width
import de.yamt.app.MainActivity
import de.yamt.app.R
import es.antonborri.home_widget.actionStartActivity

/**
 * Compact DiaryQuickEatBar: glyph-only buttons, height 44, radius md (14),
 * surfaceContainerLow, gap xs (8). Search, AI and barcode open the product
 * search hub (HomeWidgetClickAction parses the uri).
 */
@Composable
internal fun QuickEatBar(context: Context) {
  val buttons =
      listOf(
          Triple(R.drawable.ic_widget_search, R.string.home_widget_action_search, "quick-add?intent=search"),
          Triple(R.drawable.ic_widget_ai, R.string.home_widget_action_ai, "quick-add?intent=ai"),
          Triple(R.drawable.ic_widget_barcode, R.string.home_widget_action_barcode, "quick-add?intent=barcode"),
      )
  Row(modifier = GlanceModifier.fillMaxWidth()) {
    buttons.forEachIndexed { index, (icon, description, path) ->
      if (index > 0) {
        Spacer(modifier = GlanceModifier.width(8.dp))
      }
      Box(
          modifier =
              GlanceModifier.defaultWeight()
                  .height(44.dp)
                  .background(HomeWidgetColors.surfaceContainerLow)
                  .cornerRadius(14.dp)
                  .clickable(openAppAction(context, "homewidget://$path")),
          contentAlignment = Alignment.Center,
      ) {
        Image(
            provider = ImageProvider(icon),
            contentDescription = context.getString(description),
            colorFilter = ColorFilter.tint(HomeWidgetColors.onSurface),
            modifier = GlanceModifier.size(20.dp),
        )
      }
    }
  }
}

/**
 * Opens [MainActivity] with [uri] as the launch data home_widget hands to
 * Flutter. Always pass a uri: a null Intent.data collides with Glance's own
 * glance_actions://CALLBACK action dispatch. HomeWidgetClickAction ignores
 * any uri that isn't a quick-add action, so those just open the app.
 */
internal fun openAppAction(context: Context, uri: String): Action =
    actionStartActivity<MainActivity>(context, Uri.parse(uri))
