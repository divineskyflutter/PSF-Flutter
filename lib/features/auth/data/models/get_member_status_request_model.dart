class GetMemberStatusRequestModel {
  final bool isRegistered;
  final String firstName;
  final String lastName;
  final String surname;
  final String mobile;
  final int memberId;

  const GetMemberStatusRequestModel({
    required this.isRegistered,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.mobile,
    required this.memberId,
  });

  Map<String, dynamic> toJson() {
    return {
      'isRegistered': isRegistered,
      'firstName': firstName,
      'lastName': lastName,
      'surname': surname,
      'mobile': mobile,
      'memberId': memberId,
    };
  }
}