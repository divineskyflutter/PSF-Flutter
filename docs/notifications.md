# Push notifications

How the PSF app receives and shows push notifications, what the backend must
send, and what is left to set up on the Firebase side.

Code: `lib/core/notifications/`

| File | Job |
|---|---|
| `notification_service.dart` | start-up, listeners for every app state, permission request, background handler |
| `notification_display.dart` | draws a notification with our channel, chime and icon (one per message) |
| `notification_navigator.dart` | opens the screen named in the payload when a notification is tapped |
| `notification_routes.dart` | the list of screens a notification may open |
| `fcm_token_service.dart` | the phone's FCM token: upload after login, refresh, cleanup on logout |
| `notification_constants.dart` | channel id, sound, icon, payload key names |

Android pieces: `res/raw/psf_notification.mp3` (the sound your friend sent), `res/drawable/ic_stat_notification.xml`
(status-bar icon), `res/values/notification_colors.xml`, and three
`com.google.firebase.messaging.default_notification_*` entries in
`AndroidManifest.xml`.

## One notification per message

| App state | message has a `notification` block | data-only message |
|---|---|---|
| open | drawn by the app (`onMessage`) | drawn by the app (`onMessage`) |
| in the background | drawn by Android itself | drawn by the background handler |
| killed | drawn by Android itself | drawn by the background handler |

When Android draws it, the background handler skips the message, so there is
never a second copy. Each drawn notification also gets a stable id from the FCM
message id, so the same message can't be drawn twice.

## What the backend sends

Title and body go in the normal FCM `notification` block. The screen goes in
`data.route`. **No channel id is needed** — the app creates the channel and
Android uses it as the default.

```json
{
  "message": {
    "token": "<the phone's device token>",
    "notification": {
      "title": "Membership approved",
      "body": "Your PSF membership is now active."
    },
    "data": {
      "route": "/profile"
    },
    "android": {
      "priority": "HIGH"
    }
  }
}
```

* `data.route` is optional. Without it, tapping just opens the app.
* `data.screen` is accepted as another name for `route`.
* A message with **no** `notification` block (data only) may carry `data.title`
  and `data.body`; the app then draws the notification itself.
* All `data` values must be strings (FCM rule).

## Recommended: send data-only messages (shows the colour logo)

A message with a `notification` block is drawn by **Android itself** when the app
is in the background or killed: it can only show the white one-colour small icon
and the app name. A message with **no `notification` block** is drawn by the app
in every state, so it gets the full-colour logo at the left, the PSF sound and the
same look everywhere. Put the text in `data`:

```json
{
  "message": {
    "token": "<the phone's device token>",
    "data": {
      "title": "Membership approved",
      "body": "Your PSF membership is now active.",
      "route": "/profile"
    },
    "android": { "priority": "HIGH" }
  }
}
```

Keep `"priority": "HIGH"` so a sleeping or killed phone gets it promptly. The
catch: some phone makers (Xiaomi, Oppo, Vivo...) don't deliver data-only messages
to a killed app unless the user allows autostart / removes battery limits.

## Screens a notification can open (`data.route`)

| `route` value | Opens |
|---|---|
| `/home` | Home tab |
| `/profile` | Profile tab |
| `/card` | Member card tab |
| `/passbook` | Passbook tab |
| `/notifications` | Notifications screen (the bell on Home) |
| `/profile/about-us` | About Us page |
| `/profile/contact-us` | Contact Us page |
| `/profile/terms-and-conditions` | Terms & Conditions page |
| `/profile/privacy-policy` | Privacy Policy page |

* Tabs switch the bottom bar; pages open **on top** of the current screen, so
  Back works normally.
* An unknown value is ignored — the app just opens. It never crashes.
* If the app was closed, or the member isn't logged in yet, the tap is kept and
  opened as soon as the member reaches Home (kept for 30 minutes).

To open another screen, add it in `notification_routes.dart` (and here).

## Icons and the logo

* **The logo is the notification's left-hand icon**, and the same icon shows in
  the status bar: `drawable-{mdpi..xxxhdpi}/ic_stat_notification.png`, a white
  silhouette of the PSF emblem (tree, hands, ribbon), tinted PSF teal. Android
  only allows a one-colour shape in that slot, so the full-colour logo can't be
  used there; the silhouette keeps the emblem recognisable.
* It appears for **every** notification in every state, whether the app draws it
  or Android does (the manifest names the same icon as the default).
* There is no large image on the right.

## Permissions (AndroidManifest.xml)

| Permission | Why | Declared by |
|---|---|---|
| `POST_NOTIFICATIONS` | show notifications on Android 13+ (asked once at Home) | us |
| `VIBRATE` | channel vibration | us |
| `INTERNET`, `ACCESS_NETWORK_STATE` | API calls, connectivity | us |
| `WAKE_LOCK` | let Firebase handle a push while the phone sleeps | Firebase (auto) |
| `com.google.android.c2dm.permission.RECEIVE` | receive push from Google | Firebase (auto) |

Nothing else is needed. Not used: `RECEIVE_BOOT_COMPLETED` / exact alarms
(no scheduled notifications), full-screen intents.

## Sound

The sound is `android/app/src/main/res/raw/psf_notification.mp3` (the audio the team's friend sent, about 2.7 seconds). It plays in
every state because it is the sound of the notification **channel**
(`psf_notifications_v1`), which both the app and Android use.

* To change it, replace the file (keep the name `psf_notification`; only one file with that name may exist, whatever its extension) **and** change the channel id suffix (here:
  `NotificationConstants.channelId` and `AndroidManifest.xml`). Android never
  changes a channel's sound after the channel exists on a phone.
* The channel is created the first time the app opens after install, so the
  very first push on a freshly installed phone that was never opened uses
  Android's default sound.

## Device token API

`POST /api/Member/UpdateDevicetoken` with `{ "memberId": 4, "deviceToken": "..." }`
and the Bearer access token. The app calls it:

* right after a successful login, inside the login loader (never fails login);
* when FCM refreshes the token, and at app start for a logged-in member if the
  token changed;
* on logout, delete account and expired session the phone's token is deleted
  locally, so it stops getting the previous member's pushes.

## Firebase setup (done)

* Firebase project: **PSF APP** (`psf-app-69a8f`). Two Android apps are
  registered in it:
  * dev: `com.example.psf_application` - app id `1:474080138936:android:8c0e1c7cfb682d390c064d`
  * prod: `com.divinesky.psf` - app id `1:474080138936:android:2142dfc18c6dcb800c064d`
* `android/app/google-services.json` holds the config for both (re-download it
  from Project settings -> Your apps if an app is added). The Google Services
  plugin is applied only when that file exists, so removing it just turns push
  off.
* Firebase Cloud Messaging API (V1) is enabled for the project.
* Fingerprints (SHA-1/SHA-256) are not needed for push notifications.

## Testing

* Real push on demand: build with `--dart-define=PSF_NOTIF_PUSH_TEST=true`; ~7
  seconds after start the token is re-sent and the backend replies with a push.
  (Press Home right after launch to see it arrive with the app in the background.)
* Sample notification without Firebase: build with
  `--dart-define=PSF_NOTIF_TEST=true`; ~10 seconds after start a test notification
  (chime + icon, tap opens About Us) appears.
* In code: `NotificationService.instance.showTestNotification(route: '/profile')`.
* Channel settings on the phone:
  `adb shell dumpsys notification | findstr psf_notifications_v1`
* Real push: send the payload above to the device token with the Firebase
  console's "Send test message" or the backend.
* Check all three states: app open, app in the background (Home button), app
  killed (swipe away from recents) — one notification each, chime each time,
  tap opens the named screen.

## Known limits

* Some phone makers (Xiaomi, Oppo, Vivo, Realme...) stop apps in the background
  and block pushes to killed apps unless the user allows "autostart" /
  "no battery restrictions" — nothing the app can force.
* Android 13+ asks for the notification permission once, when the member first
  reaches Home. If they refuse, notifications stay off until they allow them in
  system settings.
* iOS is not set up.
