package com.nexoloterias.nexo_loterias

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NexoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.nexo_widget)

        val prefs = HomeWidgetPlugin.getData(context)
        val numeros = prefs.getString("palpite_numeros", "-- -- -- -- -- --")
        val modalidade = prefs.getString("palpite_modalidade", "Mega-Sena")
        val data = prefs.getString("palpite_data", "Abra o app para gerar")

        views.setTextViewText(R.id.widget_numeros, numeros)
        views.setTextViewText(R.id.widget_modalidade, modalidade)
        views.setTextViewText(R.id.widget_data, data)

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
