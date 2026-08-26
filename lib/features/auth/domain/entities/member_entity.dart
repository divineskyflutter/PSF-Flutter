class MemberEntity {
  final int memberId;

  final String? firstName;
  final String? lastName;
  final String? surname;

  final String? mobile;

  final int? status;

  final String? memberDetailStatus;

  const MemberEntity({
    required this.memberId,
    this.firstName,
    this.lastName,
    this.surname,
    this.mobile,
    this.status,
    this.memberDetailStatus,
  });
}