package com.nepali.calendar.nepali_calendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NepaliDateWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val views = buildViews(context, options)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val views = buildViews(context, newOptions)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun buildViews(context: Context, options: Bundle): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.nepali_date_widget)

        // Read data stored by Flutter via home_widget.
        val widgetData = HomeWidgetPlugin.getData(context)
        val day = widgetData.getString("nepali_day", "--")
        val monthYear = widgetData.getString("nepali_month_year", "---")
        val dayName = widgetData.getString("nepali_day_name", "---")
        val adDate = widgetData.getString("ad_date", "---")

        val accentHex = widgetData.getString("accent_color", "#FFB388FF")
        val accentColor = try { Color.parseColor(accentHex) } catch (_: Exception) { Color.parseColor("#FFB388FF") }
        val dividerColor = Color.argb(0x33, Color.red(accentColor), Color.green(accentColor), Color.blue(accentColor))

        views.setTextViewText(R.id.tv_nepali_day, day)
        views.setTextViewText(R.id.tv_nepali_month_year, monthYear)
        views.setTextViewText(R.id.tv_nepali_day_name, dayName)
        views.setTextViewText(R.id.tv_ad_date, adDate)

        // Apply accent color to themed elements.
        views.setTextColor(R.id.tc_nepal_ampm, accentColor)
        views.setTextColor(R.id.tv_nepali_day, accentColor)
        views.setInt(R.id.divider, "setColorFilter", dividerColor)

        // Scale font sizes based on widget dimensions.
        val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 80)
        val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 200)

        // Use height for vertical sizing, but cap by width to prevent overlap on narrow widgets.
        val widthTimeLimit = (minWidthDp * 0.28f)  // time shouldn't exceed ~28% of width
        val widthDayLimit = (minWidthDp * 0.22f)    // nepali day shouldn't exceed ~22% of width

        val timeSize = (minHeightDp * 0.45f).coerceIn(28f, 72f).coerceAtMost(widthTimeLimit.coerceAtLeast(28f))
        val ampmSize = (minHeightDp * 0.12f).coerceIn(10f, 20f)
        val nepaliDaySize = (minHeightDp * 0.38f).coerceIn(24f, 60f).coerceAtMost(widthDayLimit.coerceAtLeast(24f))
        val bottomTextSize = (minHeightDp * 0.11f).coerceIn(10f, 16f)

        views.setTextViewTextSize(R.id.tc_nepal_time, TypedValue.COMPLEX_UNIT_SP, timeSize)
        views.setTextViewTextSize(R.id.tc_nepal_ampm, TypedValue.COMPLEX_UNIT_SP, ampmSize)
        views.setTextViewTextSize(R.id.tv_nepali_day, TypedValue.COMPLEX_UNIT_SP, nepaliDaySize)
        views.setTextViewTextSize(R.id.tv_ad_date, TypedValue.COMPLEX_UNIT_SP, bottomTextSize)
        views.setTextViewTextSize(R.id.tv_nepali_day_name, TypedValue.COMPLEX_UNIT_SP, bottomTextSize)
        views.setTextViewTextSize(R.id.tv_nepali_month_year, TypedValue.COMPLEX_UNIT_SP, bottomTextSize)

        // Scale vertical padding based on height.
        val verticalPadding = (minHeightDp * 0.12f).coerceIn(8f, 32f)
        val paddingPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, verticalPadding,
            context.resources.displayMetrics
        ).toInt()
        val horizontalPaddingPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 20f,
            context.resources.displayMetrics
        ).toInt()
        views.setViewPadding(R.id.widget_root, horizontalPaddingPx, paddingPx, horizontalPaddingPx, paddingPx)

        // Tap widget to open the app.
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
