import 'package:get/get.dart';

import 'en_us.dart';
import 'gu_in.dart';
import 'hi_in.dart';

class AppTranslation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'hi_IN': hiIN,
    'gu_IN': guIN,
  };
}