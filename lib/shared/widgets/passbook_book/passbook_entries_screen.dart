import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';

import 'passbook_book_view.dart';
import 'passbook_record.dart';

/// What [PassbookEntriesScreen] is opened with (`Get.toNamed(
/// AppRoutes.passbookEntries, arguments: PassbookEntriesArgs(...))`).
class PassbookEntriesArgs {
  const PassbookEntriesArgs({
    required this.title,
    required this.source,
    this.onDownload,
    this.onDownloadAll,
  });

  /// The name of the data shown, for the app bar ("Fee entries", "Loan
  /// account", ...).
  final String title;

  final PassbookPageSource source;

  /// Receipt download of one entry.
  final PassbookRecordAction? onDownload;

  /// The download button in the app bar (the whole ledger).
  final VoidCallback? onDownloadAll;
}

/// Full-screen ledger book: an app bar with the name of the data and a
/// download button, then a [PassbookBookView] taking the rest of the screen.
/// Any ledger can use it — only the arguments differ.
class PassbookEntriesScreen extends StatelessWidget {
  const PassbookEntriesScreen({super.key, required this.args});

  final PassbookEntriesArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(
        title: args.title,
        onBack: () => Get.back(),
        actions: [
          AppHeaderIconButton(
            icon: Icons.download_rounded,
            onTap: args.onDownloadAll ??
                () => ToastUtil.info(AppStrings.receiptNotAvailable.tr),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12.px(context),
            AppSubPageHeader.totalHeight() + 10.px(context),
            12.px(context),
            10.px(context),
          ),
          child: PassbookBookView(
            source: args.source,
            onDownload: args.onDownload,
          ),
        ),
      ),
    );
  }
}
