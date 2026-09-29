package com.example.psf_application

import android.content.Intent
import android.content.IntentSender
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Shows Google's own "Phone Number Hint" picker (part of Play Services'
/// Identity APIs) from the login screen's mobile-number field, so the
/// member can tap their own number instead of typing it (see
/// SimNumberUtil on the Dart side). This is the standard, Play-Store-safe
/// way apps do this — unlike reading the number straight off the SIM
/// (TelephonyManager/SubscriptionManager, tried first — many carriers,
/// including the one tested against here, simply never populate that
/// field at all), it needs no dangerous runtime permission, just Google
/// Play Services being present, and shows the member a native Google
/// bottom sheet they can dismiss with nothing picked at any time.
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.psf_application/sim"
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val PHONE_NUMBER_HINT_REQUEST_CODE = 4231
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "showPhoneNumberHint") {
                    showPhoneNumberHint(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun showPhoneNumberHint(result: MethodChannel.Result) {
        // Only one picker can reasonably be on screen at a time — a second
        // call while one is already pending (e.g. a very fast double tap)
        // just fails immediately rather than losing track of the first
        // caller's result.
        if (pendingResult != null) {
            result.error("BUSY", "A phone number picker is already showing.", null)
            return
        }
        pendingResult = result

        val request = GetPhoneNumberHintIntentRequest.builder().build()

        Identity.getSignInClient(this)
            .getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                try {
                    startIntentSenderForResult(
                        pendingIntent.intentSender,
                        PHONE_NUMBER_HINT_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0,
                    )
                } catch (e: IntentSender.SendIntentException) {
                    finishPending(null)
                }
            }
            .addOnFailureListener {
                // No Google account signed in, Play Services unavailable or
                // out of date, or nothing to suggest — resolved as "nothing
                // picked" rather than an error, since none of that is
                // something the member did wrong or the app needs to
                // surface.
                finishPending(null)
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PHONE_NUMBER_HINT_REQUEST_CODE) {
            val number = try {
                Identity.getSignInClient(this).getPhoneNumberFromIntent(data)
            } catch (e: Exception) {
                // The member dismissed the sheet without picking anything,
                // or the result couldn't be parsed — either way, nothing to
                // fill in.
                null
            }
            finishPending(number)
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun finishPending(number: String?) {
        pendingResult?.success(number)
        pendingResult = null
    }
}
