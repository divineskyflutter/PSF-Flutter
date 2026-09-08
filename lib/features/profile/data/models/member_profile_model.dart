import '../../domain/entities/member_profile_entity.dart';

class MemberProfileModel extends MemberProfileEntity {
  MemberProfileModel({
    required super.memberId,
    required super.memberIdLabel,
    required super.fullName,
    super.mobile,
    super.fatherName,
    super.dateOfBirth,
    super.gender,
    super.maritalStatus,
    super.address,
    super.occupation,
    super.photoUrl,
    super.schemeName,
    super.joiningDate,
  });

  factory MemberProfileModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final surname = json['surname']?.toString() ?? '';

    final fullNameFromParts = [firstName, lastName, surname]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return MemberProfileModel(
      memberId: int.tryParse(json['memberId']?.toString() ?? '') ?? 0,
      memberIdLabel:
          (json['memberCode'] ?? json['memberIdLabel'] ?? json['memberId'])
                  ?.toString() ??
              '',
      fullName: (json['fullName']?.toString().trim().isNotEmpty ?? false)
          ? json['fullName'].toString()
          : fullNameFromParts,
      mobile: json['mobile']?.toString() ?? json['mobileNo']?.toString(),
      fatherName: json['fatherName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      maritalStatus: json['maritalStatus']?.toString(),
      address: json['address']?.toString(),
      occupation: json['occupation']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['profileImage']?.toString(),
      schemeName: json['schemeName']?.toString(),
      joiningDate: DateTime.tryParse(json['joiningDate']?.toString() ?? ''),
    );
  }
}
