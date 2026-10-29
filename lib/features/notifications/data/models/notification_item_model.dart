/// One push notification in the member's list (an entry of the `data` array of
/// `GetAllPushNotification`).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.screen,
    this.sendDateTime,
    this.readDateTime,
    this.totalCount,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;

  /// Where a tap goes (a `NotificationRoutes` value such as `/profile`);
  /// `null` / blank means Home.
  final String? screen;

  /// When it was sent (server time, which is the same local time as the
  /// phone's) and when the member read it.
  final DateTime? sendDateTime;
  final DateTime? readDateTime;

  /// How many notifications match the filter in all (repeated on every row).
  final int? totalCount;

  NotificationItem copyWith({bool? isRead, DateTime? readDateTime}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      screen: screen,
      sendDateTime: sendDateTime,
      readDateTime: readDateTime ?? this.readDateTime,
      totalCount: totalCount,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _toInt(_get(json, 'pushNotificationId')) ?? 0,
      title: _text(_get(json, 'title')) ?? '',
      message: _text(_get(json, 'message')) ?? '',
      isRead: _toBool(_get(json, 'isRead')),
      screen: _text(_get(json, 'screen')),
      sendDateTime: _toDate(_get(json, 'sendDateTime')),
      readDateTime: _toDate(_get(json, 'readDateTime')),
      totalCount: _toInt(_get(json, 'totalcount')),
    );
  }

  // Case-insensitive lookup, like the other models of this API.
  static dynamic _get(Map<String, dynamic> json, String key) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime? _toDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

/// One loaded page of notifications.
class NotificationPage {
  const NotificationPage({required this.items, this.totalCount});

  final List<NotificationItem> items;

  /// Total matching the filter, when the API said.
  final int? totalCount;
}
