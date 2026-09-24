import 'dart:typed_data';

import '../entities/contact_entity.dart';
import '../entities/member_profile_entity.dart';
import '../entities/passbook_entry_entity.dart';

abstract class ProfileRepository {
  Future<MemberProfileEntity> getMemberProfile();

  /// [fields] are the raw field names the backend expects — only the ones
  /// the caller wants to change need to be included.
  Future<void> updateMemberProfile(Map<String, dynamic> fields);

  /// Deletes the signed-in member's account. Callers are responsible for
  /// clearing local session storage afterwards.
  Future<void> deleteAccount();

  Future<List<PassbookEntryEntity>> getPassbook();

  Future<List<ContactEntity>> getContactUsList();

  /// The signed-in member's application, rendered as a PDF by the server —
  /// see `ProfileRemoteDataSource.generatePdf`.
  Future<Uint8List> generateApplicationPdf();
}
