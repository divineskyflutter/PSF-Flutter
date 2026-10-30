class AppStrings {
  AppStrings._();

  // ------------------------------------------------------------
  // Common
  // ------------------------------------------------------------

  static const String appName = 'app_name';
  static const String welcome = 'welcome';
  static const String continueText = 'continue';
  static const String next = 'next';
  static const String skip = 'skip';
  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String logout = 'logout';

  // ------------------------------------------------------------
  // Language
  // ------------------------------------------------------------

  static const String chooseLanguage = 'choose_language';
  static const String selectPreferredLanguage =
      'select_preferred_language';
  static const String languageChangeHint = 'language_change_hint';

  // ------------------------------------------------------------
  // Onboarding
  // ------------------------------------------------------------

  static const String onboardingWelcomeTitle =
      'onboarding_welcome_title';

  static const String onboardingWelcomeDescription =
      'onboarding_welcome_description';

  static const String onboardingFamilyTitle =
      'onboarding_family_title';

  static const String onboardingFamilyDescription =
      'onboarding_family_description';

  static const String onboardingGrowTitle =
      'onboarding_grow_title';

  static const String onboardingGrowDescription =
      'onboarding_grow_description';

  // ------------------------------------------------------------
  // Authentication
  // ------------------------------------------------------------

  static const String welcomeToPsf =
      'welcome_to_psf';

  static const String authHeaderSubtitle =
      'auth_header_subtitle';

  static const String authWelcomeTitle =
      'auth_welcome_title';

  static const String authWelcomeDescription =
      'auth_welcome_description';

  static const String signIn =
      'sign_in';

  static const String register =
      'register';

  static const String bannerPlaceholder =
      'banner_placeholder';




  // ------------------------------------------------------------
  // Home — a Foundation dashboard, not a raw finance ledger: the full
  // payment/loan history still lives in Passbook/Loans. The membership
  // countdown and the current-balance summary below are a deliberate
  // exception — a glance at "when do I activate" and "what's my balance
  // right now" without leaving Home, not a ledger.
  // ------------------------------------------------------------

  static const String dashboard =
      'dashboard';

  static const String quickActions =
      'quick_actions';

  static const String documents =
      'documents';

  static const String support =
      'support';

  /// Heading for Home's placeholder "recent updates" list — see
  /// HomeScreen's _RecentUpdatesSection doc comment for why it's dummy
  /// content for now.
  static const String recentUpdates =
      'recent_updates';

  // Membership activation countdown (joining date + 365 days) — see
  // MembershipCountdownCard.
  static const String membershipCountdownTitle =
      'membership_countdown_title';
  static const String membershipCountdownSubtitle =
      'membership_countdown_subtitle';
  static const String membershipActiveTitle =
      'membership_active_title';
  static const String membershipActiveSubtitle =
      'membership_active_subtitle';
  static const String daysLabel = 'days_label';
  static const String hoursLabel = 'hours_label';
  static const String minutesLabel = 'minutes_label';
  static const String secondsLabel = 'seconds_label';

  // Current-balance summary — see HomeBalanceCard.
  static const String currentBalance = 'current_balance';

  // ------------------------------------------------------------
  // Other
  // ------------------------------------------------------------

  static const String noImagesAvailable =
      'no_images_available';

// ------------------------------------------------------------
// About Us
// ------------------------------------------------------------

  static const String aboutUs =
      'about_us';

  static const String aboutUsDescription =
      'about_us_description';

  static const String knowAboutUs =
      'know_about_us';
  static const String knowAboutUsDescription =
      'know_about_us_description';

  // ------------------------------------------------------------
  // Common actions
  // ------------------------------------------------------------

  static const String cancel = 'cancel';
  static const String retry = 'retry';
  static const String edit = 'edit';
  static const String save = 'save';
  static const String share = 'share';
  static const String download = 'download';
  static const String delete = 'delete';
  static const String viewAll = 'view_all';
  static const String somethingWentWrong = 'something_went_wrong';
  static const String noDataFound = 'no_data_found';

  // ------------------------------------------------------------
  // Bottom Navigation
  // ------------------------------------------------------------

  static const String navHome = 'home';
  static const String navLoans = 'loans';
  static const String navProfile = 'profile';

  // ------------------------------------------------------------
  // Home Dashboard — Membership Scheme summary
  //
  // This is the Foundation dashboard's own "scheme progress" card, kept
  // distinct from the Loans tab below: it talks about the member's
  // Parivar Suraksha Yojna membership scheme, not a raw balance/loan
  // ledger.
  // ------------------------------------------------------------

  static const String welcomeBack = 'welcome_back';
  static const String memberSummary = 'member_summary';
  static const String schemeName = 'scheme_name';
  static const String totalAmount = 'total_amount';
  static const String paidAmount = 'paid_amount';
  static const String remainingAmount = 'remaining_amount';
  static const String dueDate = 'due_date';
  static const String percentCompleted = 'percent_completed';
  static const String paymentReminder = 'payment_reminder';
  static const String noActiveSchemeMessage = 'no_active_scheme_message';

  // ------------------------------------------------------------
  // Profile — menu
  // ------------------------------------------------------------

  static const String myProfile = 'my_profile';
  static const String welcomeToProfile = 'welcome_to_profile';
  static const String memberId = 'member_id';
  static const String membershipCard = 'membership_card';
  static const String passbook = 'passbook';
  static const String language = 'language';
  static const String termsAndConditionsApply = 'terms_and_conditions_apply';
  static const String membershipFeeTitle = 'membership_fee_title';
  static const String yojnaLabel = 'yojna_label';
  static const String feeTotal = 'fee_total';
  static const String feePaid = 'fee_paid';
  static const String feePending = 'fee_pending';
  static const String feeFullyPaid = 'fee_fully_paid';
  static const String feeFullyPaidNote = 'fee_fully_paid_note';
  static const String referencesTitle = 'references_title';
  static const String referencesRequiredCount = 'references_required_count';
  static const String referencesNoneYet = 'references_none_yet';
  static const String referenceOfTitle = 'reference_of_title';
  static const String referenceNameLabel = 'reference_name_label';
  static const String memberNoLabel = 'member_no_label';
  static const String statusLabel = 'status_label';
  static const String sabhasadFeeLabel = 'sabhasad_fee_label';
  static const String sangyogNitiLabel = 'sangyog_niti_label';
  static const String loanTakenLabel = 'loan_taken_label';
  static const String loanPendingLabel = 'loan_pending_label';
  static const String sabhasadAccountTab = 'sabhasad_account_tab';
  static const String sangyogNitiAccountTab = 'sangyog_niti_account_tab';
  static const String loanAccountTab = 'loan_account_tab';
  static const String passbookTabEmpty = 'passbook_tab_empty';
  static const String downloadDocumentsTitle = 'download_documents_title';
  static const String docIdCard = 'doc_id_card';
  static const String docReceipt = 'doc_receipt';
  static const String docCertificate = 'doc_certificate';
  static const String docAgreement = 'doc_agreement';
  static const String docApplicationForm = 'doc_application_form';
  static const String docNotAvailable = 'doc_not_available';
  static const String referencesMismatch = 'references_mismatch';
  static const String refreshFailed = 'refresh_failed';
  static const String refreshFailedTitle = 'refresh_failed_title';
  static const String okButton = 'ok_button';
  static const String authBtnSignin = 'auth_btn_signin';
  static const String authBtnRegister = 'auth_btn_register';
  static const String authLinkAboutText = 'auth_link_about_text';
  static const String authLinkContactText = 'auth_link_contact_text';
  static const String authLinkRulesText = 'auth_link_rules_text';
  static const String authLinkAction = 'auth_link_action';
  static const String referencesIncompleteTitle = 'references_incomplete_title';
  static const String mobileShortLabel = 'mobile_short_label';
  static const String notificationsTitle = 'notifications_title';
  static const String notificationsEmpty = 'notifications_empty';
  static const String notificationsEmptyHint = 'notifications_empty_hint';
  static const String notificationsFilterLabel = 'notifications_filter_label';
  static const String notificationsFilterAll = 'notifications_filter_all';
  static const String notificationsFilterUnread = 'notifications_filter_unread';
  static const String notificationsFilterRead = 'notifications_filter_read';
  static const String notificationsLoadMoreFailed = 'notifications_load_more_failed';
  static const String timeJustNow = 'time_just_now';
  static const String timeSecAgo = 'time_sec_ago';
  static const String timeMinAgo = 'time_min_ago';
  static const String timeHourAgo = 'time_hour_ago';
  static const String timeDayAgo = 'time_day_ago';
  static const String timeMonthAgo = 'time_month_ago';
  static const String timeYearAgo = 'time_year_ago';
  static const String depositAccountTab = 'deposit_account_tab';
  static const String profileFormDetailsTitle = 'profile_form_details_title';
  static const String profileFormDetailsHint = 'profile_form_details_hint';
  static const String profilePaymentProgress = 'profile_payment_progress';
  static const String profilePercentPaid = 'profile_percent_paid';
  static const String profilePaymentHistory = 'profile_payment_history';
  static const String profileNoPayments = 'profile_no_payments';
  static const String colNo = 'col_no';
  static const String colDate = 'col_date';
  static const String colAmount = 'col_amount';
  static const String colType = 'col_type';
  static const String colStatus = 'col_status';
  static const String supportingAccountTitle = 'supporting_account_title';
  static const String supportingRequired = 'supporting_required';
  static const String supportingNotRequired = 'supporting_not_required';
  static const String supportingAddedCount = 'supporting_added_count';
  static const String supportingCompleted = 'supporting_completed';
  static const String supportingPending = 'supporting_pending';
  static const String supportingNone = 'supporting_none';
  static const String profileFeeInfo = 'profile_fee_info';
  static const String profileImportantTitle = 'profile_important_title';
  static const String profileNote1 = 'profile_note_1';
  static const String profileNote2 = 'profile_note_2';
  static const String profileNote3 = 'profile_note_3';
  static const String profileApplicableFee = 'profile_applicable_fee';
  static const String colPaymentType = 'col_payment_type';
  static const String colReceipt = 'col_receipt';
  static const String pageOfTotal = 'page_of_total';
  static const String receiptNotAvailable = 'receipt_not_available';
  static const String profileFeeEntriesTitle = 'profile_fee_entries_title';
  static const String profileLastDate = 'profile_last_date';
  static const String profileMemberName = 'profile_member_name';
  static const String profileJoinedOn = 'profile_joined_on';
  static const String profileAge = 'profile_age';
  static const String profileAgeYears = 'profile_age_years';
  static const String supportingAgeRule = 'supporting_age_rule';
  static const String sangyogCardTitle = 'sangyog_card_title';
  static const String sangyogCardDesc = 'sangyog_card_desc';
  static const String sangyogInitialDeposit = 'sangyog_initial_deposit';
  static const String sangyogDepositDone = 'sangyog_deposit_done';
  static const String sangyogNote = 'sangyog_note';
  static const String deleteAccount = 'delete_account';

  // ------------------------------------------------------------
  // My Profile — field labels
  // ------------------------------------------------------------

  static const String fullName = 'full_name';
  static const String mobileNumber = 'mobile_number';
  static const String fatherName = 'father_name';
  static const String dateOfBirth = 'date_of_birth';
  static const String gender = 'gender';
  static const String maritalStatus = 'marital_status';
  static const String address = 'address';
  static const String occupation = 'occupation';
  static const String editProfile = 'edit_profile';

  // ------------------------------------------------------------
  // My Profile — tabs (Personal / Nominee / Health Declaration)
  // ------------------------------------------------------------

  static const String personalTab = 'personal_tab';
  static const String nomineeTab = 'nominee_tab';
  static const String healthDeclarationTab = 'health_declaration_tab';
  static const String memberStatus = 'member_status';
  static const String nomineeShare = 'nominee_share';
  static const String profilePhotoLabel = 'profile_photo_label';
  static const String aadharFrontPhotoLabel = 'aadhar_front_photo_label';
  static const String aadharBackPhotoLabel = 'aadhar_back_photo_label';
  static const String panCardPhotoLabel = 'pan_card_photo_label';
  static const String noNomineeFound = 'no_nominee_found';

  // ------------------------------------------------------------
  // Membership Card
  // ------------------------------------------------------------

  static const String validMember = 'valid_member';
  static const String joiningDate = 'joining_date';

  // ------------------------------------------------------------
  // Passbook
  // ------------------------------------------------------------

  static const String passbookEmptyMessage = 'passbook_empty_message';
  static const String withdrawnAmount = 'withdrawn_amount';
  static const String balanceAmount = 'balance_amount';
  static const String savings = 'savings';
  static const String details = 'details';

  // ------------------------------------------------------------
  // Loans
  // ------------------------------------------------------------

  static const String loanDetails = 'loan_details';
  static const String foreclosureAmount = 'foreclosure_amount';
  static const String loanAmount = 'loan_amount';
  static const String currentDueAmount = 'current_due_amount';
  static const String pendingInstallments = 'pending_installments';
  static const String loanId = 'loan_id';
  static const String viewInstalmentDetails = 'view_instalment_details';
  static const String installmentDetails = 'installment_details';
  static const String installmentNo = 'installment_no';
  static const String upcomingOn = 'upcoming_on';
  static const String paid = 'paid';
  static const String pending = 'pending';
  static const String overdue = 'overdue';
  static const String noActiveLoanMessage = 'no_active_loan_message';

  // ------------------------------------------------------------
  // About Us — Mission / Vision / Values
  // ------------------------------------------------------------

  static const String ourMission = 'our_mission';
  static const String ourMissionText = 'our_mission_text';
  static const String ourVision = 'our_vision';
  static const String ourVisionText = 'our_vision_text';
  static const String ourValues = 'our_values';
  static const String valueCompassion = 'value_compassion';
  static const String valueIntegrity = 'value_integrity';
  static const String valueTransparency = 'value_transparency';
  static const String valueEquality = 'value_equality';
  static const String valueServiceToHumanity = 'value_service_to_humanity';

  // ------------------------------------------------------------
  // Terms & Conditions
  // ------------------------------------------------------------

  static const String termsAndConditions = 'terms_and_conditions';
  static const String termsAndConditionsIntro = 'terms_and_conditions_intro';

  // ------------------------------------------------------------
  // Privacy Policy
  // ------------------------------------------------------------

  static const String privacyPolicy = 'privacy_policy';
  static const String privacyPolicyIntro = 'privacy_policy_intro';
  static const String informationWeCollect = 'information_we_collect';
  static const String informationWeCollectText = 'information_we_collect_text';
  static const String dataProtection = 'data_protection';
  static const String dataProtectionText = 'data_protection_text';
  static const String informationSharing = 'information_sharing';
  static const String informationSharingText = 'information_sharing_text';
  static const String yourRights = 'your_rights';
  static const String yourRightsText = 'your_rights_text';
  static const String policyUpdates = 'policy_updates';
  static const String policyUpdatesText = 'policy_updates_text';

  // ------------------------------------------------------------
  // Contact Us
  // ------------------------------------------------------------

  static const String contactUs = 'contact_us';
  static const String founder = 'founder';
  static const String contactUsEmptyMessage = 'contact_us_empty_message';

  // ------------------------------------------------------------
  // Delete Account
  // ------------------------------------------------------------

  static const String deleteAccountQuestion = 'delete_account_question';
  static const String deleteAccountWarning = 'delete_account_warning';

  // ------------------------------------------------------------
  // Logout
  // ------------------------------------------------------------

  static const String logoutConfirmMessage = 'logout_confirm_message';
}