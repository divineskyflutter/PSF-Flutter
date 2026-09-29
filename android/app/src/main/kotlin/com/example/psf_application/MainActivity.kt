package com.example.psf_application

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Exposes the phone number(s) Android already associates with this
/// device's SIM slot(s) — when the OS/carrier actually populates them;
/// many devices/carriers never do, so an empty result here is the normal
/// case, not a bug — to the login screen's mobile-number field, via a
/// small platform channel (see SimNumberUtil on the Dart side). Read-only:
/// this never sends anything anywhere, and only ever runs after the
/// member has granted READ_PHONE_NUMBERS, which the Dart side asks for
/// first.
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.psf_application/sim"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSimPhoneNumbers") {
                    result.success(getSimPhoneNumbers())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun getSimPhoneNumbers(): List<String> {
        val hasPermission = checkSelfPermission(Manifest.permission.READ_PHONE_NUMBERS) ==
            PackageManager.PERMISSION_GRANTED

        if (!hasPermission) return emptyList()

        val numbers = LinkedHashSet<String>()

        // Dual-SIM devices: each active subscription can carry its own
        // number. Falls through to the single-number check below when this
        // API isn't available or reports nothing (very common — most
        // carriers never program this field at all).
        try {
            val subscriptionManager = getSystemService(SubscriptionManager::class.java)
            subscriptionManager?.activeSubscriptionInfoList?.forEach { info ->
                val number = info.number
                if (!number.isNullOrBlank()) numbers.add(number)
            }
        } catch (_: SecurityException) {
            // Falls through to the single-SIM fallback below.
        } catch (_: Exception) {
            // Some OEMs throw unexpected exceptions here instead of just
            // returning null/empty — never let that reach the caller.
        }

        if (numbers.isEmpty()) {
            try {
                val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
                val number = telephonyManager?.line1Number
                if (!number.isNullOrBlank()) numbers.add(number)
            } catch (_: SecurityException) {
                // No number available — the Dart side treats an empty list
                // as "nothing to suggest", not an error.
            }
        }

        return numbers.toList()
    }
}
