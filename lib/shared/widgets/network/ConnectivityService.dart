import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../core/network/network_request_manager.dart';
import '../dialogs/app_dialog.dart';
import '../loaders/app_loader_controller.dart';

/// App-wide connectivity watchdog.
///
/// Owns the single "No Internet Connection" dialog shown anywhere in the
/// app: it is triggered either by the ambient [InternetConnection] stream
/// below, or directly by [NetworkCaller]/[ErrorInterceptor] when a request
/// itself hits a connection error. Both paths funnel through
/// [handleNetworkFailure] so there is only ever one dialog on screen.
///
/// Three production-hardening changes on top of the original version, all
/// aimed at the same family of bug reports (dialog stuck on screen after
/// reconnecting, dialog popping up during camera/gallery/crop or a phone
/// call, retries failing right after a reconnect):
///
/// 1. DEBOUNCE — a single "disconnected" signal (ambient stream OR a failed
///    API call) no longer shows the dialog / cancels every other in-flight
///    request instantly. It waits [_disconnectDebounceDuration] for that
///    state to actually persist first. A momentary blip (radio handoff
///    when opening the camera, a call connecting/ending, one flaky
///    request) resolves itself inside that window and nothing happens; a
///    real outage is still caught within ~1.2s.
/// 2. APP-LIFECYCLE AWARENESS — connectivity flips while the app isn't the
///    foreground surface (camera/gallery/crop are their own native
///    Activity/UIViewController, same as an incoming-call overlay) are
///    ignored outright, and the moment the app comes back to the
///    foreground a single fresh, real check runs instead of trusting
///    whatever was last observed while backgrounded. This is what stopped
///    the dialog from silently queuing itself behind the camera and then
///    appearing the instant the member returned to the app.
/// 3. SELF-HEALING ON SUCCESS — [markInternetVerified] lets NetworkCaller
///    tell this service "a request just round-tripped successfully" after
///    *every* successful API call. Previously the ONLY way [hasInternet]
///    could flip back to true was the ambient checker's own probe (an
///    unrelated third-party endpoint) agreeing — so if that probe was ever
///    slow, blocked, or just disagreed with reality, [hasInternet] stayed
///    stuck at false and NetworkCaller's own upfront `hasInternet` guard
///    (see network_caller.dart) then rejected every subsequent retry
///    before it even reached the network, which is exactly the "API call
///    just doesn't work any more" symptom reported. Now any real, proven
///    success clears the flag immediately, the same way a banking/social
///    app treats "the request I actually care about just worked" as
///    better evidence than a generic connectivity probe.
class ConnectivityService extends GetxService with WidgetsBindingObserver {
  /// A dedicated checker instance (instead of the bare default singleton)
  /// so the polling cadence can be tuned for this app: a shorter
  /// [checkInterval] means the ambient state resyncs faster after a missed
  /// event, on top of the stream reacting immediately to OS connectivity
  /// changes.
  final InternetConnection _checker = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 3),
  );

  StreamSubscription<InternetStatus>? _subscription;

  bool _isDialogShowing = false;

  /// Exposed (not private) so the no-internet dialog can show a live
  /// "Checking connection..." indicator the instant Retry is tapped,
  /// instead of the button looking unresponsive while the real check runs.
  final RxBool isCheckingConnection = false.obs;

  final RxBool _hasInternet = true.obs;

  int _interruptionVersion = 0;

  // See class doc (1) — a disconnected signal only takes effect once it
  // survives this long. Long enough to swallow the camera/call-style
  // blips reported, short enough that a real outage still shows the
  // dialog almost immediately.
  Timer? _disconnectDebounce;
  static const _disconnectDebounceDuration = Duration(milliseconds: 1200);

  // See class doc (2).
  bool _appInForeground = true;

  /// Fires once whenever connectivity transitions from lost -> restored.
  /// Passive, auto-loading data (banners, enum options) listens here to
  /// re-fetch itself — user-triggered flows (Save/Continue) deliberately do
  /// NOT listen here; those only ever resume when the user taps the button
  /// again, so a background reconnect never fires an API call that saves
  /// or submits anything.
  final _reconnectedController = StreamController<void>.broadcast();

  Stream<void> get onReconnected => _reconnectedController.stream;

  bool get hasInternet => _hasInternet.value;

  /// A flow can retain this value before awaiting work and verify it before
  /// starting its next API call or navigation.
  int get interruptionVersion => _interruptionVersion;

  bool canContinueFlow(int version) =>
      _hasInternet.value && version == _interruptionVersion;

  AppLoaderController get _loader =>
      Get.find<AppLoaderController>();

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);

    _subscription = _checker.onStatusChange.listen(
      _handleInternetStatus,
    );

    _checkInitialConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInForeground = _appInForeground;
    _appInForeground = state == AppLifecycleState.resumed;

    // Coming back from the camera/gallery/crop UI, a phone call overlay,
    // or just the app switcher — drop anything the background period
    // queued up and do one real, immediate check instead of trusting a
    // stale or transient reading taken while we weren't in the foreground.
    if (!wasInForeground && _appInForeground) {
      _disconnectDebounce?.cancel();
      _checkInitialConnection();
    }
  }

  Future<void> _checkInitialConnection() async {
    final status = await _checker.internetStatus;

    _handleInternetStatus(status);
  }

  void _handleInternetStatus(InternetStatus status) {
    final connected = status == InternetStatus.connected;

    if (connected) {
      _restoreConnection();
      return;
    }

    _scheduleDisconnect();
  }

  /// Used by the Dio interceptor when a request itself detects a network
  /// failure before the connectivity stream has emitted its update.
  void handleNetworkFailure() => _scheduleDisconnect();

  /// Called by NetworkCaller after ANY API call completes successfully —
  /// see class doc (3). Cheap no-op when already marked as having
  /// internet.
  void markInternetVerified() {
    if (!_hasInternet.value) {
      _restoreConnection();
    }
  }

  void _restoreConnection() {
    _disconnectDebounce?.cancel();

    final wasDisconnected = !_hasInternet.value;

    _hasInternet.value = true;
    _closeDialog();

    if (wasDisconnected) {
      _reconnectedController.add(null);
    }
  }

  void _scheduleDisconnect() {
    // Ignore connectivity noise while backgrounded —
    // didChangeAppLifecycleState forces one real check the moment the app
    // is foregrounded again, so nothing is permanently missed.
    if (!_appInForeground) return;

    // Already counting down to the same conclusion — let it run rather
    // than restarting the clock on every extra signal.
    if (_disconnectDebounce?.isActive ?? false) return;

    _disconnectDebounce = Timer(_disconnectDebounceDuration, () {
      _handleInternetDisconnected();
    });
  }

  void _handleInternetDisconnected() {
    if (_hasInternet.value) {
      _hasInternet.value = false;
      _interruptionVersion++;
    }

    // Cancel and hide on every signal. New requests are blocked while the
    // dialog is visible, so a second API cannot remain loading in the
    // background.
    NetworkRequestManager.instance
        .cancelAllRequests();
    _loader.hide();
    _showNoInternetDialog();
  }

  void _showNoInternetDialog() {
    if (_isDialogShowing) return;

    // The initial connectivity check can finish before GetMaterialApp creates
    // its overlay. Delay the dialog until an overlay exists instead of losing
    // the first no-internet notification.
    if (Get.overlayContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInternet.value) _showNoInternetDialog();
      });
      return;
    }

    _isDialogShowing = true;

    // Uses the app's shared dialog design (same look as every other
    // AppDialog in the app) instead of a plain, unstyled AlertDialog.
    AppDialog.noInternet(
      onRetry: () async {
        await checkConnection();
      },
      customContent: Obx(
        () => isCheckingConnection.value
            ? const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Checking connection...',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  Future<void> checkConnection() async {
    if (isCheckingConnection.value) return;

    // A manual Retry always wins over a pending debounce — the member
    // explicitly asked "check right now", so don't make them wait out a
    // timer that exists only to filter passive/ambient noise.
    _disconnectDebounce?.cancel();

    isCheckingConnection.value = true;
    try {
      // A manual retry must never hang indefinitely — if the real probe
      // takes too long, treat it as "still disconnected" (the dialog just
      // stays up, which is harmless) instead of leaving the Retry tap
      // looking like it did nothing.
      final status = await _checker.internetStatus.timeout(
        const Duration(seconds: 5),
        onTimeout: () => InternetStatus.disconnected,
      );
      _handleInternetStatus(status);
    } finally {
      isCheckingConnection.value = false;
    }
  }

  void _closeDialog() {
    if (!_isDialogShowing) return;

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    _isDialogShowing = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectDebounce?.cancel();
    _subscription?.cancel();
    _checker.dispose();
    _reconnectedController.close();

    super.onClose();
  }
}
