import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/notifications/notification_constants.dart';
import 'package:psf_application/core/notifications/notification_events.dart';
import 'package:psf_application/core/notifications/notification_navigator.dart';
import 'package:psf_application/core/notifications/notification_routes.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';

import '../../data/models/notification_filter.dart';
import '../../data/models/notification_item_model.dart';
import '../../data/models/notification_list_request.dart';
import '../../data/notifications_repository.dart';

/// State of the Notifications screen (opened from the bell on Home, or by a
/// push whose route is `/notifications`).
///
/// * Every open starts a fresh load with the first filter; changing the filter
///   loads again (both show the shimmer).
/// * Paging: the first call skips 0, the next 25, then 50 ... and always takes
///   25. More is loaded when the list is scrolled near its end.
/// * Tapping a notification marks it read (in the background — nothing waits
///   for it and nothing is shown) and goes to the screen it names, or Home.
class NotificationsController extends GetxController {
  NotificationsController({NotificationsRepository? repository})
      : _repository = repository ?? NotificationsRepository();

  final NotificationsRepository _repository;

  final RxList<NotificationItem> items = <NotificationItem>[].obs;
  final Rx<NotificationFilter> filter = NotificationFilterConfig.initial.obs;

  /// First page / filter change: the screen shows its shimmer.
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool loadMoreFailed = false.obs;
  final RxBool hasError = false.obs;
  final RxBool hasMore = false.obs;

  final ScrollController scroll = ScrollController();

  int _nextSkip = 0;

  /// Bumped for every fresh load, so a slow answer to an old filter can never
  /// overwrite the list of the current one.
  int _generation = 0;
  int? _memberId;

  Timer? _arrivalTimer;

  @override
  void onInit() {
    super.onInit();
    scroll.addListener(_onScroll);
    NotificationEvents.received.addListener(_onPushArrived);
    load();
  }

  @override
  void onClose() {
    NotificationEvents.received.removeListener(_onPushArrived);
    _arrivalTimer?.cancel();
    scroll.dispose();
    super.onClose();
  }

  /// A push arrived while this screen is open: reload quietly (no shimmer, the
  /// list stays until the new one is in). The short wait lets the server file
  /// the notification first; several pushes in a row reload once.
  void _onPushArrived() {
    _arrivalTimer?.cancel();
    _arrivalTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!isLoading.value && !isLoadingMore.value) load(silent: true);
    });
  }

  void _onScroll() {
    if (!scroll.hasClients) return;
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 320) loadMore();
  }

  /// The shown list for the current filter, from the first page.
  /// [silent]: pull-to-refresh — no shimmer, the old list stays until the new
  /// one arrives.
  Future<void> load({bool silent = false}) async {
    final generation = ++_generation;
    if (!silent) isLoading.value = true;
    hasError.value = false;
    loadMoreFailed.value = false;
    isLoadingMore.value = false;

    try {
      final memberId = await _member();
      final page = await _repository.fetchPage(
        NotificationListRequest(memberId: memberId, filter: filter.value, skipRecords: 0),
      );
      if (generation != _generation) return;

      items.assignAll(page.items);
      _nextSkip = NotificationListRequest.pageSize;
      hasMore.value = _moreAfter(page);
    } catch (_) {
      if (generation != _generation) return;
      // A failed pull-to-refresh keeps what is on screen.
      if (!silent || items.isEmpty) {
        items.clear();
        hasMore.value = false;
        hasError.value = true;
      }
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  Future<void> refresh() => load(silent: true);

  void retry() => load();

  /// The next 25.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value || hasError.value) return;

    final generation = _generation;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;

    try {
      final memberId = await _member();
      final page = await _repository.fetchPage(
        NotificationListRequest(
          memberId: memberId,
          filter: filter.value,
          skipRecords: _nextSkip,
        ),
      );
      if (generation != _generation) return;

      items.addAll(page.items);
      _nextSkip += NotificationListRequest.pageSize;
      hasMore.value = _moreAfter(page);
    } catch (_) {
      if (generation != _generation) return;
      loadMoreFailed.value = true;
    } finally {
      if (generation == _generation) isLoadingMore.value = false;
    }
  }

  void changeFilter(NotificationFilter next) {
    if (next == filter.value) return;
    filter.value = next;
    items.clear();
    hasMore.value = false;
    load();
  }

  /// A tapped notification: read in the background, then go where it says.
  void onTap(NotificationItem item) {
    if (!item.isRead) {
      final index = items.indexWhere((e) => e.id == item.id);
      if (index >= 0) items[index] = item.copyWith(isRead: true);
      unawaited(_repository.markRead(item.id)); // not awaited, silent
    }

    var route = item.screen?.trim();
    if (route == null || route.isEmpty || NotificationRoutes.resolve(route) == null) {
      route = AppRoutes.home;
    }
    NotificationNavigator.instance.handleTap({NotificationConstants.routeKey: route});
  }

  // --------------------------------------------------------------------------

  Future<int> _member() async {
    final id = _memberId ??= await AppSecureStorage.getMemberId();
    if (id == null || id <= 0) throw Exception('No signed-in member');
    return id;
  }

  /// Is there another page after [page]? A short page is the last one; the
  /// total count (when the API gives it) settles the rest.
  bool _moreAfter(NotificationPage page) {
    if (page.items.length < NotificationListRequest.pageSize) return false;
    final total = page.totalCount;
    if (total == null || total <= 0) return true;
    return items.length < total;
  }
}
