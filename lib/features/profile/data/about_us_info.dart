import 'package:flutter/material.dart';

/// One headline number on the About Us screen.
class AboutStat {
  const AboutStat({required this.value, required this.labelKey, required this.icon});

  final int value;

  final String labelKey;

  final IconData icon;
}

/// One thing the Foundation does. Both keys are translation keys.
class AboutProgram {
  const AboutProgram({required this.titleKey, required this.textKey, required this.icon});

  final String titleKey;

  final String textKey;

  final IconData icon;
}

/// One step of the Foundation's journey. [year] is shown as written.
class AboutMilestone {
  const AboutMilestone({required this.year, required this.titleKey, required this.textKey});

  final String year;

  final String titleKey;

  final String textKey;
}

/// One leader. [nameKey] reuses the translated names from the support
/// contacts so the name shows in the member's own language.
class AboutLeader {
  const AboutLeader({required this.nameKey, required this.roleKey});

  final String nameKey;

  final String roleKey;
}

/// Everything the About Us screen shows.
///
/// >>> DUMMY DATA <<<  The numbers, programs and milestones below are
/// placeholders so the screen looks complete. Replace the values here (or
/// load them from an API) — the screen and its translations follow. The
/// registration numbers and the leaders' names are the real ones from the
/// printed member card.
class AboutUsInfo {
  AboutUsInfo._();

  static const List<AboutStat> stats = [
    AboutStat(value: 12500, labelKey: 'about_stat_families', icon: Icons.family_restroom_rounded),
    AboutStat(value: 25000, labelKey: 'about_stat_members', icon: Icons.groups_rounded),
    AboutStat(value: 18, labelKey: 'about_stat_districts', icon: Icons.map_rounded),
    AboutStat(value: 12, labelKey: 'about_stat_programs', icon: Icons.volunteer_activism_rounded),
  ];

  static const List<AboutProgram> programs = [
    AboutProgram(
      titleKey: 'about_program_health_title',
      textKey: 'about_program_health_text',
      icon: Icons.health_and_safety_rounded,
    ),
    AboutProgram(
      titleKey: 'about_program_education_title',
      textKey: 'about_program_education_text',
      icon: Icons.school_rounded,
    ),
    AboutProgram(
      titleKey: 'about_program_family_title',
      textKey: 'about_program_family_text',
      icon: Icons.shield_rounded,
    ),
    AboutProgram(
      titleKey: 'about_program_community_title',
      textKey: 'about_program_community_text',
      icon: Icons.diversity_3_rounded,
    ),
  ];

  static const List<AboutMilestone> milestones = [
    AboutMilestone(year: '2025', titleKey: 'about_milestone_1_title', textKey: 'about_milestone_1_text'),
    AboutMilestone(year: '2025', titleKey: 'about_milestone_2_title', textKey: 'about_milestone_2_text'),
    AboutMilestone(year: '2026', titleKey: 'about_milestone_3_title', textKey: 'about_milestone_3_text'),
  ];

  static const List<AboutLeader> leaders = [
    AboutLeader(nameKey: 'support_contact_2_name', roleKey: 'contact_role_founder'),
    AboutLeader(nameKey: 'support_contact_1_name', roleKey: 'contact_role_founder'),
  ];

  static const String registrationNumber = 'U94990GJ2025NPL167764';

  static const String licenceNumber = '173515';
}
