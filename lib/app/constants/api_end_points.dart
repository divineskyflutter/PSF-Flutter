// lib/core/network/api_end_points.dart

import 'package:psf_application/app/config/env/env.dart';

class ApiEndPoints {
  ApiEndPoints._();

  static String get baseUrl => Env.config.baseUrl;

  // Api
  static String get getEnumBundle => '$baseUrl/api/Api/GetEnumBundle';

  // Banner
  static String get getBannerListByType => '$baseUrl/api/Banner/GetBannerListByType';

  static String get saveMemberStep1 =>
      '$baseUrl/api/Member/SaveMemberStep1';

  static String get getSingleMemberByRegisteredStatus =>
      '$baseUrl/api/Member/GetSingleMemberByRegistredStatus';

  static String get saveRulesRegulationScreen =>
      '$baseUrl/api/Member/SaveRulesRegulationScreen';

  static String get saveMemberPersonalDetail =>
      '$baseUrl/api/Member/SaveMemberPersonalDetail';

  /// Marks the Nominee step (step 2) as done for the member — called once
  /// every visible nominee slot has been saved via [saveNominee], right
  /// before moving on to the Health step. Request body is just
  /// `{"id": memberId}`, same shape as [saveRulesRegulationScreen].
  static String get saveNomineeScreen =>
      '$baseUrl/api/Member/SaveNomineeScreen';

  static String get saveDocument =>
      '$baseUrl/api/Document/SaveDocument';

  // ============================================================
  // Nominee
  // ============================================================

  /// Creates (nomineeId 0) or updates (nomineeId > 0) a single nominee.
  static String get saveNominee =>
      '$baseUrl/api/Nominee/SaveNominee';

  /// Returns every nominee already saved for a member — request body is
  /// `{"id": memberId}`. Used to prefill the Nominee step when the member
  /// resumes registration after already saving one or more nominees.
  static String get getNomineeByMemberId =>
      '$baseUrl/api/Nominee/GetNomineeByMemberId';

  // ============================================================
  // Health Declaration
  // ============================================================

  /// Always called on the Health step's Next button (create when
  /// `healthDeclarationId` is 0, update when it's a real id already
  /// returned by an earlier save or by [getHealthDeclarationByMemberId]).
  static String get saveMemberHealthDeclaration =>
      '$baseUrl/api/HealthDeclaration/SaveMemberHealthDeclaration';

  /// Called once when the Health step opens, to prefill it with whatever
  /// was already saved for this member (same "GET first, then allow
  /// editing" pattern as [getNomineeByMemberId]) — request body is
  /// `{"id": memberId}`.
  static String get getHealthDeclarationByMemberId =>
      '$baseUrl/api/HealthDeclaration/GetHealthDeclarationByMemberId';

  // ============================================================
  // Rules & Declaration step (step 5's accept-checkbox screen) — distinct
  // from [saveRulesRegulationScreen] above, which is called earlier, from
  // the Legal Rules screen before step 1 even starts.
  // ============================================================

  static String get saveRulesRegulationAcceptScreen =>
      '$baseUrl/api/Member/SaveRulesRegulationAcceptScreen';

  /// Called from the Preview screen's final "Complete Registration"
  /// button, before navigating to Home — request body is `{"id": memberId}`.
  static String get savePreviewScreen =>
      '$baseUrl/api/Member/SavePreviewScreen';

  // ============================================================
  // Transliteration APIs
  //
  // These convert phonetically-typed text into a target script and are
  // what the registration screens use to fill the hi/gu name variants —
  // NOT the `/api/translation/en-*` endpoints below, which do
  // meaning-based translation and don't fit proper names.
  // ============================================================
  static String get transliterateToHindi =>
      '$baseUrl/api/Transliteration/Hindi';
  static String get transliterateToGujarati =>
      '$baseUrl/api/Transliteration/Gujarati';
  static String get transliterateToEnglish =>
      '$baseUrl/api/Transliteration/English';

  // Meaning-based translation (English only, per the current API surface).
  // Kept for future use elsewhere in the app; not used for name fields.
  // static String get englishToHindi => '$baseUrl/api/translation/en-hi';
  // static String get englishToGujarati => '$baseUrl/api/translation/en-gu';

  // ============================================================
  // Home / Profile / Passbook / Loans
  //
  // These path segments are provisional — the app's backend team hasn't
  // handed off a final route list for this area yet. Every endpoint below
  // still goes through NetworkCaller and returns the same
  // `{status, message, data, id}` envelope as the endpoints above, so once
  // the real paths are known only the string literals here need to change
  // — nothing in the repositories/controllers that call them.
  // ============================================================

  // Home dashboard — membership scheme summary + payment reminder.
  static String get getMemberDashboard =>
      '$baseUrl/api/Member/GetMemberDashboard';

  // Full member profile (for the My Profile / Membership Card screens).
  static String get getMemberProfile =>
      '$baseUrl/api/Member/GetMemberProfile';

  static String get updateMemberProfile =>
      '$baseUrl/api/Member/UpdateMemberProfile';

  static String get deleteMemberAccount =>
      '$baseUrl/api/Member/DeleteAccount';

  // Passbook — ledger of scheme payments / withdrawals.
  static String get getPassbook => '$baseUrl/api/Member/GetPassbook';

  // Loans
  static String get getLoanDetails => '$baseUrl/api/Loan/GetLoanDetails';

  static String get getLoanInstallments =>
      '$baseUrl/api/Loan/GetLoanInstallments';

  // Contact Us — founders / support contacts list.
  static String get getContactUsList =>
      '$baseUrl/api/Content/GetContactUsList';
}