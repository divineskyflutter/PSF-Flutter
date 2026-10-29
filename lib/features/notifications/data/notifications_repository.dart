import 'package:flutter/foundation.dart';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/auth/no_auth_token_provider.dart';
import 'package:psf_application/core/network/dio_client.dart';
import 'package:psf_application/core/network/network_caller.dart';

import 'models/notification_item_model.dart';
import 'models/notification_list_request.dart';

/// The notification list API: the member's push notifications, one page at a
/// time, and marking one as read. The app's network layer adds the Bearer
/// token to both calls.
class NotificationsRepository {
  NotificationsRepository({NetworkCaller? caller})
      : _network = caller ?? NetworkCaller(DioClient.create(const NoAuthTokenProvider()));

  final NetworkCaller _network;

  /// One page for [request]. Throws when the call fails, so the screen can
  /// show its retry state.
  Future<NotificationPage> fetchPage(NotificationListRequest request) async {
    final response = await _network.postRequest(
      ApiEndPoints.getAllPushNotification,
      body: request.toJson(),
      // The screen shows its own error state; no toast or blocking dialog.
      suppressErrorToast: true,
      suppressNetworkDialog: true,
    );

    if (!response.status) {
      throw Exception(response.message.isEmpty ? 'Could not load notifications' : response.message);
    }

    final raw = response.data;
    final items = <NotificationItem>[
      if (raw is List)
        for (final entry in raw)
          if (entry is Map) NotificationItem.fromJson(Map<String, dynamic>.from(entry)),
    ];

    return NotificationPage(
      items: items,
      totalCount: items.isEmpty ? null : items.first.totalCount,
    );
  }

  /// Tells the server the member read notification [id]. Meant to be fired
  /// without waiting; it never throws and never shows anything.
  Future<void> markRead(int id) async {
    try {
      final response = await _network.postRequest(
        ApiEndPoints.readPushNotification,
        body: {'id': id},
        suppressErrorToast: true,
        suppressNetworkDialog: true,
      );
      if (!response.status) {
        debugPrint('Notifications: marking $id as read was refused (${response.message})');
      }
    } catch (e) {
      debugPrint('Notifications: marking $id as read failed ($e)');
    }
  }
}
