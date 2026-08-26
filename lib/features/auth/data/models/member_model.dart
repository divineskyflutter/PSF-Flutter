class MemberModel {
  final int memberId;

  // ============================================================
  // BASIC MEMBER INFORMATION
  // ============================================================

  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? mobile;

  // ============================================================
  // MEMBER DETAILS
  // ============================================================

  final String? fatherName;
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;

  // ============================================================
  // ADDRESS
  // ============================================================

  final String? address;
  final String? village;
  final String? taluka;
  final String? district;
  final String? state;

  // ============================================================
  // OTHER DETAILS
  // ============================================================

  final String? occupation;
  final String? aadharNo;
  final String? panNo;

  // ============================================================
  // STATUS
  // ============================================================

  final int? status;
  final String? memberDetailStatus;

  const MemberModel({
    required this.memberId,

    this.firstName,
    this.lastName,
    this.surname,
    this.mobile,

    this.fatherName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,

    this.address,
    this.village,
    this.taluka,
    this.district,
    this.state,

    this.occupation,
    this.aadharNo,
    this.panNo,

    this.status,
    this.memberDetailStatus,
  });

  factory MemberModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MemberModel(
      memberId: _parseInt(
        json['id'],
      ),

      firstName:
      json['firstName']?.toString(),

      lastName:
      json['lastName']?.toString(),

      surname:
      json['surname']?.toString(),

      mobile:
      json['mobile']?.toString() ??
          json['mobileNo']?.toString() ??
          json['mobile1']?.toString(),

      fatherName:
      json['fatherName']?.toString(),

      dateOfBirth:
      json['dateOfBirth']?.toString(),

      gender:
      json['gender']?.toString(),

      maritalStatus:
      json['maritalStatus']?.toString(),

      address:
      json['address']?.toString(),

      village:
      json['village']?.toString(),

      taluka:
      json['taluka']?.toString(),

      district:
      json['district']?.toString(),

      state:
      json['state']?.toString(),

      occupation:
      json['occupation']?.toString(),

      aadharNo:
      json['aadharNo']?.toString(),

      panNo:
      json['panNo']?.toString(),

      status:
      _parseNullableInt(
        json['status'],
      ),

      memberDetailStatus:
      json['memberDetailStatus']?.toString(),
    );
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