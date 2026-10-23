import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_entries_screen.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_record.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import '../../data/models/scheme_reference_model.dart';
import '../controllers/profile_controller.dart';
import '../pages/profile_form_details_page.dart';
import 'profile_card_style.dart';

String _orDash(String? value) =>
    (value != null && value.trim().isNotEmpty) ? value.trim() : '-';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// Whole rupees without decimals, paise only when there are some.
String _rupees(double value) {
  if (value == value.roundToDouble()) return _money.format(value);
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(value);
}

/// Same as [_rupees], but a crore or more becomes e.g. "₹1.2Cr" so a very
/// large amount stays readable inside a narrow tile.
String _rupeesShort(double value) {
  if (value.abs() < 10000000) return _rupees(value);
  return NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
      .format(value);
}

// ===========================================================================
// HERO — photo and the member's headline facts
// ===========================================================================

/// The top card of Profile: the member's photo (tap to zoom) beside a short
/// list — member number, name, member-since date, age and status. A value the
/// backend has not sent reads "-".
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.photoUrl,
    required this.memberNo,
    required this.name,
    required this.joinedOn,
    required this.age,
    required this.status,
  });

  final String? photoUrl;
  final String? memberNo;
  final String name;
  final DateTime? joinedOn;
  final int? age;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl?.isNotEmpty ?? false;

    final rows = [
      (Icons.badge_outlined, AppStrings.memberNoLabel.tr, _orDash(memberNo)),
      (Icons.person_outline_rounded, AppStrings.profileMemberName.tr, _orDash(name)),
      (
        Icons.event_available_rounded,
        AppStrings.profileJoinedOn.tr,
        joinedOn != null ? AppDateFormat.medium(joinedOn!) : '-',
      ),
      (
        Icons.cake_outlined,
        AppStrings.profileAge.tr,
        age != null ? AppStrings.profileAgeYears.trParams({'age': '$age'}) : '-',
      ),
      (Icons.verified_rounded, AppStrings.memberStatus.tr, _orDash(status)),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.px(context)),
      decoration: profileCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasPhoto
                ? () => CommonImagePreview.show(
                      context: context,
                      images: [PreviewImageItem(imagePath: photoUrl!)],
                      mode: ImagePreviewMode.dialog,
                    )
                : null,
            child: FramedImage(
              url: photoUrl,
              size: 78.px(context),
              circle: true,
              fallbackIcon: Icons.person_rounded,
            ),
          ),
          SizedBox(width: 10.px(context)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.06),
                borderRadius: BorderRadius.circular(14.px(context)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 9.px(context)),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _HeroRow(
                      icon: rows[i].$1,
                      label: rows[i].$2,
                      value: rows[i].$3,
                      divider: i != rows.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.divider,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.5.px(context)),
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: AppColors.primary.withOpacity(.14)))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.px(context),
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            ':  ',
            style: TextStyle(fontSize: 12.px(context), color: AppColors.textSecondary),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5.px(context),
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FEE — total / paid / pending, progress and the last date
// ===========================================================================

/// The member's membership fee: three colour-coded amount tiles (total, paid,
/// pending), the percentage paid with a progress bar, "paid / total", and the
/// last date to complete the fee ([lastDate] — the joining date plus 365
/// days). Fed by [ProfileController.scheme] (from the last login); with no
/// amount yet every figure reads "-" and the bar stays empty.
class ProfileFeeCard extends StatelessWidget {
  const ProfileFeeCard({super.key, required this.scheme, required this.lastDate});

  final MembershipSchemeInfo scheme;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final hasAmount = scheme.totalAmount > 0;
    final fraction = !hasAmount
        ? 0.0
        : (scheme.paidAmount / scheme.totalAmount).clamp(0.0, 1.0);
    final percent = fraction * 100;
    final percentText = percent == percent.roundToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
    final complete = scheme.isFullyPaid && hasAmount;

    String money(double v) => hasAmount ? _rupeesShort(v) : '-';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.account_balance_wallet_rounded,
            title: AppStrings.membershipFeeTitle.tr,
            trailing: complete
                ? _StatusPill(text: AppStrings.feeFullyPaid.tr, color: AppColors.success)
                : null,
          ),
          SizedBox(height: 14.px(context)),
          // IntrinsicHeight: "stretch" needs a bounded height, and this sits
          // inside a scrolling column — the tiles all take the tallest one.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _AmountTile(
                    label: AppStrings.feeTotal.tr,
                    value: money(scheme.totalAmount),
                    color: AppColors.info,
                    icon: Icons.payments_rounded,
                  ),
                ),
                SizedBox(width: 8.px(context)),
                Expanded(
                  child: _AmountTile(
                    label: AppStrings.feePaid.tr,
                    value: money(scheme.paidAmount),
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                SizedBox(width: 8.px(context)),
                Expanded(
                  child: _AmountTile(
                    label: AppStrings.feePending.tr,
                    value: money(scheme.pendingAmount),
                    color: AppColors.danger,
                    icon: Icons.error_rounded,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.px(context)),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.profilePaymentProgress.tr,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                hasAmount
                    ? AppStrings.profilePercentPaid.trParams({'percent': percentText})
                    : '-',
                style: TextStyle(
                  fontSize: 13.px(context),
                  fontWeight: FontWeight.w800,
                  color: complete ? AppColors.success : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.px(context)),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.px(context)),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10.px(context),
              backgroundColor: AppColors.primary.withOpacity(.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                complete ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 10.px(context)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasAmount
                          ? '${_rupeesShort(scheme.paidAmount)} / ${_rupeesShort(scheme.totalAmount)}'
                          : '-',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14.px(context),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.px(context)),
              Icon(Icons.event_rounded, size: 22.px(context), color: AppColors.primaryDark),
              SizedBox(width: 6.px(context)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.profileLastDate.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.px(context),
                        height: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      lastDate != null ? AppDateFormat.medium(lastDate!) : '-',
                      style: TextStyle(
                        fontSize: 12.5.px(context),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.px(context), vertical: 12.px(context)),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14.px(context)),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.px(context), color: color),
          SizedBox(height: 6.px(context)),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.px(context),
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.px(context)),
          // Shrinks instead of overflowing on a narrow screen or a big amount.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16.px(context),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PAYMENT ENTRIES — a collapsible section with the latest three
// ===========================================================================

/// "Payment history": a section that opens and closes (like Documents). Open,
/// it lists the latest three entries as a passbook table with a receipt
/// download on each; "View all" opens every entry as a book
/// ([PassbookEntriesScreen]). Entries come from [ProfileController.passbook]
/// (payments only); until there are any it shows an empty row.
class ProfilePaymentSection extends StatefulWidget {
  const ProfilePaymentSection({super.key, required this.controller});

  final ProfileController controller;

  @override
  State<ProfilePaymentSection> createState() => _ProfilePaymentSectionState();
}

class _ProfilePaymentSectionState extends State<ProfilePaymentSection> {
  bool _open = false;

  static const _flex = [2, 4, 4, 5, 4, 3];

  List<PassbookRecord> _records() {
    // Read first, so the surrounding Obx always has something to watch.
    widget.controller.passbook.length;

    // Test aid: `--dart-define=PSF_FAKE_LEDGER=true` fills the ledger with 23
    // sample entries, to try the multi-page book (flip, tear, page numbers).
    if (const bool.fromEnvironment('PSF_FAKE_LEDGER')) {
      return [
        for (var i = 0; i < 23; i++)
          PassbookRecord(
            no: i + 1,
            date: DateTime(2026, 10, 1).add(Duration(days: i * 7)),
            amount: 500.0 + i * 100,
            type: i.isEven ? 'Online' : 'Installment',
            status: 'Paid',
          ),
      ];
    }
    final payments = widget.controller.passbook
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

  void _download(PassbookRecord record) =>
      ToastUtil.info(AppStrings.receiptNotAvailable.tr);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = _records();
      final shown = records.take(3).toList();

      return Container(
        width: double.infinity,
        decoration: profileCardDecoration(context),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18.px(context)),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: EdgeInsets.all(16.px(context)),
                child: Row(
                  children: [
                    Expanded(
                      child: _CardTitle(
                        icon: Icons.receipt_long_rounded,
                        title: AppStrings.profilePaymentHistory.tr,
                      ),
                    ),
                    SizedBox(width: 6.px(context)),
                    InkWell(
                      borderRadius: BorderRadius.circular(20.px(context)),
                      onTap: () => Get.toNamed(
                        AppRoutes.passbookEntries,
                        arguments: PassbookEntriesArgs(
                          title: AppStrings.profileFeeEntriesTitle.tr,
                          source: ListPassbookPageSource(records),
                          onDownload: _download,
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.px(context),
                          vertical: 5.px(context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20.px(context)),
                        ),
                        child: Text(
                          AppStrings.viewAll.tr,
                          style: TextStyle(
                            fontSize: 12.px(context),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.px(context)),
                    AnimatedRotation(
                      turns: _open ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryDark,
                        size: 26.px(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        16.px(context),
                        0,
                        16.px(context),
                        16.px(context),
                      ),
                      child: _table(context, shown),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    });
  }

  Widget _table(BuildContext context, List<PassbookRecord> rows) {
    final headings = [
      AppStrings.colNo.tr,
      AppStrings.colDate.tr,
      AppStrings.colAmount.tr,
      AppStrings.colPaymentType.tr,
      AppStrings.colStatus.tr,
    ];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.px(context)),
          child: Column(
            children: [
              _tableRow(context, headings, header: true),
              if (rows.isEmpty)
                _tableRow(context, const ['-', '-', '-', '-', '-'])
              else
                for (var i = 0; i < rows.length; i++)
                  _tableRow(
                    context,
                    [
                      '${rows[i].no}',
                      rows[i].date != null ? AppDateFormat.medium(rows[i].date!) : '-',
                      rows[i].amount != null ? _rupees(rows[i].amount!) : '-',
                      _orDash(rows[i].type),
                      _orDash(rows[i].status),
                    ],
                    shaded: i.isOdd,
                    onDownload: () => _download(rows[i]),
                  ),
            ],
          ),
        ),
        if (rows.isEmpty) ...[
          SizedBox(height: 10.px(context)),
          Text(
            AppStrings.profileNoPayments.tr,
            style: TextStyle(
              fontSize: 12.5.px(context),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _tableRow(
    BuildContext context,
    List<String> cells, {
    bool header = false,
    bool shaded = false,
    VoidCallback? onDownload,
  }) {
    return Container(
      color: header
          ? AppColors.primary.withOpacity(.14)
          : (shaded ? AppColors.primary.withOpacity(.04) : Colors.transparent),
      padding: EdgeInsets.symmetric(horizontal: 4.px(context), vertical: header ? 10.px(context) : 6.px(context)),
      constraints: BoxConstraints(minHeight: header ? 0 : 40.px(context)),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.px(context)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    cells[i],
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: header ? 11.5.px(context) : 12.px(context),
                      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
                      color: header ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: _flex[5],
            child: header
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.px(context)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.colReceipt.tr,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5.px(context),
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  )
                : (onDownload == null
                    ? const SizedBox.shrink()
                    : Center(
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onDownload,
                          child: Padding(
                            padding: EdgeInsets.all(5.px(context)),
                            child: Icon(
                              Icons.download_rounded,
                              size: 19.px(context),
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FEE INFO — a short green note
// ===========================================================================

class ProfileFeeInfoBar extends StatelessWidget {
  const ProfileFeeInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.px(context)),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(.10),
        borderRadius: BorderRadius.circular(16.px(context)),
        border: Border.all(color: AppColors.success.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: AppColors.success, size: 20.px(context)),
          SizedBox(width: 10.px(context)),
          Expanded(
            child: Text(
              AppStrings.profileFeeInfo.tr,
              style: TextStyle(
                fontSize: 12.5.px(context),
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SANGYOG NITI — the support-fund card, only when the member has it
// ===========================================================================

/// The Sangyog Niti (support fund) card: shown only while the login response
/// flags it for the member ([MembershipSchemeInfo.sangyogNiti]); otherwise it
/// takes no space. The amount is [MembershipSchemeInfo.sangyogNitiAmount].
class ProfileSangyogNitiCard extends StatelessWidget {
  const ProfileSangyogNitiCard({super.key, required this.scheme});

  final MembershipSchemeInfo scheme;

  @override
  Widget build(BuildContext context) {
    if (!scheme.sangyogNiti) return const SizedBox.shrink();

    final amount = _rupees(MembershipSchemeInfo.sangyogNitiAmount);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.px(context)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.px(context)),
        decoration: BoxDecoration(
          color: AppColors.accentGold.withOpacity(.16),
          borderRadius: BorderRadius.circular(18.px(context)),
          border: Border.all(color: AppColors.accentGold.withOpacity(.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38.px(context),
                  height: 38.px(context),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.savings_rounded,
                      color: AppColors.primaryDark, size: 21.px(context)),
                ),
                SizedBox(width: 10.px(context)),
                Expanded(
                  child: Text(
                    AppStrings.sangyogCardTitle.trParams({'amount': amount}),
                    style: TextStyle(
                      fontSize: 15.px(context),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.px(context)),
            Text(
              AppStrings.sangyogCardDesc.trParams({'amount': amount}),
              style: TextStyle(
                fontSize: 12.5.px(context),
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10.px(context)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 10.px(context)),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(.12),
                borderRadius: BorderRadius.circular(12.px(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sangyogInitialDeposit.tr,
                          style: TextStyle(
                            fontSize: 12.px(context),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount,
                            style: TextStyle(
                              fontSize: 20.px(context),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.px(context)),
                  _StatusPill(
                    text: AppStrings.sangyogDepositDone.tr,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.px(context)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18.px(context), color: AppColors.warning),
                SizedBox(width: 8.px(context)),
                Expanded(
                  child: Text(
                    AppStrings.sangyogNote.tr,
                    style: TextStyle(
                      fontSize: 12.px(context),
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUPPORTING ACCOUNT — age / rule and the references, Required / Not required
// ===========================================================================

/// The Supporting Account (references) status, read from the login response
/// (`isReferenceNeeded`, `referenceCount`, `refrencemembers`), under the
/// member's age and the age rule:
///  * not needed (or nothing in the response) → "Not required";
///  * needed → "Required", how many are added of how many, and each added
///    person (name, mobile, member no.) — or a "-" row while none are added.
class ProfileSupportingAccountCard extends StatelessWidget {
  const ProfileSupportingAccountCard({
    super.key,
    required this.controller,
    required this.age,
  });

  final ProfileController controller;
  final int? age;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final info = controller.references.value;
      final required = info?.isReferenceNeeded == true;
      final language = Get.find<LanguageController>().currentAppLanguage;
      final color = required ? AppColors.warning : AppColors.success;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.px(context)),
        decoration: profileCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.groups_rounded,
              title: AppStrings.supportingAccountTitle.tr,
              trailing: _StatusPill(
                text: required
                    ? AppStrings.supportingRequired.tr
                    : AppStrings.supportingNotRequired.tr,
                color: color,
              ),
            ),
            SizedBox(height: 12.px(context)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 10.px(context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.07),
                borderRadius: BorderRadius.circular(12.px(context)),
              ),
              child: Text(
                AppStrings.supportingAgeRule.trParams({'age': age != null ? '$age' : '-'}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.px(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (required) ...[
              SizedBox(height: 12.px(context)),
              Text(
                info!.referenceCount != null
                    ? AppStrings.supportingAddedCount.trParams({
                        'added': '${info.members.length}',
                        'required': '${info.referenceCount}',
                      })
                    : '${info.members.length}',
                style: TextStyle(
                  fontSize: 13.px(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.px(context)),
              if (info.members.isEmpty)
                Text(
                  '-  ${AppStrings.referencesNoneYet.tr}',
                  style: TextStyle(
                    fontSize: 12.5.px(context),
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final m in info.members)
                  _PersonLine(
                    name: localizedField(
                      language,
                      plain: m.name,
                      hindi: m.hindiName,
                      gujarati: m.gujaratiName,
                    ),
                    mobile: m.mobile,
                    memberNo: m.memberNo,
                  ),
            ],
          ],
        ),
      );
    });
  }
}

class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.name, this.mobile, this.memberNo});

  final String name;
  final String? mobile;
  final String? memberNo;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (mobile != null && mobile!.isNotEmpty) mobile!,
      if (memberNo != null && memberNo!.isNotEmpty)
        '${AppStrings.memberNoLabel.tr}: $memberNo',
    ].join('  ·  ');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 6.px(context)),
      padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 10.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(12.px(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _orDash(name),
            style: TextStyle(
              fontSize: 13.5.px(context),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (details.isNotEmpty)
            Text(
              details,
              style: TextStyle(
                fontSize: 12.px(context),
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FORM DETAILS — one tile
// ===========================================================================

/// One "Form details" tile. It opens [ProfileFormDetailsPage], where the
/// submitted form is split into Personal / Nominee / Health Declaration tabs
/// that can be tapped or swiped.
class ProfileFormDetailsOptions extends StatelessWidget {
  const ProfileFormDetailsOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.px(context));

    return Container(
      width: double.infinity,
      decoration: profileCardDecoration(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => Get.to(() => const ProfileFormDetailsPage()),
          child: Padding(
            padding: EdgeInsets.all(16.px(context)),
            child: Row(
              children: [
                Container(
                  width: 42.px(context),
                  height: 42.px(context),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(13.px(context)),
                  ),
                  child: Icon(Icons.assignment_rounded,
                      color: Colors.white, size: 22.px(context)),
                ),
                SizedBox(width: 14.px(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.profileFormDetailsTitle.tr,
                        style: TextStyle(
                          fontSize: 15.px(context),
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 2.px(context)),
                      Text(
                        AppStrings.profileFormDetailsHint.tr,
                        style: TextStyle(
                          fontSize: 12.5.px(context),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.primaryDark, size: 26.px(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// IMPORTANT NOTES — at the end of the page
// ===========================================================================

class ProfileImportantNotes extends StatelessWidget {
  const ProfileImportantNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = [
      AppStrings.profileNote1.tr,
      AppStrings.profileNote2.tr,
      AppStrings.profileNote3.tr,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.px(context)),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(.22),
        borderRadius: BorderRadius.circular(18.px(context)),
        border: Border.all(color: AppColors.accentGold.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded,
                  color: AppColors.warning, size: 24.px(context)),
              SizedBox(width: 8.px(context)),
              Expanded(
                child: Text(
                  AppStrings.profileImportantTitle.tr,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.px(context)),
          for (final note in notes)
            Padding(
              padding: EdgeInsets.only(bottom: 6.px(context)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.px(context), right: 8.px(context)),
                    child: Container(
                      width: 6.px(context),
                      height: 6.px(context),
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12.5.px(context),
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// shared bits
// ===========================================================================

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.px(context),
          height: 34.px(context),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(11.px(context)),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19.px(context)),
        ),
        SizedBox(width: 10.px(context)),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.px(context), vertical: 4.px(context)),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5.px(context),
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
