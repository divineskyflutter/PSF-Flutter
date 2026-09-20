import 'package:psf_application/shared/enums/app_language.dart';

class MemberModel {
  final int memberId;

  // ============================================================
  // BASIC MEMBER INFORMATION
  // ============================================================

  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? mobile;

  /// Second/alternate mobile number — sent as `mobile2` on
  /// SaveMemberPersonalDetail (see RegistrationController.mobile2Controller)
  /// but was never parsed back out of GetMemberStatus/
  /// GetSingleMemberByRegisteredStatus's response, so a resumed
  /// registration always showed this field blank even when the member had
  /// already filled it in and saved. Multiple candidate keys, same reason
  /// as every other field here — this API's GET response casing isn't
  /// confirmed to match its own POST schema.
  final String? mobile2;

  /// The real member number (e.g. `PSF12545`) — null until one is assigned.
  /// Deliberately separate from [memberId], which is just the database id.
  final String? memberNo;

  // Hindi/Gujarati transliterations, same convention as NomineeModel's
  // hName/gName — SaveMemberPersonalDetail accepts these (see
  // SaveMemberPersonalDetailRequestModel: hfirstName/gfirstName etc.), so
  // GetMemberStatus almost certainly echoes them back too; they just
  // weren't being parsed here before, which is why resuming registration
  // in Hindi/Gujarati silently showed the plain/English text everywhere
  // instead of the saved translation (see RegistrationController.
  // getMemberStatus, which now seeds firstNameLanguages/etc. from these).
  final String? hFirstName;
  final String? gFirstName;
  final String? hLastName;
  final String? gLastName;
  final String? hSurname;
  final String? gSurname;

  // ============================================================
  // MEMBER DETAILS
  // ============================================================

  final String? fatherName;
  final String? hFatherName;
  final String? gFatherName;
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;

  // ============================================================
  // ADDRESS
  // ============================================================

  final String? address;
  final String? hAddress;
  final String? gAddress;
  final String? village;
  final String? hVillage;
  final String? gVillage;
  final String? taluka;
  final String? hTaluka;
  final String? gTaluka;
  final String? district;
  final String? hDistrict;
  final String? gDistrict;
  final String? state;
  final String? hState;
  final String? gState;

  // ============================================================
  // OTHER DETAILS
  // ============================================================

  final String? occupation;
  final String? hOccupation;
  final String? gOccupation;
  final String? aadharNo;
  final String? panNo;

  // ============================================================
  // UPLOADED DOCUMENT IDS + BEST-EFFORT URLS
  //
  // Document ids the member already uploaded in an earlier session (via
  // SaveDocument, then SaveMemberPersonalDetail) — present whenever this
  // response's own `data` object doesn't omit them, so a member who
  // closes and reopens the app mid-registration doesn't have to redo
  // uploads that already succeeded. See
  // RegistrationController.getMemberStatus, which reads these into
  // profileImageId/aadharImageId/panImageId/signatureFileId/
  // aadharBackImageId so uploadStep1Documents treats an existing id the
  // same as a freshly picked File.
  //
  // The *Url fields are the same best-effort, multi-key-fallback parse as
  // NomineeModel.photoUrl — nothing in the published schema documents a
  // URL field for these, so every plausible key is tried and the first
  // non-empty one wins; `null` when none match, which lets the resumed
  // image tile fall back to "tap to upload" instead of a broken image.
  // ============================================================

  final int? image;
  final int? aadharImage;
  final int? aadharBackImage;
  final int? panImage;
  final int? digitalSign;

  final String? imageUrl;
  final String? aadharImageUrl;
  final String? aadharBackImageUrl;
  final String? panImageUrl;
  final String? digitalSignUrl;

  // ============================================================
  // STATUS
  // ============================================================

  final int? status;

  /// Numeric registration-progress code (e.g. `4`).
  final String? memberDetailStatus;

  /// The actual app route to resume at (e.g. `"/member-registration-step2"`).
  /// This — not [memberDetailStatus] — is what should be handed to
  /// [RegistrationNavigator], since the numeric code isn't a route.
  final String? memberDetailStatusName;

  /// First + middle ([lastName]) + surname, in that order, skipping any
  /// that are empty. One shared place to build this instead of every
  /// screen concatenating the three fields itself.
  String get fullName => [firstName, lastName, surname]
      .where((part) => (part ?? '').trim().isNotEmpty)
      .map((part) => part!.trim())
      .join(' ');

  /// Same idea as [fullName], but each part prefers ITS OWN Hindi/Gujarati
  /// translation when [language] calls for one (falling back to that
  /// part's plain value when no translation was returned) — used to
  /// prefill the Member step's editable full-name field in whichever app
  /// language the member has selected, instead of always the plain/
  /// English value regardless of language. Same 3-tier fallback every
  /// other resumed field on this wizard already uses (see
  /// RegistrationController.getMemberStatus).
  String localizedFullName(AppLanguage language) {
    String partFor(String? plain, String? hindi, String? gujarati) {
      final translated = switch (language) {
        AppLanguage.hindi => hindi,
        AppLanguage.gujarati => gujarati,
        AppLanguage.english => plain,
      };

      if (translated != null && translated.trim().isNotEmpty) {
        return translated.trim();
      }

      return (plain ?? '').trim();
    }

    return [
      partFor(firstName, hFirstName, gFirstName),
      partFor(lastName, hLastName, gLastName),
      partFor(surname, hSurname, gSurname),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  const MemberModel({
    required this.memberId,

    this.firstName,
    this.lastName,
    this.surname,
    this.mobile,
    this.mobile2,
    this.memberNo,
    this.hFirstName,
    this.gFirstName,
    this.hLastName,
    this.gLastName,
    this.hSurname,
    this.gSurname,

    this.fatherName,
    this.hFatherName,
    this.gFatherName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,

    this.address,
    this.hAddress,
    this.gAddress,
    this.village,
    this.hVillage,
    this.gVillage,
    this.taluka,
    this.hTaluka,
    this.gTaluka,
    this.district,
    this.hDistrict,
    this.gDistrict,
    this.state,
    this.hState,
    this.gState,

    this.occupation,
    this.hOccupation,
    this.gOccupation,
    this.aadharNo,
    this.panNo,

    this.image,
    this.aadharImage,
    this.aadharBackImage,
    this.panImage,
    this.digitalSign,
    this.imageUrl,
    this.aadharImageUrl,
    this.aadharBackImageUrl,
    this.panImageUrl,
    this.digitalSignUrl,

    this.status,
    this.memberDetailStatus,
    this.memberDetailStatusName,
  });

  /// Returns a copy with the given fields replaced. Needed because some
  /// endpoints' responses don't echo back every field the model has —
  /// notably SaveMemberStep1, whose response only carries the new
  /// memberId and the resumable route, not the name that was just saved.
  /// Callers that know a value the response didn't return (e.g. the name
  /// that was actually submitted) can patch it back in with this instead
  /// of losing it to null.
  MemberModel copyWith({
    int? memberId,
    String? firstName,
    String? lastName,
    String? surname,
    String? mobile,
    String? mobile2,
    String? fatherName,
    String? dateOfBirth,
    String? gender,
    String? maritalStatus,
    String? address,
    String? village,
    String? taluka,
    String? district,
    String? state,
    String? occupation,
    String? aadharNo,
    String? panNo,
    int? image,
    int? aadharImage,
    int? aadharBackImage,
    int? panImage,
    int? digitalSign,
    String? imageUrl,
    String? aadharImageUrl,
    String? aadharBackImageUrl,
    String? panImageUrl,
    String? digitalSignUrl,
    int? status,
    String? memberDetailStatus,
    String? memberDetailStatusName,
  }) {
    return MemberModel(
      memberId: memberId ?? this.memberId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      surname: surname ?? this.surname,
      mobile: mobile ?? this.mobile,
      mobile2: mobile2 ?? this.mobile2,
      fatherName: fatherName ?? this.fatherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      state: state ?? this.state,
      occupation: occupation ?? this.occupation,
      aadharNo: aadharNo ?? this.aadharNo,
      panNo: panNo ?? this.panNo,
      image: image ?? this.image,
      aadharImage: aadharImage ?? this.aadharImage,
      aadharBackImage: aadharBackImage ?? this.aadharBackImage,
      panImage: panImage ?? this.panImage,
      digitalSign: digitalSign ?? this.digitalSign,
      imageUrl: imageUrl ?? this.imageUrl,
      aadharImageUrl: aadharImageUrl ?? this.aadharImageUrl,
      aadharBackImageUrl: aadharBackImageUrl ?? this.aadharBackImageUrl,
      panImageUrl: panImageUrl ?? this.panImageUrl,
      digitalSignUrl: digitalSignUrl ?? this.digitalSignUrl,
      status: status ?? this.status,
      memberDetailStatus: memberDetailStatus ?? this.memberDetailStatus,
      memberDetailStatusName:
          memberDetailStatusName ?? this.memberDetailStatusName,
    );
  }

  factory MemberModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MemberModel(
      // The API names the member's id "memberId" in this payload (not
      // "id" — that's the outer response envelope's own id, which SHOULD
      // be handled by the repository for endpoints whose `data` lacks
      // both keys, e.g. SaveMemberStep1). "id" is kept only as a
      // last-resort fallback for any response shape that does use it.
      //
      // Unlike every other field parsed below, this used to read the key
      // with a plain case-sensitive `json['memberId']` — the one field in
      // this model NOT going through _ciGet. GetSingleMemberByRegisteredStatus
      // (the endpoint behind getMemberStatus(), which is what re-fetches
      // the member on resume/preview) doesn't reliably use the same casing
      // as SaveMemberStep1's response, so that plain lookup could silently
      // miss and parse to 0 — showing as an empty Member No. in Preview —
      // even though every other field on the SAME response parsed fine via
      // _ciGet. Routed through _ciGet now, matching the rest of this file.
      memberId: _parseInt(
        _ciGet(json, 'memberId') ??
            _ciGet(json, 'member_id') ??
            _ciGet(json, 'id'),
      ),

      firstName:
      json['firstName']?.toString(),

      lastName:
      json['lastName']?.toString(),

      surname:
      json['surname']?.toString(),

      // h-/g- variants — case-insensitive, and tried under both the
      // "hfirstName" style SaveMemberPersonalDetail sends and a plain
      // "hFirstName"/"firstNameHindi" in case GetMemberStatus's response
      // schema doesn't mirror the save request's own key casing (the same
      // uncertainty NomineeModel's doc comment already flags for this
      // API).
      hFirstName: _firstNonEmptyKey(json, const [
        'hfirstName', 'hFirstName', 'firstNameHindi',
      ]),
      gFirstName: _firstNonEmptyKey(json, const [
        'gfirstName', 'gFirstName', 'firstNameGujarati',
      ]),
      hLastName: _firstNonEmptyKey(json, const [
        'hlastName', 'hLastName', 'lastNameHindi',
      ]),
      gLastName: _firstNonEmptyKey(json, const [
        'glastName', 'gLastName', 'lastNameGujarati',
      ]),
      hSurname: _firstNonEmptyKey(json, const [
        'hsurName', 'hSurname', 'surnameHindi',
      ]),
      gSurname: _firstNonEmptyKey(json, const [
        'gsurName', 'gSurname', 'surnameGujarati',
      ]),

      mobile:
      json['mobile']?.toString() ??
          json['mobileNo']?.toString() ??
          json['mobile1']?.toString(),

      memberNo: _firstNonEmptyKey(json, const ['memberNo']),

      mobile2: _firstNonEmptyKey(json, const [
        'mobile2', 'mobileNo2', 'mobileNumber2', 'alternateMobile',
        'secondMobile', 'mobile2No',
      ]),

      fatherName:
      json['fatherName']?.toString(),

      hFatherName: _firstNonEmptyKey(json, const [
        'hfatherName', 'hFatherName', 'fatherNameHindi',
      ]),
      gFatherName: _firstNonEmptyKey(json, const [
        'gfatherName', 'gFatherName', 'fatherNameGujarati',
      ]),

      dateOfBirth:
      json['dateOfBirth']?.toString(),

      gender:
      json['gender']?.toString(),

      maritalStatus:
      json['maritalStatus']?.toString(),

      address:
      json['address']?.toString(),

      hAddress: _firstNonEmptyKey(json, const [
        'haddress', 'hAddress', 'addressHindi',
      ]),
      gAddress: _firstNonEmptyKey(json, const [
        'gaddress', 'gAddress', 'addressGujarati',
      ]),

      village:
      json['village']?.toString(),

      hVillage: _firstNonEmptyKey(json, const [
        'hvillage', 'hVillage', 'villageHindi',
      ]),
      gVillage: _firstNonEmptyKey(json, const [
        'gvillage', 'gVillage', 'villageGujarati',
      ]),

      taluka:
      json['taluka']?.toString(),

      hTaluka: _firstNonEmptyKey(json, const [
        'htaluka', 'hTaluka', 'talukaHindi',
      ]),
      gTaluka: _firstNonEmptyKey(json, const [
        'gtaluka', 'gTaluka', 'talukaGujarati',
      ]),

      district:
      json['district']?.toString(),

      hDistrict: _firstNonEmptyKey(json, const [
        'hdistrict', 'hDistrict', 'districtHindi',
      ]),
      gDistrict: _firstNonEmptyKey(json, const [
        'gdistrict', 'gDistrict', 'districtGujarati',
      ]),

      state:
      json['state']?.toString(),

      hState: _firstNonEmptyKey(json, const [
        'hstate', 'hState', 'stateHindi',
      ]),
      gState: _firstNonEmptyKey(json, const [
        'gstate', 'gState', 'stateGujarati',
      ]),

      occupation:
      json['occupation']?.toString(),

      hOccupation: _firstNonEmptyKey(json, const [
        'hoccupation', 'hOccupation', 'occupationHindi',
      ]),
      gOccupation: _firstNonEmptyKey(json, const [
        'goccupation', 'gOccupation', 'occupationGujarati',
      ]),

      aadharNo:
      json['aadharNo']?.toString(),

      panNo:
      json['panNo']?.toString(),

      image: _parseNullableInt(
        json['image'],
      ),

      aadharImage: _parseNullableInt(
        json['aadharImage'],
      ),

      aadharBackImage: _parseNullableInt(
        json['aadharBackImage'],
      ),

      panImage: _parseNullableInt(
        json['panImage'],
      ),

      digitalSign: _parseNullableInt(
        json['digitalSign'],
      ),

      // Still not confirmed against a real member response (it was
      // truncated in every debug log seen so far right around this data),
      // but GetNomineeByMemberId's response — same API, same shape of
      // problem — turned out to use all-lowercase keys with "Photo" (not
      // "Image") in the word itself (e.g. `aadharFrontImage`'s URL comes
      // back as `aadharfrontphotourl`, not `aadharFrontImageUrl`). Every
      // candidate here is matched case-insensitively (see
      // _firstNonEmptyKey), so only the WORD needs to guess right — both
      // the original "Image"-based guesses and that same "Photo"-based
      // pattern (applied to this model's own field names: `image`,
      // `aadharImage`, `aadharBackImage`, `panImage`, `digitalSign`) are
      // tried.
      // Broadened past the original guesses — Aadhaar/PAN were the two
      // fields members reported as sometimes missing after resuming (the
      // profile photo's own guesses happened to match), so every plausible
      // spelling of each is tried rather than just one or two. Matching is
      // still case-insensitive (_firstNonEmptyKey/_ciGet), so only the
      // exact word choice matters here.
      imageUrl: _firstNonEmptyKey(json, const [
        'imagePhotoUrl',
        'profilePhotoUrl',
        'imageUrl',
        'profileImageUrl',
        'photoUrl',
        'memberImageUrl',
        'memberPhotoUrl',
      ]),

      aadharImageUrl: _firstNonEmptyKey(json, const [
        'aadharPhotoUrl',
        'aadharImageUrl',
        'aadharFrontPhotoUrl',
        'aadharFrontImageUrl',
        'aadharCardPhotoUrl',
        'aadharCardUrl',
        'aadharFrontUrl',
        'aadhaarPhotoUrl',
        'aadhaarImageUrl',
      ]),

      aadharBackImageUrl: _firstNonEmptyKey(json, const [
        'aadharBackPhotoUrl',
        'aadharBackImageUrl',
        'aadharBackUrl',
        'aadhaarBackPhotoUrl',
        'aadhaarBackImageUrl',
      ]),

      panImageUrl: _firstNonEmptyKey(json, const [
        'panPhotoUrl',
        'panImageUrl',
        'panCardPhotoUrl',
        'panCardUrl',
        'panUrl',
      ]),

      digitalSignUrl: _firstNonEmptyKey(json, const [
        'digitalSignPhotoUrl',
        'digitalSignUrl',
        'signaturePhotoUrl',
        'signatureUrl',
        'signatureImageUrl',
        'eSignPhotoUrl',
        'eSignUrl',
      ]),

      status:
      _parseNullableInt(
        json['status'],
      ),

      memberDetailStatus:
      json['memberDetailStatus']?.toString(),

      memberDetailStatusName:
      json['memberDetailStatusName']?.toString(),
    );
  }

  /// Same case-insensitive, multi-key-fallback URL parse as
  /// NomineeModel._firstNonEmptyKey — tries each candidate key in order,
  /// matching regardless of casing (this API's GET responses don't use
  /// the same casing as their own POST schemas — see NomineeModel's doc
  /// comment for a confirmed example), returns the first non-empty
  /// trimmed string, `null` if no candidate matches.
  static String? _firstNonEmptyKey(
      Map<String, dynamic> json, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      final value = _ciGet(json, key);
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static dynamic _ciGet(Map<String, dynamic> json, String key) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static int? _parseNullableInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}