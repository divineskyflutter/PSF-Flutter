import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/navigation/drawer_back_scope.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/staggered_reveal.dart';

import '../../data/contact_us_info.dart';
import '../widgets/profile_card_style.dart';

/// Contact Us — how to reach the Foundation: a welcoming header with quick
/// Call / WhatsApp actions, the people to contact (each with Call and
/// WhatsApp), office hours with an open/closed badge, email, and both
/// office addresses that open in Maps. Names and addresses show in the
/// member's selected language; the details themselves live in
/// [ContactUsInfo]. Sections come in one after another.
///
/// Reachable straight from the drawer OR nested from About Us's CTA button.
/// Either way, back (arrow or system gesture) reopens the drawer only when
/// this page was the one reached directly from it — see [DrawerBackScope].
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerBackScope(
      builder: (context, onBack) => _ContactUsView(onBack: onBack),
    );
  }
}

class _ContactUsView extends StatelessWidget {
  const _ContactUsView({required this.onBack});

  final VoidCallback? onBack;

  Future<void> _launch(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) ToastUtil.error('could_not_open_app_error'.tr);
    } catch (_) {
      ToastUtil.error('could_not_open_app_error'.tr);
    }
  }

  Future<void> _call(String phone) => _launch(Uri(scheme: 'tel', path: phone));

  // "91" = India's country code; every number here is a local 10-digit
  // mobile number (same assumption the registration screen makes).
  Future<void> _whatsApp(String phone) => _launch(Uri.parse('https://wa.me/91$phone'));

  Future<void> _email() => _launch(Uri(scheme: 'mailto', path: ContactUsInfo.email));

  Future<void> _openMaps(String query) => _launch(
        Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query}),
      );

  @override
  Widget build(BuildContext context) {
    final office = ContactUsInfo.people.first;

    var index = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      // The header stays fixed and the page scrolls under its wavy edge.
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(title: AppStrings.contactUs.tr, onBack: onBack),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18.px(context),
          AppSubPageHeader.totalHeight() + 12.px(context),
          18.px(context),
          28.px(context) + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaggeredReveal(
              index: index++,
              child: _HeroCard(
                onCall: () => _call(office.phone),
                onWhatsApp: () => _whatsApp(office.phone),
              ),
            ),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle('contact_reach_us'.tr)),
            SizedBox(height: 10.px(context)),
            for (final person in ContactUsInfo.people) ...[
              StaggeredReveal(
                index: index++,
                child: _PersonCard(
                  person: person,
                  onCall: () => _call(person.phone),
                  onWhatsApp: () => _whatsApp(person.phone),
                ),
              ),
              SizedBox(height: 12.px(context)),
            ],
            SizedBox(height: 10.px(context)),
            StaggeredReveal(index: index++, child: const _HoursCard()),
            SizedBox(height: 12.px(context)),
            StaggeredReveal(index: index++, child: _EmailCard(onTap: _email)),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle('contact_visit_us'.tr)),
            SizedBox(height: 10.px(context)),
            for (final address in ContactUsInfo.addresses) ...[
              StaggeredReveal(
                index: index++,
                child: _AddressCard(
                  address: address,
                  onOpenMaps: () => _openMaps(address.mapsQuery),
                ),
              ),
              SizedBox(height: 12.px(context)),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.onCall, required this.onWhatsApp});

  final VoidCallback onCall;

  final VoidCallback onWhatsApp;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with SingleTickerProviderStateMixin {
  // A slow pulse ring behind the headset icon keeps the card feeling alive.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 62.px(context);

    return Container(
      padding: EdgeInsets.all(20.px(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF2E9A8E)],
        ),
        borderRadius: BorderRadius.circular(24.px(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: iconSize * 1.5,
                height: iconSize * 1.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final t = Curves.easeOut.transform(_pulse.value);
                        return Container(
                          width: iconSize * (1 + t * .5),
                          height: iconSize * (1 + t * .5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity((1 - t) * .5),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentGold.withOpacity(.9), width: 1.4),
                      ),
                      child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 32.px(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.px(context)),
              Expanded(
                child: Text(
                  'contact_hero_title'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21.px(context),
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.px(context)),
          Text(
            'contact_hero_subtitle'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontSize: 13.px(context),
              height: 1.45,
            ),
          ),
          SizedBox(height: 16.px(context)),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  icon: Icons.call_rounded,
                  label: 'contact_call_office'.tr,
                  filled: true,
                  onTap: widget.onCall,
                ),
              ),
              SizedBox(width: 10.px(context)),
              Expanded(
                child: _HeroButton(
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'whatsapp'.tr,
                  filled: false,
                  onTap: widget.onWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;

  final String label;

  final bool filled;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.primaryDark : Colors.white;

    return Material(
      color: filled ? Colors.white : Colors.white.withOpacity(.14),
      borderRadius: BorderRadius.circular(16.px(context)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.px(context)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.px(context), horizontal: 8.px(context)),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(16.px(context)),
                  border: Border.all(color: Colors.white.withOpacity(.45)),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.px(context), color: foreground),
              SizedBox(width: 8.px(context)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13.5.px(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PEOPLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.px(context),
          height: 18.px(context),
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 10.px(context)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.onCall, required this.onWhatsApp});

  final ContactPerson person;

  final VoidCallback onCall;

  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: profileCardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 50.px(context),
            height: 50.px(context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              border: Border.all(color: AppColors.accentGold, width: 1.6),
            ),
            child: Icon(person.icon, color: Colors.white, size: 26.px(context)),
          ),
          SizedBox(width: 14.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.nameKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.px(context)),
                Text(
                  person.roleKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.px(context),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.px(context)),
                Text(
                  '+91 ${AppValidators.formatMobile(person.phone)}',
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
          _RoundAction(icon: Icons.call_rounded, tooltip: 'call'.tr, onTap: onCall),
          SizedBox(width: 8.px(context)),
          _RoundAction(icon: FontAwesomeIcons.whatsapp, tooltip: 'whatsapp'.tr, onTap: onWhatsApp),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;

  final String tooltip;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primary.withOpacity(.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(10.px(context)),
            child: Icon(icon, size: 19.px(context), color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OFFICE HOURS
// ============================================================

class _HoursCard extends StatelessWidget {
  const _HoursCard();

  @override
  Widget build(BuildContext context) {
    final open = ContactUsInfo.isOpenAt(DateTime.now());
    final statusColor = open ? const Color(0xFF2E9A5B) : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.primary, size: 22.px(context)),
              SizedBox(width: 10.px(context)),
              Expanded(
                child: Text(
                  'support_office_hours_title'.tr,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.px(context), vertical: 4.px(context)),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20.px(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.px(context),
                      height: 7.px(context),
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 6.px(context)),
                    Text(
                      open ? 'contact_open_now'.tr : 'contact_closed_now'.tr,
                      style: TextStyle(
                        fontSize: 11.5.px(context),
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.px(context)),
          _HoursRow(icon: Icons.wb_sunny_outlined, text: 'support_office_hours_morning'.tr),
          SizedBox(height: 8.px(context)),
          _HoursRow(icon: Icons.nights_stay_outlined, text: 'support_office_hours_afternoon'.tr),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.icon, required this.text});

  final IconData icon;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.px(context), color: AppColors.accentGold),
        SizedBox(width: 10.px(context)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5.px(context),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMAIL + ADDRESSES
// ============================================================

class _EmailCard extends StatelessWidget {
  const _EmailCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: profileCardDecoration(context),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(11.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 22.px(context)),
          ),
          SizedBox(width: 14.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'contact_email_title'.tr,
                  style: TextStyle(fontSize: 12.px(context), color: AppColors.textSecondary),
                ),
                SizedBox(height: 2.px(context)),
                Text(
                  ContactUsInfo.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          _RoundAction(icon: Icons.send_rounded, tooltip: 'contact_send_email'.tr, onTap: onTap),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onOpenMaps});

  final ContactAddress address;

  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(9.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12.px(context)),
                ),
                child: Icon(address.icon, size: 20.px(context), color: AppColors.primary),
              ),
              SizedBox(width: 12.px(context)),
              Expanded(
                child: Text(
                  address.titleKey.tr,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.px(context)),
          Text(
            address.addressKey.tr,
            style: TextStyle(
              fontSize: 13.5.px(context),
              height: 1.5,
              color: AppColors.textPrimary.withOpacity(.85),
            ),
          ),
          SizedBox(height: 12.px(context)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenMaps,
              icon: Icon(Icons.map_outlined, size: 18.px(context)),
              label: Text('contact_open_in_maps'.tr),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(.08),
                padding: EdgeInsets.symmetric(horizontal: 14.px(context), vertical: 8.px(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.px(context))),
                textStyle: TextStyle(fontSize: 13.px(context), fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
