import 'notification_filter.dart';

/// Body of `POST /api/Notification/GetAllPushNotification`.
///
/// Paging is by [skipRecords] (how many to skip) and [takeRecords] (how many
/// to return): the first call is skip 0, the next skip 25, then 50, ... with
/// take always 25. The API takes both as text, so they go out as strings.
class NotificationListRequest {
  const NotificationListRequest({
    required this.memberId,
    required this.filter,
    this.skipRecords = 0,
    this.takeRecords = pageSize,
    this.isExport = false,
    this.search = '',
  });

  /// Notifications per call.
  static const int pageSize = 25;

  final int memberId;
  final NotificationFilter filter;
  final int skipRecords;
  final int takeRecords;
  final bool isExport;

  /// Search is not offered in the app yet: always empty.
  final String search;

  Map<String, dynamic> toJson() => {
        'skipRecords': '$skipRecords',
        'takeRecords': '$takeRecords',
        'isExport': isExport,
        'search': search,
        'isRead': filter.apiValue,
        'memberId': memberId,
      };
}
