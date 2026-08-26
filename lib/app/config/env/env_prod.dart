import 'package:envied/envied.dart';

part 'env_prod.g.dart';

@Envied(path: 'env/prod.env')
abstract class EnvProd {
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvProd.baseUrl;
}
