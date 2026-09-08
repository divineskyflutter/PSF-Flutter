/// Request body for `POST /api/Member/SaveMemberPersonalDetail`.
///
/// Every text field on this endpoint carries English/Hindi/Gujarati
/// variants (h-/g- prefixes), matching the pattern already used by
/// [SaveMemberStep1RequestModel] for the name fields.
class SaveMemberPersonalDetailRequestModel {
  final int memberId;

  // Name (re-sent here per the API's own schema, even though it was
  // already saved in SaveMemberStep1).
  final String surname;
  final String firstName;
  final String lastName;
  final String gSurname;
  final String gFirstName;
  final String gLastName;
  final String hSurname;
  final String hFirstName;
  final String hLastName;

  // Father's name
  final String fatherName;
  final String hFatherName;
  final String gFatherName;

  /// Document id returned by SaveDocument for the profile photo.
  final int image;

  /// ISO-8601 date-time string.
  final String dateOfBirth;

  final int gender;
  final int maritalStatus;

  final String address;
  final String hAddress;
  final String gAddress;

  final String village;
  final String hVillage;
  final String gVillage;

  final String taluka;
  final String hTaluka;
  final String gTaluka;

  final String district;
  final String hDistrict;
  final String gDistrict;

  final String state;
  final String hState;
  final String gState;

  final String mobile1;
  final String mobile2;

  final String occupation;
  final String hOccupation;
  final String gOccupation;

  final String aadharNo;

  /// Document id returned by SaveDocument for the Aadhaar image.
  final int aadharImage;

  /// Document id returned by SaveDocument for the Aadhaar BACK image.
  /// Added to the swagger schema alongside NomineeModel's new document
  /// fields — see DocumentModule.memberAadharBack.
  final int aadharBackImage;

  final String panNo;

  /// Document id returned by SaveDocument for the PAN image.
  final int panImage;

  /// Document id returned by SaveDocument for the signature.
  final int digitalSign;

  const SaveMemberPersonalDetailRequestModel({
    required this.memberId,
    required this.surname,
    required this.firstName,
    required this.lastName,
    required this.gSurname,
    required this.gFirstName,
    required this.gLastName,
    required this.hSurname,
    required this.hFirstName,
    required this.hLastName,
    required this.fatherName,
    required this.hFatherName,
    required this.gFatherName,
    required this.image,
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    required this.address,
    required this.hAddress,
    required this.gAddress,
    required this.village,
    required this.hVillage,
    required this.gVillage,
    required this.taluka,
    required this.hTaluka,
    required this.gTaluka,
    required this.district,
    required this.hDistrict,
    required this.gDistrict,
    required this.state,
    required this.hState,
    required this.gState,
    required this.mobile1,
    required this.mobile2,
    required this.occupation,
    required this.hOccupation,
    required this.gOccupation,
    required this.aadharNo,
    required this.aadharImage,
    required this.aadharBackImage,
    required this.panNo,
    required this.panImage,
    required this.digitalSign,
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'surname': surname,
      'firstName': firstName,
      'lastName': lastName,
      'gsurName': gSurname,
      'gfirstName': gFirstName,
      'glastName': gLastName,
      'hsurName': hSurname,
      'hfirstName': hFirstName,
      'hlastName': hLastName,
      'fatherName': fatherName,
      'hfatherName': hFatherName,
      'gfatherName': gFatherName,
      'image': image,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'address': address,
      'haddress': hAddress,
      'gaddress': gAddress,
      'village': village,
      'hvillage': hVillage,
      'gvillage': gVillage,
      'taluka': taluka,
      'htaluka': hTaluka,
      'gtaluka': gTaluka,
      'district': district,
      'hdistrict': hDistrict,
      'gdistrict': gDistrict,
      'state': state,
      'hstate': hState,
      'gstate': gState,
      'mobile1': mobile1,
      'mobile2': mobile2,
      'occupation': occupation,
      'hoccupation': hOccupation,
      'goccupation': gOccupation,
      'aadharNo': aadharNo,
      'aadharImage': aadharImage,
      'aadharBackImage': aadharBackImage,
      'panNo': panNo,
      'panImage': panImage,
      'digitalSign': digitalSign,
    };
  }
}
