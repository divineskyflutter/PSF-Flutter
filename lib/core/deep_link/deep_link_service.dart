import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DeepLinkService extends GetxService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<DeepLinkService> init() async {
    _appLinks = AppLinks();
    _handleIncomingLinks();
    return this;
  }

  void _handleIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      // Extract path or query params and navigate accordingly
      // Example: 
      // if (uri.path.contains('/loan/apply')) { Get.toNamed('/apply_loan'); }
    }, onError: (err) {
      debugPrint('Failed to handle incoming deep link: $err');
    });
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
