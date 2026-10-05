package com.example.focus_guard

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "focus_guard/apps"

    private val PREFS_NAME = "focus_guard_preferences"

    private val BLOCKED_APPS_KEY = "blocked_apps"
    private val PROTECTION_ENABLED_KEY = "protection_enabled"

    private val SCHEDULE_ENABLED_KEY = "schedule_enabled"
    private val START_HOUR_KEY = "start_hour"
    private val START_MINUTE_KEY = "start_minute"
    private val END_HOUR_KEY = "end_hour"
    private val END_MINUTE_KEY = "end_minute"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // ---------------------------------------------------------
                // Get installed apps
                // ---------------------------------------------------------

                "getInstalledApps" -> {

                    try {

                        val packageManager = packageManager

                        val apps = packageManager
                            .getInstalledApplications(0)
                            .filter { appInfo ->

                                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0
                            }
                            .map { appInfo ->

                                val appName =
                                    packageManager
                                        .getApplicationLabel(appInfo)
                                        .toString()

                                mapOf(
                                    "name" to appName,
                                    "packageName" to appInfo.packageName
                                )
                            }
                            .sortedBy {
                                it["name"]
                                    .toString()
                                    .lowercase()
                            }

                        result.success(apps)

                    } catch (e: Exception) {

                        result.error(
                            "APP_LIST_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ---------------------------------------------------------
                // Get selected/blocked apps
                // ---------------------------------------------------------

                "getBlockedApps" -> {

                    val preferences =
                        getSharedPreferences(
                            PREFS_NAME,
                            Context.MODE_PRIVATE
                        )

                    val blockedApps =
                        preferences
                            .getStringSet(
                                BLOCKED_APPS_KEY,
                                emptySet()
                            )
                            ?.toList()
                            ?: emptyList()

                    result.success(blockedApps)
                }

                // ---------------------------------------------------------
                // Save selected/blocked apps
                // ---------------------------------------------------------

                "setBlockedApps" -> {

                    try {

                        val apps =
                            call.argument<List<String>>("apps")
                                ?: emptyList()

                        val preferences =
                            getSharedPreferences(
                                PREFS_NAME,
                                Context.MODE_PRIVATE
                            )

                        preferences.edit()
                            .putStringSet(
                                BLOCKED_APPS_KEY,
                                apps.toSet()
                            )
                            .apply()

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "SAVE_BLOCKED_APPS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ---------------------------------------------------------
                // Accessibility status
                // ---------------------------------------------------------

                "isAccessibilityEnabled" -> {

                    result.success(
                        isAccessibilityServiceEnabled()
                    )
                }

                // ---------------------------------------------------------
                // Open Accessibility settings
                // ---------------------------------------------------------

                "openAccessibilitySettings" -> {

                    try {

                        val intent = Intent(
                            Settings.ACTION_ACCESSIBILITY_SETTINGS
                        )

                        startActivity(intent)

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "ACCESSIBILITY_SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ---------------------------------------------------------
                // Get protection status
                // ---------------------------------------------------------

                "getProtectionEnabled" -> {

                    val preferences =
                        getSharedPreferences(
                            PREFS_NAME,
                            Context.MODE_PRIVATE
                        )

                    val enabled =
                        preferences.getBoolean(
                            PROTECTION_ENABLED_KEY,
                            true
                        )

                    result.success(enabled)
                }

                // ---------------------------------------------------------
                // Set protection status
                // ---------------------------------------------------------

                "setProtectionEnabled" -> {

                    val enabled =
                        call.argument<Boolean>("enabled")
                            ?: true

                    getSharedPreferences(
                        PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                        .edit()
                        .putBoolean(
                            PROTECTION_ENABLED_KEY,
                            enabled
                        )
                        .apply()

                    result.success(true)
                }

                // ---------------------------------------------------------
                // Get schedule
                // ---------------------------------------------------------

                "getSchedule" -> {

                    val preferences =
                        getSharedPreferences(
                            PREFS_NAME,
                            Context.MODE_PRIVATE
                        )

                    val schedule = mapOf(
                        "enabled" to preferences.getBoolean(
                            SCHEDULE_ENABLED_KEY,
                            false
                        ),
                        "startHour" to preferences.getInt(
                            START_HOUR_KEY,
                            22
                        ),
                        "startMinute" to preferences.getInt(
                            START_MINUTE_KEY,
                            0
                        ),
                        "endHour" to preferences.getInt(
                            END_HOUR_KEY,
                            7
                        ),
                        "endMinute" to preferences.getInt(
                            END_MINUTE_KEY,
                            0
                        )
                    )

                    result.success(schedule)
                }

                // ---------------------------------------------------------
                // Save schedule
                // ---------------------------------------------------------

                "setSchedule" -> {

                    try {

                        val enabled =
                            call.argument<Boolean>("enabled")
                                ?: false

                        val startHour =
                            call.argument<Int>("startHour")
                                ?: 22

                        val startMinute =
                            call.argument<Int>("startMinute")
                                ?: 0

                        val endHour =
                            call.argument<Int>("endHour")
                                ?: 7

                        val endMinute =
                            call.argument<Int>("endMinute")
                                ?: 0

                        getSharedPreferences(
                            PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                            .edit()
                            .putBoolean(
                                SCHEDULE_ENABLED_KEY,
                                enabled
                            )
                            .putInt(
                                START_HOUR_KEY,
                                startHour
                            )
                            .putInt(
                                START_MINUTE_KEY,
                                startMinute
                            )
                            .putInt(
                                END_HOUR_KEY,
                                endHour
                            )
                            .putInt(
                                END_MINUTE_KEY,
                                endMinute
                            )
                            .apply()

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "SAVE_SCHEDULE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ---------------------------------------------------------
                // Check if schedule is currently active
                // ---------------------------------------------------------

                "isScheduleActive" -> {

                    result.success(
                        isScheduleCurrentlyActive()
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // =========================================================
    // Accessibility helper
    // =========================================================

    private fun isAccessibilityServiceEnabled(): Boolean {

        val accessibilityManager =
            getSystemService(
                Context.ACCESSIBILITY_SERVICE
            ) as AccessibilityManager

        val enabledServices =
            accessibilityManager
                .getEnabledAccessibilityServiceList(
                    AccessibilityServiceInfo.FEEDBACK_ALL_MASK
                )

        val expectedPackage =
            packageName

        return enabledServices.any { serviceInfo ->

            serviceInfo.resolveInfo
                ?.serviceInfo
                ?.packageName == expectedPackage
        }
    }

    // =========================================================
    // Schedule helper
    // =========================================================

    private fun isScheduleCurrentlyActive(): Boolean {

        val preferences =
            getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

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
            startHour * 60 + startMinute

        val endMinutes =
            endHour * 60 + endMinute

        // Same time means the schedule is considered active
        // all day.
        if (startMinutes == endMinutes) {
            return true
        }

        // Normal schedule:
        // 09:00 -> 17:00
        if (startMinutes < endMinutes) {

            return currentMinutes >= startMinutes &&
                   currentMinutes < endMinutes
        }

        // Overnight schedule:
        // 22:00 -> 07:00
        return currentMinutes >= startMinutes ||
               currentMinutes < endMinutes
    }
}