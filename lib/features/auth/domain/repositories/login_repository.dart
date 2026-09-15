import '../../data/models/login_model.dart';

abstract class LoginRepository {
  /// Calls the login API with [mobile] + [password] and returns the
  /// signed-in member's full profile data on success. Throws an
  /// [Exception] (message already unwrapped from the API envelope) on
  /// failure — callers show that message via ToastUtil.error, same
  /// pattern as every other repository in this app (see
  /// MemberRepositoryImpl).
  Future<LoginModel> login({
    required String mobile,
    required String password,
  });
}
