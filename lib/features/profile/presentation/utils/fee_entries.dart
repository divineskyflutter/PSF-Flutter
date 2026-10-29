import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_entries_screen.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_record.dart';

import '../controllers/profile_controller.dart';

/// The member's fee payments (passbook entries that are payments), as ledger
/// rows. Reading the list here also makes any `Obx` around the caller watch it.
List<PassbookRecord> feeEntryRecords(ProfileController controller) {
  controller.passbook.length;

  final payments = controller.passbook
      .where((e) => e.paidAmount > 0)
      .toList(growable: false);

  return [
    for (var i = 0; i < payments.length; i++)
      PassbookRecord(
        no: i + 1,
        date: payments[i].date,
        amount: payments[i].paidAmount,
        type: payments[i].details,
      ),
  ];
}

/// What the fee-entries book screen is opened with — used by Profile's
/// "View all" and by the `/passbook-entries` route when it is opened without
/// arguments (from a notification).
PassbookEntriesArgs feeEntriesArgs() {
  final controller = Get.find<ProfileController>();
  return PassbookEntriesArgs(
    title: AppStrings.profileFeeEntriesTitle.tr,
    source: ListPassbookPageSource(feeEntryRecords(controller)),
    onDownload: (_) => ToastUtil.info(AppStrings.receiptNotAvailable.tr),
  );
}
