import 'package:flutter/material.dart';

/// One person / desk on the Contact Us screen. [nameKey] and [roleKey] are
/// translation keys (so the name shows in the member's own language);
/// [phone] is the plain 10-digit number.
class ContactPerson {
  const ContactPerson({
    required this.nameKey,
    required this.roleKey,
    required this.phone,
    required this.icon,
  });

  final String nameKey;

  final String roleKey;

  final String phone;

  final IconData icon;
}

/// One address on the Contact Us screen. [addressKey] is a translation key
/// (the address is written in each language); [mapsQuery] is what Maps is
/// asked to search for (English, so it resolves the same in every language).
class ContactAddress {
  const ContactAddress({
    required this.titleKey,
    required this.addressKey,
    required this.mapsQuery,
    required this.icon,
  });

  final String titleKey;

  final String addressKey;

  final String mapsQuery;

  final IconData icon;
}

/// The Foundation's contact details, straight from its printed material and
/// the registration-pending screen. Plain constants on purpose — replace
/// them here (or load them from an API later) and the screen follows.
class ContactUsInfo {
  ContactUsInfo._();

  static const List<ContactPerson> people = [
    ContactPerson(
      nameKey: 'support_contact_office_name',
      roleKey: 'contact_role_office',
      phone: '9664698982',
      icon: Icons.apartment_rounded,
    ),
    ContactPerson(
      nameKey: 'support_contact_1_name',
      roleKey: 'contact_role_founder',
      phone: '9825635110',
      icon: Icons.person_rounded,
    ),
    ContactPerson(
      nameKey: 'support_contact_2_name',
      roleKey: 'contact_role_founder',
      phone: '8000212041',
      icon: Icons.person_rounded,
    ),
  ];

  static const String email = 'psk4mail@gmail.com';

  static const List<ContactAddress> addresses = [
    ContactAddress(
      titleKey: 'contact_reg_office',
      addressKey: 'contact_reg_office_address',
      mapsQuery: '57, D.K. Nagar-2, Nr. Santoshi Krupa Society, Dabholi Char Rasta, Katargam, Surat 395004',
      icon: Icons.business_rounded,
    ),
    ContactAddress(
      titleKey: 'contact_founders_office',
      addressKey: 'contact_founders_office_address',
      mapsQuery: 'B/29, Danev Ashish Society, Chikuwadi Road, Katargam, Surat 395004',
      icon: Icons.location_on_rounded,
    ),
  ];

  /// Office hours as minutes since midnight, matching the morning /
  /// afternoon lines shown from the `support_office_hours_*` translations
  /// (9:30 AM – 1:30 PM and 4:00 PM – 9:30 PM).
  static const List<(int, int)> openingWindows = [
    (9 * 60 + 30, 13 * 60 + 30),
    (16 * 60, 21 * 60 + 30),
  ];

  /// Whether the office is inside one of [openingWindows] at [now].
  static bool isOpenAt(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    return openingWindows.any((window) => minutes >= window.$1 && minutes < window.$2);
  }
}
