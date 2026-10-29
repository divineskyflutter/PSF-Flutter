import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';

/// Where a tapped notification can send the member.
///
/// The backend puts one of the [all] values in the notification's
/// `data.route`. A tab route switches the bottom bar of the signed-in shell; a
/// page route opens that page ON TOP of whatever the member was doing, so Back
/// behaves normally. Only screens that open without extra arguments are listed
/// — an unknown value is ignored (the app just opens) and never crashes.
class NotificationTarget {
  const NotificationTarget._({this.tabIndex, this.subTab, this.page, required this.label});

  /// Bottom-bar tab to show (see [MainNavigationController]).
  final int? tabIndex;

  /// Tab inside the bottom-bar tab (Passbook: 0 Deposit Account, 1 Loan
  /// Account); `null` leaves the tab as it was.
  final int? subTab;

  /// Named page to push.
  final String? page;

  /// Human description (for the docs).
  final String label;

  const NotificationTarget.tab(int index, String label, {int? subTab})
      : this._(tabIndex: index, subTab: subTab, label: label);

  const NotificationTarget.page(String route, String label)
      : this._(page: route, label: label);
}

class NotificationRoutes {
  NotificationRoutes._();

  /// route value -> target. Keep `docs/notifications.md` in step.
  static const Map<String, NotificationTarget> all = {
    // --- bottom-bar tabs of the signed-in app -----------------------------
    AppRoutes.home: NotificationTarget.tab(MainNavigationController.homeTab, 'Home tab'),
    '/profile': NotificationTarget.tab(MainNavigationController.profileTab, 'Profile tab'),
    '/card': NotificationTarget.tab(MainNavigationController.cardTab, 'Member card tab'),
    '/passbook': NotificationTarget.tab(MainNavigationController.passbookTab, 'Passbook tab'),
    '/passbook/deposit': NotificationTarget.tab(
        MainNavigationController.passbookTab, 'Passbook - Deposit Account tab',
        subTab: 0),
    '/passbook/loan': NotificationTarget.tab(
        MainNavigationController.passbookTab, 'Passbook - Loan Account tab',
        subTab: 1),

    // --- pages ----------------------------------------------------------------
    AppRoutes.notifications:
        NotificationTarget.page(AppRoutes.notifications, 'Notifications list'),
    AppRoutes.passbookEntries:
        NotificationTarget.page(AppRoutes.passbookEntries, 'Fee entries (Profile - View all)'),
    AppRoutes.aboutUs: NotificationTarget.page(AppRoutes.aboutUs, 'About Us'),
    AppRoutes.contactUs: NotificationTarget.page(AppRoutes.contactUs, 'Contact Us'),
    AppRoutes.termsAndConditions:
        NotificationTarget.page(AppRoutes.termsAndConditions, 'Terms & Conditions'),
    AppRoutes.privacyPolicy:
        NotificationTarget.page(AppRoutes.privacyPolicy, 'Privacy Policy'),
  };

  /// Looks up [raw] (tolerates spaces, a missing leading "/", trailing "/",
  /// and upper case). `null` when it isn't a supported route.
  static NotificationTarget? resolve(String? raw) {
    var route = (raw ?? '').trim().toLowerCase();
    if (route.isEmpty) return null;
    if (!route.startsWith('/')) route = '/$route';
    while (route.length > 1 && route.endsWith('/')) {
      route = route.substring(0, route.length - 1);
    }
    return all[route];
  }
}
