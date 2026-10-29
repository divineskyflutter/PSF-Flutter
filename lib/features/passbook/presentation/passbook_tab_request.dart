import 'package:flutter/foundation.dart';

/// "Show this tab of the Passbook screen" — left by a tapped notification
/// (`/passbook/deposit`, `/passbook/loan`) and picked up by
/// `PassbookTabsScreen`, which slides to the tab and clears the request.
class PassbookTabRequest {
  PassbookTabRequest._();

  static const int depositTab = 0;
  static const int loanTab = 1;

  static final ValueNotifier<int?> requested = ValueNotifier<int?>(null);

  static void request(int tab) => requested.value = tab;
}
