class NomineeModel {
  final String firstName;
  final String middleName;
  final String surname;
  final String mobile;
  final String relation;
  final String dateOfBirth;

  const NomineeModel({
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.mobile,
    required this.relation,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'mobile': mobile,
      'relation': relation,
      'dateOfBirth': dateOfBirth,
    };
  }

  factory NomineeModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return NomineeModel(
      firstName:
      json['firstName']?.toString() ?? '',

      middleName:
      json['middleName']?.toString() ?? '',

      surname:
      json['surname']?.toString() ?? '',

      mobile:
      json['mobile']?.toString() ?? '',

      relation:
      json['relation']?.toString() ?? '',

      dateOfBirth:
      json['dateOfBirth']?.toString() ?? '',
    );
  }
}