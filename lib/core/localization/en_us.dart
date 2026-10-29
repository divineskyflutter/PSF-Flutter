import 'info_pages_strings.dart';
import 'registration_strings.dart';

const Map<String, String> enUS = {
  ...registrationEn,
  ...infoPagesEn,
  // Common
  'app_name': 'PSF Foundation',
  'welcome': 'Welcome',
  'continue': 'Continue',
  'next': 'Next',
  'skip': 'Skip',
  'login': 'Login',
  'sign_up': 'Sign up',
  'logout': 'Logout',
  'cancel': 'Cancel',

  // Permissions (camera / gallery — shared across every photo upload)
  'permission_required': 'Permission Required',
  'open_settings': 'Open Settings',
  'enable_from_settings':
  'Please enable it from Settings → App Permissions.',
  'camera_permission_required':
  'Camera permission is required to take a photo.',
  'storage_permission_required':
  'Storage permission is required to pick a photo.',
  'photo_library_permission_required':
  'Photo library permission is required to pick a photo.',

  // Language
  'choose_language': 'Choose Language',
  'select_preferred_language':
  'Select your preferred language to continue',
  'language_change_hint':
  'You can change language anytime from profile settings.',

  // Onboarding
  'onboarding_welcome_title':
  'Welcome to\nParivar Suraksha Foundation',
  'onboarding_welcome_description':
  'Safer families, stronger communities, and a brighter future.',

  'onboarding_family_title':
  'Your Family,\nOur Priority',
  'onboarding_family_description':
  'Building a safe, caring, and supportive future for every family.',

  'onboarding_grow_title':
  'Together,\nWe Grow',
  'onboarding_grow_description':
  'Supporting each other today to create a better tomorrow.',

  // Authentication
  'welcome_to_psf': 'Welcome to PSF',
  'auth_header_subtitle':
  'A True promise of family security',
  'auth_welcome_title':
  "Your family's Security starts Here",
  'auth_welcome_description':
  'Sign in to continue or register to become part of our trusted community.',
  'sign_in': 'Sign In',
  'register': 'Register',
  'banner_placeholder': 'Banner Image',

  // Authentication/Register

  'family_safety_foundation': 'Parivar Suraksha Foundation',
  'family_safety_subtitle':
  'Start your journey towards a safer and secure family.',

  'enter_your_information': 'Enter Your Information',
  'enter_information_correctly':
  'Please enter the following information correctly.',

  'first_name': 'First Name',
  'enter_first_name': 'Enter your first name',
  'please_enter_first_name':
  'Please enter your first name',

  'middle_name': 'Middle Name',
  'enter_middle_name': 'Enter your middle name',
  'please_enter_middle_name':
  'Please enter your middle name',

  'surname': 'Surname',
  'enter_surname': 'Enter your surname',
  'please_enter_surname':
  'Please enter your surname',

  'please_enter_valid_name':
  'Please enter a valid name using letters only',

  'phone_number': 'Phone Number',
  'enter_mobile_number':
  'Enter 10 digit mobile number',
  'please_enter_phone_number':
  'Please enter your phone number',
  'please_enter_valid_phone_number':
  'Please enter a valid 10 digit mobile number',

  'secure_encrypted_login':
  'Secure & encrypted login',

  //Authentication/register/firstscreen

  'welcome_to_parivar_suraksha':
  'Welcome to Parivar Suraksha Foundation',

  'bipin_hambhibhai_ghoghin':
  'Bipin Hambhibhai Ghoghin',

  'legal_compliance':
  'Legal & Compliance',

  'read_more':
  'Read More',

  'family_welfare_information':
  'Learn more about our family welfare initiatives and the benefits available for your family.',

  'registration_form_information':
  'To become a part of the family welfare program, please complete the registration form.',

  'continue_registration':
  'Continue Registration',

  'information':
  'Information',

  // Bottom navigation
  'home':
  'Home',

  'schemes':
  'Schemes',

  'about_us':
  'About Us',

  'contact_us':
  'Contact Us',

  // Home — a Foundation dashboard, not a finance one: no balances,
  // payments, or loans belong here.
  'dashboard':
  'Dashboard',

  'quick_actions':
  'Quick Actions',

  'documents':
  'Documents',

  'support':
  'Support',

  'recent_updates':
  'Recent Updates',

  'membership_countdown_title':
  'Membership Activation',

  'membership_countdown_subtitle':
  'Your membership activates in',

  'membership_active_title':
  'Membership Active',

  'membership_active_subtitle':
  'Your Parivar Suraksha membership is active.',

  'days_label':
  'Days',

  'hours_label':
  'Hours',

  'minutes_label':
  'Min',

  'seconds_label':
  'Sec',

  'current_balance':
  'Current Balance',

  'no_images_available':
  'No images available',


  // About Us
  'know_about_us': 'Know About Us',

  'know_about_us_description':
  'Learn about Parivar Suraksha Foundation, our mission, and our commitment to supporting families and building a stronger community.',

  'about_us_description':
  'Learn more about Parivar Suraksha Foundation',

  // ------------------------------------------------------------
  // Common actions
  // ------------------------------------------------------------

  'edit': 'Edit',
  'save': 'Save',
  'share': 'Share',
  'download': 'Download',
  'delete': 'Delete',
  'view_all': 'View All',
  'something_went_wrong': 'Something went wrong. Please try again.',
  'no_data_found': 'No data found',

  // ------------------------------------------------------------
  // Bottom Navigation
  // ------------------------------------------------------------

  'loans': 'Loans',
  'profile': 'Profile',

  // ------------------------------------------------------------
  // Home Dashboard — Membership Scheme summary
  // ------------------------------------------------------------

  'welcome_back': 'Welcome,',
  'member_summary': 'Member Summary',
  'scheme_name': 'Scheme Name',
  'total_amount': 'Total Amount',
  'paid_amount': 'Paid Amount',
  'remaining_amount': 'Remaining Amount',
  'due_date': 'Due Date',
  'percent_completed': 'Completed',
  'payment_reminder': 'Payment Reminder',
  'no_active_scheme_message':
  'You do not have an active membership scheme yet.',

  // ------------------------------------------------------------
  // Profile — menu
  // ------------------------------------------------------------

  'my_profile': 'My Profile',
  'welcome_to_profile': 'Welcome to your Profile',
  'member_id': 'Member Id',
  'membership_card': 'Membership Card',
  'passbook': 'Passbook',
  'language': 'Language',
  'terms_and_conditions_apply': 'Terms & Conditions Apply',
  // Membership fee / scheme / references
  'membership_fee_title': 'Membership Fee',
  'yojna_label': 'Yojna',
  'fee_total': 'Total Amount',
  'fee_paid': 'Paid',
  'fee_pending': 'Pending',
  'fee_fully_paid': 'Fully Paid',
  'fee_fully_paid_note': 'Your membership fee has been paid in full.',
  'references_title': 'References',
  'references_required_count': 'References required',
  'references_none_yet': 'No references added yet',
  'reference_of_title': 'You joined through the reference of',
  'reference_name_label': 'Name',
  // Home header / passbook tabs / documents
  'member_no_label': 'Member No',
  'status_label': 'Status',
  'sabhasad_fee_label': 'Sabhasad Fee',
  'sangyog_niti_label': 'Sangyog Niti',
  'loan_taken_label': 'Loan Taken',
  'loan_pending_label': 'Loan Pending',
  'sabhasad_account_tab': 'Sabhasad Account',
  'sangyog_niti_account_tab': 'Sangyog Niti Account',
  'loan_account_tab': 'Loan Account',
  'passbook_tab_empty': 'No entries yet',
  'download_documents_title': 'Download Documents',
  'doc_id_card': 'ID Card',
  'doc_receipt': 'My Receipt',
  'doc_certificate': 'Certificate',
  'doc_agreement': 'Agreement',
  'doc_application_form': 'Application Form',
  'doc_not_available': 'This document is not available yet.',
  'references_mismatch': 'References incomplete: @added of @required added.',
  'refresh_failed': 'We could not update your details from the server right now. The details saved on your phone are being shown.',
  'refresh_failed_title': 'Could not refresh',
  'ok_button': 'OK',
  'auth_btn_signin': 'Already a member? Sign In',
  'auth_btn_register': 'Become a New Member',
  'auth_link_about_text': 'Want to know more about us?',
  'auth_link_contact_text': 'Need help or have a question?',
  'auth_link_rules_text': 'Want to read our rules and terms?',
  'auth_link_action': 'Click here',
  'references_incomplete_title': 'References incomplete',
  'mobile_short_label': 'Mobile',
  'notifications_title': 'Notifications',
  'notifications_empty': 'No notifications yet',
  'notifications_filter_label': 'Filter',
  'notifications_filter_all': 'All',
  'notifications_filter_unread': 'Unread',
  'notifications_filter_read': 'Read',
  'notifications_load_more_failed': 'Could not load more. Tap to retry',
  'time_just_now': 'Just now',
  'time_sec_ago': '@n sec ago',
  'time_min_ago': '@n min ago',
  'time_hour_ago': '@n hr ago',
  'time_day_ago': '@n d ago',
  'time_month_ago': '@n mo ago',
  'time_year_ago': '@n yr ago',
  'deposit_account_tab': 'Deposit Account',
  'profile_form_details_title': 'Form details',
  'profile_form_details_hint': 'Tap to view the details you submitted',
  'profile_payment_progress': 'Payment progress',
  'profile_percent_paid': '@percent% paid',
  'profile_payment_history': 'Payment history',
  'profile_no_payments': 'No payments yet',
  'col_no': 'No.',
  'col_date': 'Date',
  'col_amount': 'Amount',
  'col_type': 'Type',
  'col_status': 'Status',
  'supporting_account_title': 'Supporting Account',
  'supporting_required': 'Required',
  'supporting_not_required': 'Not required',
  'supporting_added_count': '@added of @required added',
  'supporting_completed': 'Completed',
  'supporting_pending': '@pending pending',
  'supporting_none': 'You do not have any reference account.',
  'profile_fee_info': 'You can pay the fee in one go or in installments. It must be completed within 365 days.',
  'profile_important_title': 'Important notes',
  'profile_note_1': 'Your fixed membership fee must be completed within 365 days.',
  'profile_note_2': 'You can pay in one go, or weekly as it suits you.',
  'profile_note_3': 'Members above 50 years of age must submit the required Supporting Account details on time.',
  'profile_applicable_fee': 'Applicable fee (at joining)',
  'col_payment_type': 'Payment type',
  'col_receipt': 'Receipt',
  'page_of_total': 'Page @page of @total',
  'receipt_not_available': 'Receipt is not available yet',
  'profile_fee_entries_title': 'Fee entries',
  'profile_last_date': 'Last date to complete fee',
  'profile_member_name': 'Member name',
  'profile_joined_on': 'Member since',
  'profile_age': 'Age',
  'profile_age_years': '@age years',
  'supporting_age_rule': 'Your age: @age  |  Rule: 18 to 50 years',
  'sangyog_card_title': 'Sangyog Niti (@amount)',
  'sangyog_card_desc': 'From your membership fee, @amount is deposited into the Sangyog Niti account.',
  'sangyog_initial_deposit': 'Initial deposit',
  'sangyog_deposit_done': 'Deposit complete',
  'sangyog_note': 'This amount is kept in the Niti account as per the organisation rules.',
  'delete_account': 'Delete Account',

  // ------------------------------------------------------------
  // My Profile — field labels
  // ------------------------------------------------------------

  'edit_profile': 'Edit Profile',

  // My Profile — tabs
  'personal_tab': 'Personal',
  'nominee_tab': 'Nominee',
  'health_declaration_tab': 'Health Declaration',
  'member_status': 'Member Status',
  'profile_photo_label': 'Profile Photo',
  'aadhar_front_photo_label': 'Aadhaar Front Photo',
  'aadhar_back_photo_label': 'Aadhaar Back Photo',
  'pan_card_photo_label': 'PAN Card Photo',
  'no_nominee_found': 'No nominee added yet',

  // ------------------------------------------------------------
  // Membership Card
  // ------------------------------------------------------------

  'valid_member': 'Valid Member',
  'joining_date': 'Joining Date',

  // ------------------------------------------------------------
  // Passbook
  // ------------------------------------------------------------

  'passbook_empty_message': 'No passbook entries yet.',
  'withdrawn_amount': 'Withdrawn',
  'balance_amount': 'Balance',
  'savings': 'Savings',
  'details': 'Details',

  // ------------------------------------------------------------
  // Loans
  // ------------------------------------------------------------

  'loan_details': 'Loan Details',
  'foreclosure_amount': 'Foreclosure Amount',
  'loan_amount': 'Loan Amount',
  'current_due_amount': 'Current Due Amount',
  'pending_installments': 'Pending Instalments',
  'loan_id': 'Loan ID',
  'view_instalment_details': 'View Instalment Details',
  'installment_details': 'Instalment Details',
  'installment_no': 'Instalment',
  'upcoming_on': 'Upcoming on',
  'paid': 'Paid',
  'pending': 'Pending',
  'overdue': 'Overdue',
  'no_active_loan_message': 'You do not have any active loans.',

  // ------------------------------------------------------------
  // About Us — Mission / Vision / Values
  // ------------------------------------------------------------

  'our_mission': 'Mission',
  'our_mission_text':
  'To empower families and communities through support, awareness, and social development.',
  'our_vision': 'Vision',
  'our_vision_text':
  'A safer, healthier, and more empowered society where every family can thrive.',
  'our_values': 'Our Values',
  'value_compassion': 'Compassion',
  'value_integrity': 'Integrity',
  'value_transparency': 'Transparency',
  'value_equality': 'Equality',
  'value_service_to_humanity': 'Service to Humanity',

  // ------------------------------------------------------------
  // Terms & Conditions
  // ------------------------------------------------------------

  'terms_and_conditions': 'Terms & Conditions',
  'terms_and_conditions_intro':
  'By using the Parivar Suraksha Foundation app, you agree to the following terms and conditions. Please read them carefully before continuing to use our services.',

  // ------------------------------------------------------------
  // Privacy Policy
  // ------------------------------------------------------------

  'privacy_policy': 'Privacy Policy',
  'privacy_policy_intro':
  'At Parivar Suraksha Foundation, we value your privacy and are committed to protecting your personal information.',
  'information_we_collect': 'Information We Collect',
  'information_we_collect_text':
  '1. Details you give us when you register: name (also in Hindi/Gujarati), gender, date of birth, marital status, mobile number, address and occupation.\n\n2. Documents and photos you upload: profile photo, Aadhaar and PAN details/photos, signature, and your nominee\'s details and documents.\n\n3. A health declaration you fill in for the membership scheme.\n\n4. Your login details, and your membership and passbook records kept by the Foundation.\n\n5. Camera and photos are used only for the pictures you choose to take or select. We do not use your location, contacts, SMS or microphone.',
  'data_protection': 'Data Protection',
  'data_protection_text':
  'Your data is sent over encrypted (HTTPS) connections, and your sign-in details are kept in your phone\'s secure storage. Access to member records is limited to authorised Foundation staff.',
  'information_sharing': 'Information Sharing',
  'information_sharing_text':
  'We do not sell or rent your personal information. It is used only to run your membership, and is shared only when the law requires it or with your consent.',
  'your_rights': 'Your Rights',
  'your_rights_text':
  'You can view your details in the app, ask us to correct them, or delete your account at any time from the Delete Account option in the menu. You can also write to us at psk4mail@gmail.com for corrections or complaints.',
  'policy_updates': 'Policy Updates',
  'policy_updates_text':
  'This Privacy Policy may be updated from time to time. Any changes will be reflected within the application.',

  // ------------------------------------------------------------
  // Contact Us
  // ------------------------------------------------------------

  'founder': 'Founder',
  'contact_us_empty_message': 'Contact details are not available right now.',

  // ------------------------------------------------------------
  // Delete Account
  // ------------------------------------------------------------

  'delete_account_question': 'Are you sure you want to Delete Account?',
  'delete_account_warning':
  'This will permanently remove your membership, passbook and loan records. This action cannot be undone.',

  // ------------------------------------------------------------
  // Logout
  // ------------------------------------------------------------

  'logout_confirm_message': 'Are you sure you want to logout?',
  'session_expired_message': 'Your session has expired. Please login again.',
  // Bottom nav / side menu / member card
  'nav_card': 'Card',
  'press_back_again_to_exit': 'Press back again to exit',
  'member_card': 'Member Card',
  'menu': 'Menu',
  'view_profile': 'View Profile',
  'tap_to_open_card': 'Tap to open your card',
  'tap_to_flip_card': 'Tap the card to flip it',
  'download_card': 'Download Card',
  'card_downloading': 'Preparing your card…',
  'scan_qr': 'Scan QR to verify',
  'qr_unavailable': 'QR code unavailable',
  'tap_to_retry': 'Tap to retry',
  'close_wallet': 'Close',
  'card_valid_note': 'Issued by Parivar Suraksha Foundation. Scan the QR code to verify this card.',
  'nominee_share_percent': 'Share (%)',
  'nominees_count': 'Nominees',
  'nominee_passbook_cheque_label': 'Passbook / Cheque Photo',

  // Enum names (GetEnumBundle) - Gender / Marital Status / Member Status / Relation
  'enum_male': 'Male',
  'enum_female': 'Female',
  'enum_other': 'Other',
  'enum_single': 'Single',
  'enum_married': 'Married',
  'enum_divorced': 'Divorced',
  'enum_widowed': 'Widowed',
  'enum_registrationpending': 'Registration Pending',
  'enum_inreview': 'In Review',
  'enum_approved': 'Approved',
  'enum_active': 'Active',
  'enum_inedit': 'In Edit',
  'enum_father': 'Father',
  'enum_mother': 'Mother',
  'enum_son': 'Son',
  'enum_daughter': 'Daughter',
  'enum_brother': 'Brother',
  'enum_sister': 'Sister',
  'enum_husband': 'Husband',
  'enum_wife': 'Wife',
  'enum_grandfather': 'Grandfather',
  'enum_grandmother': 'Grandmother',
  'enum_grandson': 'Grandson',
  'enum_granddaughter': 'Granddaughter',
  'enum_uncle': 'Uncle',
  'enum_aunt': 'Aunt',
  'enum_nephew': 'Nephew',
  'enum_niece': 'Niece',
  'enum_cousin': 'Cousin',
  'enum_fatherinlaw': 'Father-in-law',
  'enum_motherinlaw': 'Mother-in-law',
  'enum_brotherinlaw': 'Brother-in-law',
  'enum_sisterinlaw': 'Sister-in-law',
  'enum_soninlaw': 'Son-in-law',
  'enum_daughterinlaw': 'Daughter-in-law',
  'enum_stepfather': 'Stepfather',
  'enum_stepmother': 'Stepmother',
  'enum_stepson': 'Stepson',
  'enum_stepdaughter': 'Stepdaughter',
  'enum_stepbrother': 'Stepbrother',
  'enum_stepsister': 'Stepsister',

  // Horizontal member card (matches the printed foundation card)
  'card_title': 'PARIVAR SURKSHA FOUNDATION',
  'card_tagline': 'પરિવારની સુરક્ષાનું સાચું વચન',
  'card_label_name': 'Name',
  'card_label_contact': 'Contact',
  'card_label_dob': 'DOB',
  'card_layout_horizontal': 'Horizontal',
  'card_layout_vertical': 'Vertical',
  'card_footer_note': 'આ કાર્ડ માત્ર પરિવાર સુરક્ષા ફાઉન્ડેશનની વિવિધ યોજનાઓના ઉપયોગ માટેની ઓળખ છે.',
};
