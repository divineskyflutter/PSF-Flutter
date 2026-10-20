import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/widgets/dialogs/app_dialog.dart';

import '../controllers/profile_controller.dart';

/// Invisible helper dropped into a tab's body: while that tab ([tabIndex]) is
/// the one showing, it opens an info dialog (not a toast) once if the member's reference list doesn't
/// match their required reference count (see
/// [ProfileController.referenceMismatchMessage]). Shown once per tab for each
/// distinct count pair, not on every visit.
class ReferenceMismatchNotifier extends StatefulWidget {
  const ReferenceMismatchNotifier({super.key, required this.tabIndex});

  final int tabIndex;

  @override
  State<ReferenceMismatchNotifier> createState() => _ReferenceMismatchNotifierState();
}

class _ReferenceMismatchNotifierState extends State<ReferenceMismatchNotifier> {
  static final Set<String> _alreadyShown = {};

  final _profile = Get.find<ProfileController>();
  final _nav = Get.find<MainNavigationController>();

  final List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _workers.add(ever(_profile.references, (_) => _check()));
    _workers.add(ever(_nav.currentIndex, (_) => _check()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _nav.currentIndex.value != widget.tabIndex) return;

    final message = _profile.referenceMismatchMessage;
    if (message == null) return;

    final key = '${widget.tabIndex}|$message';
    if (!_alreadyShown.add(key)) return;

    // After the current frame so the dialog never opens mid-build.
    scheduleMicrotask(() => AppDialog.show(
          title: AppStrings.referencesIncompleteTitle.tr,
          message: message,
          type: AppDialogType.error,
          primaryButtonText: AppStrings.okButton.tr,
        ));
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
