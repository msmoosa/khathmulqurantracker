package com.khathmulqurantracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Home screen widget showing the reading streak, where the reader is up to
 * and how far through the khathm. The app saves the values (see
 * HomeWidgetSync in lib/state/home_widget_sync.dart); a tap opens the
 * reader at the tracked verse.
 */
class KhathmWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val position = widgetData.getString("position", null)
        val percent = widgetData.number("percent")
        val lastRead = widgetData.getString("last_read_day", null)

        // The streak was counted up to the last day read: it still stands
        // if that was today or yesterday.
        val days = Calendar.getInstance()
        val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val today = format.format(days.time)
        days.add(Calendar.DAY_OF_MONTH, -1)
        val yesterday = format.format(days.time)
        val readToday = lastRead == today
        val streak =
            if (readToday || lastRead == yesterday) widgetData.number("streak") else 0

        val views = RemoteViews(context.packageName, R.layout.khathm_widget)
        views.setTextViewText(R.id.streak, "🔥 $streak")
        views.setTextViewText(
            R.id.streak_label,
            if (streak > 0) "day streak" else "Start a streak today",
        )
        views.setTextViewText(R.id.position, position ?: "Start tracking your khathm")
        views.setProgressBar(R.id.progress, 100, percent, false)
        val todayVerses = if (readToday) widgetData.number("last_read_verses") else 0
        views.setTextViewText(
            R.id.detail,
            "$percent% of khathm · " +
                when {
                    todayVerses == 1 -> "1 verse today"
                    todayVerses > 1 -> "$todayVerses verses today"
                    else -> "Not read today yet"
                },
        )
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("khathmtracker://continue?homeWidget"),
            ),
        )
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** A whole number saved from Dart, which may arrive as an Int or a Long. */
    private fun SharedPreferences.number(key: String): Int =
        (all[key] as? Number)?.toInt() ?: 0
}
