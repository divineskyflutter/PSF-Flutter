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
  // Home — a Foundation dashboard, not a finance one: no balance,
  // payment, or loan strings belong here.
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