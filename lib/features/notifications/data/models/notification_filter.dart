import 'package:psf_application/app/constants/app_strings.dart';

/// Which notifications the list shows.
enum NotificationFilter {
  all,
  unread,
  read;

  /// Label key in the language files.
  String get labelKey => switch (this) {
        NotificationFilter.all => AppStrings.notificationsFilterAll,
        NotificationFilter.unread => AppStrings.notificationsFilterUnread,
        NotificationFilter.read => AppStrings.notificationsFilterRead,
      };

  /// What the API's `isRead` field is sent as. See [NotificationFilterConfig].
  Object? get apiValue {
    if (NotificationFilterConfig.numericIsRead) {
      return switch (this) {
        NotificationFilter.all => 2,
        NotificationFilter.read => 1,
        NotificationFilter.unread => 0,
      };
    }
    return switch (this) {
      NotificationFilter.read => true,
      NotificationFilter.unread => false,
      // The boolean API cannot ask for "all"; it is not offered (see
      // [NotificationFilterConfig.available]).
      NotificationFilter.all => null,
    };
  }
}

/// The two switches that decide how the filter talks to the API — flip them
/// when the backend changes, nothing else needs to move.
class NotificationFilterConfig {
  NotificationFilterConfig._();

  /// `false` (today): `isRead` is `true` (read) / `false` (unread).
  /// `true` (later): `isRead` is `2` (all) / `1` (read) / `0` (unread).
  static const bool numericIsRead = false;

  /// Offer "All" in the dropdown. Needs [numericIsRead] (the boolean API has
  /// no "all").
  static const bool allEnabled = false;

  /// The filters the dropdown shows, in order.
  static List<NotificationFilter> get available => [
        if (allEnabled) NotificationFilter.all,
        NotificationFilter.unread,
        NotificationFilter.read,
      ];

  /// What the list opens with: "All" once it exists, otherwise "Unread".
  static NotificationFilter get initial => available.first;
}
