import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/profile/domain/entities/passbook_entry_entity.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
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
// HERO — photo, name, member number, status, mobile and scheme
// ===========================================================================

/// The top card of Profile: a teal gradient panel with the member's photo in
/// a white ring (tap to zoom) and the headline facts as chips. Every missing
/// value reads "-".
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.memberNo,
    required this.status,
    required this.mobile,
    required this.schemeName,
  });

  final String? photoUrl;
  final String name;
  final String? memberNo;
  final String? status;
  final String? mobile;
  final String? schemeName;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl?.isNotEmpty ?? false;
    final radius = BorderRadius.circular(26.px(context));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Soft decorative circles.
            Positioned(
              right: -34.px(context),
              top: -34.px(context),
              child: _Bubble(size: 130.px(context), opacity: .08),
            ),
            Positioned(
              left: -26.px(context),
              bottom: -40.px(context),
              child: _Bubble(size: 110.px(context), opacity: .06),
            ),
            Padding(
              padding: EdgeInsets.all(18.px(context)),
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
                    child: Container(
                      padding: EdgeInsets.all(3.px(context)),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: FramedImage(
                        url: photoUrl,
                        size: 86.px(context),
                        circle: true,
                        fallbackIcon: Icons.person_rounded,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.px(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.px(context),
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.px(context)),
                        Wrap(
                          spacing: 8.px(context),
                          runSpacing: 6.px(context),
                          children: [
                            _Chip(
                              icon: Icons.badge_outlined,
                              text: _orDash(memberNo),
                            ),
                            _Chip(
                              icon: Icons.verified_rounded,
                              text: _orDash(status),
                              highlighted: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 10.px(context)),
                        _HeroLine(icon: Icons.phone_rounded, text: _orDash(mobile)),
                        SizedBox(height: 4.px(context)),
                        _HeroLine(
                          icon: Icons.account_balance_wallet_rounded,
                          text: _orDash(schemeName),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.highlighted = false});

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.px(context), vertical: 5.px(context)),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white : Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.px(context),
            color: highlighted ? AppColors.primaryDark : Colors.white,
          ),
          SizedBox(width: 5.px(context)),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.px(context),
                fontWeight: FontWeight.w700,
                color: highlighted ? AppColors.primaryDark : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.px(context), color: Colors.white70),
        SizedBox(width: 6.px(context)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5.px(context),
              color: Colors.white.withOpacity(.92),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// FEE — total / paid / pending with a progress bar
// ===========================================================================

/// The member's membership fee: three colour-coded amount tiles (total, paid,
/// pending) and a progress bar with the percentage paid. Fed by
/// [ProfileController.scheme] (from the last login); with no amount yet every
/// figure reads "-" and the bar stays empty.
class ProfileFeeCard extends StatelessWidget {
  const ProfileFeeCard({super.key, required this.scheme});

  final MembershipSchemeInfo scheme;

  @override
  Widget build(BuildContext context) {
    final hasAmount = scheme.totalAmount > 0;
    final fraction = !hasAmount
        ? 0.0
        : (scheme.paidAmount / scheme.totalAmount).clamp(0.0, 1.0);
    final percent = (fraction * 100);
    final percentText = percent == percent.roundToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);

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
            trailing: scheme.isFullyPaid && hasAmount
                ? _StatusPill(
                    text: AppStrings.feeFullyPaid.tr,
                    color: AppColors.success,
                  )
                : null,
          ),
          SizedBox(height: 12.px(context)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 10.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(12.px(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    AppStrings.profileApplicableFee.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.px(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 8.px(context)),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasAmount ? _rupees(scheme.totalAmount) : '-',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14.px(context),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.px(context)),
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
                  color: scheme.isFullyPaid && hasAmount
                      ? AppColors.success
                      : AppColors.primaryDark,
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
                scheme.isFullyPaid && hasAmount ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          if (hasAmount) ...[
            SizedBox(height: 6.px(context)),
            Text(
              '${_rupees(scheme.paidAmount)} / ${_rupees(scheme.totalAmount)}',
              style: TextStyle(
                fontSize: 12.px(context),
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
// PAYMENT HISTORY — a table (empty state until a payments source exists)
// ===========================================================================

/// "Payment history" table: No. / Date / Amount / Type. It lists the member's
/// passbook entries that are payments ([ProfileController.passbook]); while
/// there are none it shows a single "-" row and a "No payments yet" note, so
/// the layout is ready for when the data arrives.
class ProfilePaymentTable extends StatelessWidget {
  const ProfilePaymentTable({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.passbook
          .where((e) => e.paidAmount > 0)
          .toList(growable: false);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.px(context)),
        decoration: profileCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.receipt_long_rounded,
              title: AppStrings.profilePaymentHistory.tr,
            ),
            SizedBox(height: 12.px(context)),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.px(context)),
              child: Column(
                children: [
                  const _TableRow(
                    cells: [
                      'col_no',
                      'col_date',
                      'col_amount',
                      'col_type',
                    ],
                    header: true,
                  ),
                  if (payments.isEmpty)
                    const _TableRow(cells: ['-', '-', '-', '-'])
                  else
                    for (var i = 0; i < payments.length; i++)
                      _TableRow(
                        cells: _cells(i, payments[i]),
                        shaded: i.isOdd,
                      ),
                ],
              ),
            ),
            if (payments.isEmpty) ...[
              SizedBox(height: 10.px(context)),
              Center(
                child: Text(
                  AppStrings.profileNoPayments.tr,
                  style: TextStyle(
                    fontSize: 12.5.px(context),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  List<String> _cells(int index, PassbookEntryEntity e) => [
        '${index + 1}',
        e.date != null ? AppDateFormat.medium(e.date!) : '-',
        _rupees(e.paidAmount),
        _orDash(e.details),
      ];
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, this.header = false, this.shaded = false});

  /// Header cells are string KEYS (translated here); body cells are text.
  final List<String> cells;
  final bool header;
  final bool shaded;

  static const _flex = [2, 4, 4, 4];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header
          ? AppColors.primary.withOpacity(.14)
          : (shaded ? AppColors.primary.withOpacity(.04) : Colors.transparent),
      padding: EdgeInsets.symmetric(horizontal: 8.px(context), vertical: 10.px(context)),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Text(
                header ? cells[i].tr : cells[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: i == 0 ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: header ? 12.px(context) : 12.5.px(context),
                  fontWeight: header ? FontWeight.w800 : FontWeight.w600,
                  color: header ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FORM DETAILS — tap an option to open it
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
// FEE INFO — a short green note under the fee / payments
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
// SANGYOG NITI — the support fund; no amount in the login response yet
// ===========================================================================

/// The Sangyog Niti (support fund) card. The login response carries no fund
/// amount yet, so the value reads "-" until the backend sends one — pass it as
/// [amount] then.
class ProfileSangyogNitiCard extends StatelessWidget {
  const ProfileSangyogNitiCard({super.key, this.amount});

  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _CardTitle(
              icon: Icons.savings_rounded,
              title: AppStrings.sangyogNitiLabel.tr,
            ),
          ),
          SizedBox(width: 8.px(context)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount != null && amount! > 0 ? _rupeesShort(amount!) : '-',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16.px(context),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SUPPORTING ACCOUNT — the references, "Required" / "Not required"
// ===========================================================================

/// The Supporting Account (references) status, read from the login response
/// (`isReferenceNeeded`, `referenceCount`, `refrencemembers`):
///  * not needed (or nothing in the response) → "Not required";
///  * needed → "Required", how many are added of how many, and each added
///    person (name, mobile, member no.) — or a "-" row while none are added.
class ProfileSupportingAccountCard extends StatelessWidget {
  const ProfileSupportingAccountCard({super.key, required this.controller});

  final ProfileController controller;

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
