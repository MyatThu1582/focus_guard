package com.example.focus_guard

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import java.util.Calendar

class AppBlockAccessibilityService : AccessibilityService() {

    private val PREFS_NAME = "focus_guard_preferences"

    private val BLOCKED_APPS_KEY = "blocked_apps"
    private val PROTECTION_ENABLED_KEY = "protection_enabled"

    private val SCHEDULE_ENABLED_KEY = "schedule_enabled"
    private val START_HOUR_KEY = "start_hour"
    private val START_MINUTE_KEY = "start_minute"
    private val END_HOUR_KEY = "end_hour"
    private val END_MINUTE_KEY = "end_minute"

    override fun onAccessibilityEvent(
        event: AccessibilityEvent?
    ) {

        if (
            event?.eventType !=
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        ) {
            return
        }

        val packageName =
            event.packageName?.toString()

        if (packageName.isNullOrEmpty()) {
            return
        }

        Log.d(
            "FocusGuard",
            "Current app: $packageName"
        )

        // Never block Focus Guard itself.
        if (
            packageName ==
            applicationContext.packageName
        ) {
            return
        }

        val preferences =
            getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

        // ---------------------------------------------------------
        // Protection must be enabled
        // ---------------------------------------------------------

        val protectionEnabled =
            preferences.getBoolean(
                PROTECTION_ENABLED_KEY,
                true
            )

        if (!protectionEnabled) {
            return
        }

        // ---------------------------------------------------------
        // Schedule must currently be active
        // ---------------------------------------------------------

        if (!isScheduleCurrentlyActive(preferences)) {
            return
        }

        // ---------------------------------------------------------
        // Check selected apps
        // ---------------------------------------------------------

        val blockedApps =
            preferences
                .getStringSet(
                    BLOCKED_APPS_KEY,
                    emptySet()
                )
                ?: emptySet()

        if (!blockedApps.contains(packageName)) {
            return
        }

        // ---------------------------------------------------------
        // BLOCK
        // ---------------------------------------------------------

        Log.d(
            "FocusGuard",
            "BLOCKING SELECTED APP: $packageName"
        )

        val intent =
            Intent(
                this,
                BlockScreenActivity::class.java
            )

        intent.putExtra(
            "blocked_package",
            packageName
        )

        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_CLEAR_TOP or
            Intent.FLAG_ACTIVITY_SINGLE_TOP
        )

        startActivity(intent)
    }

    // =========================================================
    // Schedule calculation
    // =========================================================

    private fun isScheduleCurrentlyActive(
        preferences: android.content.SharedPreferences
    ): Boolean {

        if (!preferences.getBoolean(
                SCHEDULE_ENABLED_KEY,
                false
            )
        ) {
            return false
        }

        val startHour =
            preferences.getInt(
                START_HOUR_KEY,
                22
            )

        val startMinute =
            preferences.getInt(
                START_MINUTE_KEY,
                0
            )

        val endHour =
            preferences.getInt(
                END_HOUR_KEY,
                7
            )

        val endMinute =
            preferences.getInt(
                END_MINUTE_KEY,
                0
            )

        val calendar =
            Calendar.getInstance()

        val currentMinutes =
            calendar.get(Calendar.HOUR_OF_DAY) * 60 +
            calendar.get(Calendar.MINUTE)

        val startMinutes =
            startHour * 60 +
            startMinute

        val endMinutes =
            endHour * 60 +
            endMinute

        // Same start/end = all day.
        if (startMinutes == endMinutes) {
            return true
        }

        // Normal schedule.
        if (startMinutes < endMinutes) {

            return currentMinutes >= startMinutes &&
                   currentMinutes < endMinutes
        }

        // Overnight schedule.
        return currentMinutes >= startMinutes ||
               currentMinutes < endMinutes
    }

    override fun onInterrupt() {

        Log.d(
            "FocusGuard",
            "Accessibility Service interrupted"
        )
    }
}