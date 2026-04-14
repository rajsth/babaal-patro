package com.babaal.patro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NepaliDateSmallWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = buildViews(context)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED
        ) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, NepaliDateSmallWidget::class.java))
            if (ids.isNotEmpty()) {
                onUpdate(context, mgr, ids)
            }
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.nepali_date_small_widget)

        val bs = NepaliCalendar.now()
        val day = NepaliCalendar.toNepaliNumeral(bs.day)
        val monthName = NepaliCalendar.monthNames[bs.month - 1]
        val monthYear = "$monthName ${NepaliCalendar.toNepaliNumeral(bs.year)}"
        val dayName = NepaliCalendar.dayFullNames[bs.weekday - 1]

        val widgetData = HomeWidgetPlugin.getData(context)
        val accentHex = widgetData.getString("accent_color", "#FFB388FF")
        val accentColor = try { Color.parseColor(accentHex) } catch (_: Exception) { Color.parseColor("#FFB388FF") }

        views.setTextViewText(R.id.tv_nepali_day, day)
        views.setTextViewText(R.id.tv_nepali_month_year, monthYear)
        views.setTextViewText(R.id.tv_nepali_day_name, dayName)
        views.setTextColor(R.id.tv_nepali_day, accentColor)

        // Tap widget to open the app.
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 1, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
