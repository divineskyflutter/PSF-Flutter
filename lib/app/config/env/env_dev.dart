import 'package:envied/envied.dart';

part 'env_dev.g.dart';

@Envied(path: 'env/dev.env')
abstract class EnvDev {
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvDev.baseUrl;
}
