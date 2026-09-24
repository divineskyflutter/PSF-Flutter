import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/navigation/drawer_back_scope.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/staggered_reveal.dart';

import '../../data/about_us_info.dart';
import '../widgets/profile_card_style.dart';

/// About Us — who the Foundation is: an animated header with the emblem,
/// headline numbers that count up, the story, mission and vision, what the
/// Foundation does, its values, its journey, its leaders, the registration
/// details and a "Contact us" call-to-action. Everything is translated
/// (English / Hindi / Gujarati) and the figures come from [AboutUsInfo] —
/// dummy content for now, meant to be replaced. Sections come in one after
/// another.
///
/// Reached from the drawer, so back (arrow or system gesture) reopens the
/// drawer instead of landing on the tab underneath — see [DrawerBackScope].
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerBackScope(
      builder: (context, onBack) => _AboutUsView(onBack: onBack),
    );
  }
}

class _AboutUsView extends StatelessWidget {
  const _AboutUsView({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    var index = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      // The header stays fixed and the page scrolls under its wavy edge.
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(title: AppStrings.aboutUs.tr, onBack: onBack),
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
            StaggeredReveal(index: index++, child: const _Hero()),
            SizedBox(height: 16.px(context)),
            StaggeredReveal(index: index++, child: const _StatsGrid()),
            SizedBox(height: 20.px(context)),
            StaggeredReveal(
              index: index++,
              child: _TextCard(
                icon: Icons.favorite_rounded,
                title: 'about_who_we_are_title'.tr,
                body: 'about_who_we_are_text'.tr,
              ),
            ),
            SizedBox(height: 12.px(context)),
            StaggeredReveal(
              index: index++,
              child: _TextCard(
                icon: Icons.flag_rounded,
                title: AppStrings.ourMission.tr,
                body: AppStrings.ourMissionText.tr,
              ),
            ),
            SizedBox(height: 12.px(context)),
            StaggeredReveal(
              index: index++,
              child: _TextCard(
                icon: Icons.visibility_rounded,
                title: AppStrings.ourVision.tr,
                body: AppStrings.ourVisionText.tr,
              ),
            ),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle('about_what_we_do_title'.tr)),
            SizedBox(height: 10.px(context)),
            StaggeredReveal(index: index++, child: const _ProgramsGrid()),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle(AppStrings.ourValues.tr)),
            SizedBox(height: 10.px(context)),
            StaggeredReveal(index: index++, child: const _ValuesWrap()),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle('about_journey_title'.tr)),
            SizedBox(height: 10.px(context)),
            StaggeredReveal(index: index++, child: const _Journey()),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: _SectionTitle('about_leaders_title'.tr)),
            SizedBox(height: 10.px(context)),
            StaggeredReveal(index: index++, child: const _Leaders()),
            SizedBox(height: 22.px(context)),
            StaggeredReveal(index: index++, child: const _RegistrationCard()),
            SizedBox(height: 16.px(context)),
            StaggeredReveal(index: index++, child: const _ContactCta()),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  // The emblem drifts up and down very slightly, forever.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px(context), vertical: 24.px(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF2E9A8E)],
        ),
        borderRadius: BorderRadius.circular(26.px(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_float.value);
              return Transform.translate(offset: Offset(0, -6 * t), child: child);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .6, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 104.px(context),
                height: 104.px(context),
                padding: EdgeInsets.all(12.px(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGold, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(.35),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
              ),
            ),
          ),
          SizedBox(height: 16.px(context)),
          Text(
            'card_title'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.px(context),
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          SizedBox(height: 6.px(context)),
          Text(
            'about_hero_tagline'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontSize: 13.5.px(context),
              height: 1.4,
            ),
          ),
          SizedBox(height: 14.px(context)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.px(context), vertical: 6.px(context)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(20.px(context)),
              border: Border.all(color: AppColors.accentGold.withOpacity(.8)),
            ),
            child: Text(
              'about_since'.tr,
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: 12.5.px(context),
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATS
// ============================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final gap = 10.px(context);

    Widget tile(AboutStat stat) => Expanded(child: _StatTile(stat: stat));

    return Column(
      children: [
        Row(children: [tile(AboutUsInfo.stats[0]), SizedBox(width: gap), tile(AboutUsInfo.stats[1])]),
        SizedBox(height: gap),
        Row(children: [tile(AboutUsInfo.stats[2]), SizedBox(width: gap), tile(AboutUsInfo.stats[3])]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final AboutStat stat;

  /// 12500 -> `12,500`.
  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: profileCardDecoration(context),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12.px(context)),
            ),
            child: Icon(stat.icon, size: 20.px(context), color: AppColors.primary),
          ),
          SizedBox(width: 10.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Counts up from 0 when the tile appears.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stat.value.toDouble()),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_grouped(value.round())}+',
                      style: TextStyle(
                        fontSize: 18.px(context),
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.px(context)),
                Text(
                  stat.labelKey.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.px(context),
                    height: 1.25,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

// ============================================================
// STORY / MISSION / VISION
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

class _TextCard extends StatelessWidget {
  const _TextCard({required this.icon, required this.title, required this.body});

  final IconData icon;

  final String title;

  final String body;

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
                padding: EdgeInsets.all(8.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12.px(context)),
                ),
                child: Icon(icon, size: 20.px(context), color: AppColors.primary),
              ),
              SizedBox(width: 12.px(context)),
              Expanded(
                child: Text(
                  title,
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
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5.px(context),
              height: 1.55,
              color: AppColors.textPrimary.withOpacity(.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROGRAMS
// ============================================================

class _ProgramsGrid extends StatelessWidget {
  const _ProgramsGrid();

  @override
  Widget build(BuildContext context) {
    final gap = 10.px(context);
    final programs = AboutUsInfo.programs;

    Widget tile(int i) => Expanded(child: _ProgramTile(program: programs[i]));

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(0), SizedBox(width: gap), tile(1)],
          ),
        ),
        SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(2), SizedBox(width: gap), tile(3)],
          ),
        ),
      ],
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program});

  final AboutProgram program;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.px(context),
            height: 42.px(context),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
            ),
            child: Icon(program.icon, size: 22.px(context), color: Colors.white),
          ),
          SizedBox(height: 10.px(context)),
          Text(
            program.titleKey.tr,
            style: TextStyle(
              fontSize: 14.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.px(context)),
          Text(
            program.textKey.tr,
            style: TextStyle(
              fontSize: 12.px(context),
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VALUES
// ============================================================

class _ValuesWrap extends StatelessWidget {
  const _ValuesWrap();

  @override
  Widget build(BuildContext context) {
    final values = <(IconData, String)>[
      (Icons.volunteer_activism_rounded, AppStrings.valueCompassion.tr),
      (Icons.verified_rounded, AppStrings.valueIntegrity.tr),
      (Icons.visibility_rounded, AppStrings.valueTransparency.tr),
      (Icons.balance_rounded, AppStrings.valueEquality.tr),
      (Icons.handshake_rounded, AppStrings.valueServiceToHumanity.tr),
    ];

    return Wrap(
      spacing: 10.px(context),
      runSpacing: 10.px(context),
      children: [
        for (final value in values)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.px(context), vertical: 10.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(24.px(context)),
              border: Border.all(color: AppColors.primary.withOpacity(.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(value.$1, size: 18.px(context), color: AppColors.primary),
                SizedBox(width: 8.px(context)),
                Text(
                  value.$2,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// JOURNEY
// ============================================================

class _Journey extends StatelessWidget {
  const _Journey();

  @override
  Widget build(BuildContext context) {
    final milestones = AboutUsInfo.milestones;

    return Container(
      padding: EdgeInsets.fromLTRB(16.px(context), 16.px(context), 16.px(context), 4.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        children: [
          for (var i = 0; i < milestones.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22.px(context),
                    child: Column(
                      children: [
                        Container(
                          width: 14.px(context),
                          height: 14.px(context),
                          margin: EdgeInsets.only(top: 3.px(context)),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: AppColors.accentGold.withOpacity(.5), blurRadius: 6),
                            ],
                          ),
                        ),
                        if (i != milestones.length - 1)
                          Expanded(
                            child: Container(
                              width: 2.px(context),
                              color: AppColors.primary.withOpacity(.25),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.px(context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.px(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestones[i].year,
                            style: TextStyle(
                              fontSize: 12.px(context),
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: .5,
                            ),
                          ),
                          SizedBox(height: 2.px(context)),
                          Text(
                            milestones[i].titleKey.tr,
                            style: TextStyle(
                              fontSize: 14.5.px(context),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3.px(context)),
                          Text(
                            milestones[i].textKey.tr,
                            style: TextStyle(
                              fontSize: 12.5.px(context),
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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

// ============================================================
// LEADERS
// ============================================================

class _Leaders extends StatelessWidget {
  const _Leaders();

  @override
  Widget build(BuildContext context) {
    final gap = 10.px(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < AboutUsInfo.leaders.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: _LeaderCard(leader: AboutUsInfo.leaders[i])),
        ],
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.leader});

  final AboutLeader leader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        children: [
          Container(
            width: 64.px(context),
            height: 64.px(context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              border: Border.all(color: AppColors.accentGold, width: 2),
            ),
            child: Icon(Icons.person_rounded, size: 34.px(context), color: Colors.white),
          ),
          SizedBox(height: 10.px(context)),
          Text(
            leader.nameKey.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 3.px(context)),
          Text(
            leader.roleKey.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5.px(context),
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REGISTRATION + CTA
// ============================================================

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard();

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => Padding(
          padding: EdgeInsets.symmetric(vertical: 6.px(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12.5.px(context), color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 5,
                // Long registration numbers shrink to fit on one line.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.px(context),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 20.px(context), color: AppColors.primary),
              SizedBox(width: 10.px(context)),
              Text(
                'about_reg_title'.tr,
                style: TextStyle(
                  fontSize: 15.px(context),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.px(context)),
          const Divider(height: 1, color: AppColors.border),
          row('about_reg_cin'.tr, AboutUsInfo.registrationNumber),
          row('about_reg_licence'.tr, AboutUsInfo.licenceNumber),
        ],
      ),
    );
  }
}

class _ContactCta extends StatelessWidget {
  const _ContactCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(22.px(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'about_cta_title'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.px(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.px(context)),
                Text(
                  'about_cta_text'.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 12.5.px(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.px(context)),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.px(context)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.px(context)),
              onTap: () => Get.toNamed(AppRoutes.contactUs),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.px(context), vertical: 11.px(context)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18.px(context), color: AppColors.primaryDark),
                    SizedBox(width: 6.px(context)),
                    Text(
                      AppStrings.contactUs.tr,
                      style: TextStyle(
                        fontSize: 13.px(context),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
