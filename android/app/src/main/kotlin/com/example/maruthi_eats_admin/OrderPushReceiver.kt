package com.example.maruthi_eats_admin

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Second listener for incoming FCM messages (the firebase_messaging plugin keeps
 * its own receiver, so this does not replace anything).
 *
 * Phone unlocked + admin app not on screen + new order  ->  draw the native
 * full-screen alert over whatever app is open.
 * Screen off / locked  ->  nothing here; the full-screen-intent notification
 * built by the Flutter background handler wakes the screen instead.
 */
class OrderPushReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            val extras = intent.extras ?: return

            val orderId = extras.getString("order_id") ?: return
            val status = extras.getString("status")
            if (status != null && status != "placed") return

            // App is open: the in-app overlay (HomeShell) already handles it.
            if (MainActivity.isInForeground) return

            val canOverlay = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                    Settings.canDrawOverlays(context)
            if (!canOverlay) return

            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (!pm.isInteractive || km.isKeyguardLocked) return

            OrderAlertOverlay.show(
                context.applicationContext,
                OrderAlertData(
                    orderNumber = orderId.take(6).uppercase(),
                    total = extras.getString("total"),
                    items = extras.getString("items"),
                    payment = extras.getString("payment")
                )
            )
        } catch (e: Exception) {
            Log.e("OrderPushReceiver", "Failed to show order alert: $e")
        }
    }
}