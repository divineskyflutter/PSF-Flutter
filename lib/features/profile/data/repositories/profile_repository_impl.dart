import 'package:psf_application/core/storage/app_secure_storage.dart';

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/member_profile_entity.dart';
import '../../domain/entities/passbook_entry_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/contact_model.dart';
import '../models/member_profile_model.dart';
import '../models/passbook_entry_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  Future<int> _requireMemberId() async {
    final memberId = await AppSecureStorage.getMemberId();

    if (memberId == null) {
      throw Exception('No member is currently signed in.');
    }

    return memberId;
  }

  @override
  Future<MemberProfileEntity> getMemberProfile() async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.getMemberProfile(memberId: memberId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to load your profile.' : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response.');
    }

    return MemberProfileModel.fromJson(data);
  }

  @override
  Future<void> updateMemberProfile(Map<String, dynamic> fields) async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.updateMemberProfile(
      memberId: memberId,
      fields: fields,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to update your profile.' : response.message,
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.deleteMemberAccount(memberId: memberId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to delete your account.' : response.message,
      );
    }
  }

  @override
  Future<List<PassbookEntryEntity>> getPassbook() async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.getPassbook(memberId: memberId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to load your passbook.' : response.message,
      );
    }

    final list = (response.data as List?) ?? [];

    return list
        .map((e) => PassbookEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ContactEntity>> getContactUsList() async {
    final response = await _remoteDataSource.getContactUsList();

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to load contact details.' : response.message,
      );
    }

    final list = (response.data as List?) ?? [];

    return list.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
