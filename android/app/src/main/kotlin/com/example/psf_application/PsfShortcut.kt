package com.example.psf_application

import android.content.Context
import android.content.Intent
import androidx.core.app.Person
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/// Registers one "conversation" shortcut for PSF, with the app's round colour
/// logo as its picture.
///
/// Why: a notification the app draws is marked as part of this shortcut
/// (`shortcutId` in lib/core/notifications/notification_display.dart). Android
/// 11+ then shows such a notification as a conversation — the shortcut's
/// picture (our logo) large and in full colour at the LEFT, even when the
/// notification is collapsed — instead of only the one-colour small icon.
///
/// It is published every time the app starts, so it exists before any
/// notification is drawn (including ones drawn while the app is killed).
object PsfShortcut {
    /// Must match NotificationConstants.shortcutId on the Dart side.
    const val ID = "psf_notifications"

    fun publish(context: Context) {
        try {
            val logo = IconCompat.createWithResource(context, R.drawable.notification_logo)

            val person = Person.Builder()
                .setName("PSF")
                .setKey(ID)
                .setIcon(logo)
                .setImportant(true)
                .build()

            val launch = Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW)

            val shortcut = ShortcutInfoCompat.Builder(context, ID)
                .setShortLabel("PSF")
                .setLongLived(true)
                .setIntent(launch)
                .setPerson(person)
                .setIcon(logo)
                .setLocusId(LocusIdCompat(ID))
                .build()

            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        } catch (_: Throwable) {
            // A missing shortcut only costs the left-hand logo; never break start-up.
        }
    }
}
