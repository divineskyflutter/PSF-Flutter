class SaveMemberStep1RequestModel {
  final String firstName;
  final String lastName;
  final String surname;

  final String gFirstName;
  final String gLastName;
  final String gSurname;

  final String hFirstName;
  final String hLastName;
  final String hSurname;

  final String mobile;

  const SaveMemberStep1RequestModel({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gFirstName,
    required this.gLastName,
    required this.gSurname,
    required this.hFirstName,
    required this.hLastName,
    required this.hSurname,
    required this.mobile,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'surname': surname,
      'gFirstName': gFirstName,
      'gLastName': gLastName,
      'gSurname': gSurname,
      'hFirstName': hFirstName,
      'hLastName': hLastName,
      'hSurname': hSurname,
      'mobile': mobile,
    };
  }
}