/// Display-ready member details for the wallet card faces and the
/// downloadable card PDF — every field is already a finished string (enum
/// ids resolved to names, dates formatted, Aadhaar masked), so neither the
/// card widgets nor the PDF builder need any parsing or lookup logic.
///
/// An empty string means "not available" — see [orDash] for the value the
/// UI shows in that case.
class MemberCardData {
  const MemberCardData({
    required this.name,
    required this.memberNo,
    this.mobile = '',
    this.dateOfBirth = '',
    this.dateOfBirthNumeric = '',
    this.gender = '',
    this.maritalStatus = '',
    this.status = '',
    this.fatherName = '',
    this.address = '',
    this.occupation = '',
    this.nomineeCount = 0,
    this.joiningDate = '',
    this.photoUrl,
  });

  final String name;
  final String memberNo;
  final String mobile;
  final String dateOfBirth;

  /// `dd / MM / yyyy` — used by the horizontal (printed-style) card.
  final String dateOfBirthNumeric;
  final String gender;
  final String maritalStatus;
  final String status;
  final String fatherName;
  final String address;
  final String occupation;

  final int nomineeCount;
  final String joiningDate;

  final String? photoUrl;

  static String orDash(String value) => value.trim().isEmpty ? '-' : value;
}
