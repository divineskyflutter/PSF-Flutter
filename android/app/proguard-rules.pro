# Flutter and most plugins ship their own consumer rules; these cover the few
# things R8 cannot see on its own.

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# image_cropper -> bundled uCrop (+ the OkHttp it uses to fetch remote images).
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Services Phone Number Hint (login screen) — called from Kotlin.
-keep class com.google.android.gms.auth.api.identity.** { *; }

# Flutter references Play Core's split-install classes, which this app does
# not use (no deferred components).
-dontwarn com.google.android.play.core.**
