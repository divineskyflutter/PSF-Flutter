/// Request body for the (future) Login API — mobile number + password.
class LoginRequestModel {
  final String mobile;
  final String password;

  const LoginRequestModel({
    required this.mobile,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'password': password,
    };
  }
}
