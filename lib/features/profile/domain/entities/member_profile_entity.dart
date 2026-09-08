class MemberProfileEntity {
  const MemberProfileEntity({
    required this.memberId,
    required this.memberIdLabel,
    required this.fullName,
    this.mobile,
    this.fatherName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.address,
    this.occupation,
    this.photoUrl,
    this.schemeName,
    this.joiningDate,
  });

  final int memberId;

  /// e.g. `"PSF12545"`.
  final String memberIdLabel;

  final String fullName;

  final String? mobile;

  final String? fatherName;

  final String? dateOfBirth;

  final String? gender;

  final String? maritalStatus;

  final String? address;

  final String? occupation;

  final String? photoUrl;

  final String? schemeName;

  final DateTime? joiningDate;
}
