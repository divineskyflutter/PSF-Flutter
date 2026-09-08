/// Fixed integration constants for `SaveDocument`'s `Module`/`Platform`
/// fields.
///
/// Unlike Gender/Marital Status (which are user-facing choices and must
/// come live from `GetEnumBundle`), these identify *which document field*
/// and *which client app* is uploading — that's structural, not something
/// shown to the user, so it's safe to pin here. The values below are taken
/// directly from `GetEnumBundle`'s own response (not invented) and only
/// need updating if the backend ever renumbers them:
///
/// Moduletype: 1=UserProfile, 2=Banner, 3=MemberProfile, 4=MemberAadhar,
///             5=MemberPan, 6=MemberESign, 7=NomineeProfile,
///             8=MemberAadharBackImage, 9=NomineeAadharFrontImage,
///             10=NomineeAadharBackImage, 11=NomineePassBookCheque
/// Platform:   1=MemberMobile, 2=AgentMobile, 3=AdminMobile, 4=AdminWeb
class DocumentModule {
  DocumentModule._();

  /// Generic fallback — nothing on this wizard uses it anymore now that
  /// [nomineeProfile] exists specifically for the Nominee step (which
  /// originally reused this id before that module type was added
  /// backend-side).
  static const int userProfile = 1;

  static const int memberProfile = 3;
  static const int memberAadhar = 4;
  static const int memberPan = 5;
  static const int memberESign = 6;

  /// Added to GetEnumBundle's Moduletype list after the Nominee step was
  /// first built — use this for the Nominee step's photo uploads.
  static const int nomineeProfile = 7;

  /// Added alongside SaveMemberPersonalDetail's new `aadharBackImage`
  /// field — use for the Member step's Aadhaar BACK photo upload
  /// (`memberAadhar` above is the front).
  static const int memberAadharBack = 8;

  /// Added alongside SaveNominee's new `aadharFrontImage`,
  /// `aadharBackImage` and `passBook_Cheque` fields — one module id per
  /// new nominee document upload.
  static const int nomineeAadharFront = 9;
  static const int nomineeAadharBack = 10;
  static const int nomineePassbookCheque = 11;
}

class DocumentPlatform {
  DocumentPlatform._();

  /// This app is the member-facing mobile app.
  static const int memberMobile = 1;
}
