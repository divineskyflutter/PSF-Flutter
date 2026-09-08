class ContactEntity {
  const ContactEntity({
    required this.id,
    required this.name,
    required this.role,
    this.year,
    this.photoUrl,
    this.phone,
  });

  final int id;

  final String name;

  final String role;

  final String? year;

  final String? photoUrl;

  final String? phone;
}
