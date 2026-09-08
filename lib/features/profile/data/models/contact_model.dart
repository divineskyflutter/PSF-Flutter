import '../../domain/entities/contact_entity.dart';

class ContactModel extends ContactEntity {
  ContactModel({
    required super.id,
    required super.name,
    required super.role,
    super.year,
    super.photoUrl,
    super.phone,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      year: json['year']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
    );
  }
}
