/// Fixed names used by the notification code and the Android project.
///
/// [channelId] MUST match the `default_notification_channel_id` meta-data in
/// AndroidManifest.xml — that is how a notification Android draws by itself
/// (app in the background or killed) ends up on our channel, and therefore
/// plays our sound, without the backend ever sending a channel id.
class NotificationConstants {
  NotificationConstants._();

  /// Android notification channel. The sound of a channel can't be changed
  /// after it exists on a phone, so if the sound file is ever replaced, bump
  /// the suffix (here AND in AndroidManifest.xml).
  static const channelId = 'psf_notifications_v1';
  static const channelName = 'PSF notifications';
  static const channelDescription =
      'Updates and alerts from Parivar Suraksha Foundation';

  /// android/app/src/main/res/raw/psf_notification.mp3 (no extension here).
  static const soundResource = 'psf_notification';

  /// The PSF logo as a white silhouette, shown at the LEFT of every
  /// notification (and in the status bar): android/app/src/main/res/
  /// drawable-{mdpi..xxxhdpi}/ic_stat_notification.png. Android only allows a
  /// one-colour shape for this icon, so it is tinted PSF teal.
  static const smallIcon = 'ic_stat_notification';

  /// The full-colour app logo (round), android/app/src/main/res/drawable-nodpi/
  /// notification_logo.png — shown at the left of notifications the app draws
  /// itself, as the "sender" picture of a messaging-style notification.
  static const logoAvatar = 'notification_logo';

  /// The conversation shortcut (published natively by PsfShortcut.kt, same id)
  /// that gives app-drawn notifications the logo at the left, even collapsed.
  static const shortcutId = 'psf_notifications';

  /// Keys the backend puts in the notification's `data` map.
  /// `route` says which screen a tap opens (see NotificationRoutes);
  /// `screen` is accepted as an alias. Title and body normally travel in the
  /// FCM `notification` block, but `title` / `body` in `data` are used when a
  /// message carries only data.
  static const routeKey = 'route';
  static const routeKeyAlias = 'screen';
  static const titleKey = 'title';
  static const bodyKey = 'body';

  /// Every key name the backend may use for each value. Matching ignores case,
  /// so `Title`, `TITLE` and `title` are the same key.
  static const _routeNames = [routeKey, routeKeyAlias, 'screenname'];
  static const _titleNames = [titleKey];
  static const _bodyNames = [bodyKey, 'message'];

  static String? routeFrom(Map<String, dynamic> data) => _read(data, _routeNames);
  static String? titleFrom(Map<String, dynamic> data) => _read(data, _titleNames);
  static String? bodyFrom(Map<String, dynamic> data) => _read(data, _bodyNames);

  static String? _read(Map<String, dynamic> data, List<String> names) {
    for (final name in names) {
      for (final entry in data.entries) {
        if (entry.key.toLowerCase() != name) continue;
        final text = entry.value?.toString();
        if (text != null && text.trim().isNotEmpty) return text;
      }
    }
    return null;
  }
}
