import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_datasource.dart';
import '../models/login_model.dart';
import '../models/login_request_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;

  LoginRepositoryImpl(this._remoteDataSource);

  @override
  Future<LoginModel> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(mobile: mobile, password: password),
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Login failed. Please try again.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid login response.');
    }

    // Same fallback as MemberRepositoryImpl.saveMemberStep1 — some
    // endpoints only carry the new/authenticated id on the response
    // envelope's own top-level `id`, not inside `data` itself.
    final merged = <String, dynamic>{
      ...data,
      if (data['memberId'] == null && data['id'] == null)
        'memberId': response.id,
    };

    return LoginModel.fromJson(merged);
  }
}
